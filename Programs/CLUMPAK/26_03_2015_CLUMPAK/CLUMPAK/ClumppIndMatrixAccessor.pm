package ClumppIndMatrixAccessor;

use strict;
use warnings;
use File::Slurp;
use List::Permutor;

use lib "/bioseq/bioSequence_scripts_and_constants";
use CLUMPAK_CONSTS_and_Functions;

use vars qw(@ISA @EXPORT);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(UpdateClumppOutputToClosestPermutation OrderClumppOutputByFirstPopClusters);

sub OrderClumppOutputByFirstPopClusters {
	my ( $clumppIndOutputFile, $kSize, $labelsFile ) = @_;

	print "Loading clumpp data by popId to memory\n";
	my $clumppIndDataByPopRef = &GetClumppIndDataByPop($clumppIndOutputFile);
	my %clumppIndDataByPop = %$clumppIndDataByPopRef;
	
	my @labelFileLines = read_file($labelsFile);
	my $clumppDataForFirstPopRef = -1;
	
	foreach my $curLine (@labelFileLines)	{
		$curLine =~ s/^\s+//;
		$curLine =~ s/\s+$//;
		my $length = length ($curLine);
		
		if ($length != 0){
			my $curPopId = ( split( /\s+/, $curLine ) )[0];
			
			if (exists $clumppIndDataByPop{$curPopId}) {
				$clumppDataForFirstPopRef = $clumppIndDataByPop{$curPopId};
				print "first pop id found: $curPopId\n";
				last;
			}
		}
	}
	
	if ($clumppDataForFirstPopRef == -1)
	{
		die "Labels file and CLUMPP ind file doesn't contain matching pop ID's\n";
	}
	
	# getting ordered permutation
	print "calculating ordered permutation..\n";
	my $clustersOrderedBySizePermutationRef = &GetClustersOrderedBySizePermutation($clumppDataForFirstPopRef, $kSize );
	print "ordered permutaion: ", join( " ", @$clustersOrderedBySizePermutationRef ), "\n";
	
	# loading matrix to memory before permuting 
	my $clumppMatrixRef = LoadClumppIndFileToMemoryMat( $clumppIndOutputFile, $kSize, 0 );
	
	# permuting matrix
	my $permutatedMatrix = GetPermutetedMatrix( $clumppMatrixRef, $clustersOrderedBySizePermutationRef );
	
	# saving matrix to file
	SaveBestPermutationToIndFile( $clumppIndOutputFile, $permutatedMatrix );
	
	
}

sub GetClustersOrderedBySizePermutation {
	my ($clumppDataRef, $kSize) = @_;
	my @clumppData = @$clumppDataRef;
	
	my @dataSummaryByCol;
	my %avgByCol;
	
	for (my $i = 0; $i < $kSize; $i++) {
		push (@dataSummaryByCol, 0);
	}
	
	# summing values for each col
	
	foreach my $curIndData (@clumppData) {
		my @curIndValues = split( /\s+/, $curIndData );
		
		if (0+@curIndValues != $kSize) {
			die "Size of K is not matching CLUMPP data\n";
		}
		
		for (my $i = 0; $i < $kSize; $i++) {
			$dataSummaryByCol[$i] += $curIndValues[$i];
		} 
	}
	
	
	# calculating avg
	for (my $i = 0; $i < $kSize; $i++) {
		my $avg = $dataSummaryByCol[$i] / (0+@clumppData);
		$avgByCol{$i} = $avg;
	}
	
	my @orderedPermutation;
	
	# sorting hash
	foreach my $curCol (sort{$avgByCol{$b}<=>$avgByCol{$a}} keys %avgByCol){
		push (@orderedPermutation, $curCol);
	} 
	
	return \@orderedPermutation;
}


sub GetClumppIndDataByPop {
	my ($clumppIndOutputFile) = @_;

	my %clumppValuesByPopId;

	my @fileLines = read_file($clumppIndOutputFile);

	foreach my $curLine (@fileLines) {
		$curLine =~ s/^\s+//;
		$curLine =~ s/\s+$//;
		my $length = length ($curLine);
		
		if ($length != 0){	
			my @curLineValues = split( ":", $curLine );
	
			my $clumppValues = $curLineValues[1];
			$clumppValues =~ s/^\s+//;
			$clumppValues =~ s/\s+$//;
	
			my $popAndIdData = $curLineValues[0];
			$popAndIdData =~ s/^\s+//;
			$popAndIdData =~ s/\s+$//;
	
			my $curPopId = ( split( /\s+/, $popAndIdData ) )[3];
			$curPopId =~ s/^\s+//;
			$curPopId =~ s/\s+$//;
		
			if ( !exists $clumppValuesByPopId{$curPopId} ) {
				my @curPopValues;
				$clumppValuesByPopId{$curPopId} = \@curPopValues;
			}
	
			my $curPopValuesRef = $clumppValuesByPopId{$curPopId};
			my @curPopValues    = @$curPopValuesRef;
	
			push( @curPopValues, $clumppValues );
			$clumppValuesByPopId{$curPopId} = \@curPopValues;
		}
	}
	
	return \%clumppValuesByPopId;
}

sub UpdateClumppOutputToClosestPermutation {
	my ( $clumppIndOutputFile, $kSize, $smallerIndOutputFile, $smallerKSize ) = @_;

	my $maxK = CLUMPAK_CONSTS_and_Functions::MAX_K;
	my $checkComputeTime = CLUMPAK_CONSTS_and_Functions::COMPUTE_TIME_CHECK;
	
	if ($checkComputeTime && ($kSize > $maxK)) {
		UpdateClumppOutputToClosestPermutationForLargeK($clumppIndOutputFile, $kSize, $smallerIndOutputFile, $smallerKSize);
	}
	else {
		UpdateClumppOutputToClosestPermutationForSmallK($clumppIndOutputFile, $kSize, $smallerIndOutputFile, $smallerKSize);
	}
}

sub UpdateClumppOutputToClosestPermutationForSmallK {
	my ( $clumppIndOutputFile, $kSize, $smallerIndOutputFile, $smallerKSize ) = @_;
	
	print "Calculating best Average Distance between K=$smallerKSize and K=$kSize..\n";

	print "Loading file $smallerIndOutputFile to memory\n";
	my $smallerMatrixRef =
	  LoadClumppIndFileToMemoryMat( $smallerIndOutputFile, $smallerKSize,
		$kSize - $smallerKSize );
	my @smallerMatrix = @$smallerMatrixRef;

	print "Loading file $clumppIndOutputFile to memory\n";
	my $clumppMatrixRef = LoadClumppIndFileToMemoryMat( $clumppIndOutputFile, $kSize, 0 );
	my @clumppMatrix = @$clumppMatrixRef;

	my @permutationOptions;
	for ( my $i = 0 ; $i < $kSize ; $i++ ) {
		push( @permutationOptions, $i );
	}

	my $bestForbeniusNormScore = -1;
	my @bestPermutation;
	my $bestPermutationMatrixRef;

	print "Running on all permutations..\n";

	my $permutor = new List::Permutor(@permutationOptions);
	while ( my @curPermutation = $permutor->next ) {

		my $permutatedMatrix =
		  GetPermutetedMatrix( $clumppMatrixRef, \@curPermutation );

		my $curForbeniusNorm =
		  CalcForbeniusNorm( $smallerMatrixRef, $permutatedMatrix, $kSize );

		if ( $bestForbeniusNormScore < $curForbeniusNorm ) {
			$bestForbeniusNormScore   = $curForbeniusNorm;
			@bestPermutation          = @curPermutation;
			$bestPermutationMatrixRef = $permutatedMatrix;
		}
	}

	print "Finished running on all permutations.\n";
	print "Best permutation is: ";
	print join( " ", @bestPermutation );
	print "\n";
	print "score: $bestForbeniusNormScore\n";

	SaveBestPermutationToIndFile( $clumppIndOutputFile,
		$bestPermutationMatrixRef );
}

sub SaveBestPermutationToIndFile {
	my ( $clumppIndOutputFile, $bestPermutationMatrixRef ) = @_;

	my @bestPermutationMatrix = @$bestPermutationMatrixRef;

	my @lines = read_file($clumppIndOutputFile);

	#saving a copy of old file
#	print "Saving a copy of original matrix..\n";
#
#	write_file( "$clumppIndOutputFile.before_permutation.backup", @lines );

	#cleaning @lines from empty rows
	my @tempLines;
	foreach my $line (@lines) {
		$line =~ s/^\s+//;
		$line =~ s/\s+$//;
		my $length = length ($line);
		
		if ($length != 0){
			push (@tempLines, "$line\n");
		}
	}
	
	@lines = @tempLines;

	print "Saving permutated matrix to file..\n";

	my @updatedLines;

	for ( my $i = 0 ; $i < 0 + @lines ; $i++ ) {
		my $curLine = $lines[$i];
		my $curLineValues = ( split( ":", $curLine ) )[0];

		my $curRowMatValuesRef = $bestPermutationMatrix[$i];
		my @curRowMatValues    = @$curRowMatValuesRef;

		my $updatedMatrixValues = join( " ", @curRowMatValues );

		my $updatedLine = "$curLineValues : $updatedMatrixValues\n";
		push( @updatedLines, $updatedLine );
	}

	write_file( $clumppIndOutputFile, @updatedLines );
}

sub CalcForbeniusNorm {
	my ( $matAref, $matBref, $K ) = @_;
	my @matA = @$matAref;
	my @matB = @$matBref;

	my $score = 0;

	my $C = 0 + @matA;

	for ( my $i = 0 ; $i < $C ; $i++ ) {
		for ( my $j = 0 ; $j < $K ; $j++ ) {
			my $a = $matA[$i][$j];
			my $b = $matB[$i][$j];

			$score += $a * $a + $b * $b - 2 * $a * $b;

		}
	}

	$score = $score / ( 2 * $C );
	$score = sqrt($score);

	my $norm = 1 - $score;

	return $norm;
}

sub GetPermutetedMatrix {
	my ( $clumppMatrixRef, $permutationRef ) = @_;

	my @matrix      = @$clumppMatrixRef;
	my @permutation = @$permutationRef;

	my @permutationMatrix;

	for my $curRow (@matrix) {
		my @row = @$curRow;
		my @permutatedRow;

		for my $col (@permutation) {
			push( @permutatedRow, $row[$col] );
		}

		push( @permutationMatrix, \@permutatedRow );
	}

	return \@permutationMatrix;
}

sub LoadClumppIndFileToMemoryMat {
	my ( $clumppIndFile, $kSize, $numOfZerosAtEnd ) = @_;

	my @matrix;

	my @lines = read_file($clumppIndFile);

	foreach my $curLine (@lines) {
		$curLine =~ s/^\s+//;
		$curLine =~ s/\s+$//;
		my $length = length ($curLine);
		
		if ($length != 0){
			my $curLineValues = ( split( ":", $curLine ) )[1];
			$curLineValues =~ s/^\s+//;
			$curLineValues =~ s/\s+$//;
	
			my @matValues = split( /\s+/, $curLineValues );
	
			for ( my $i = 0 ; $i < $numOfZerosAtEnd ; $i++ ) {
				push( @matValues, 0 );
			}
	
			push( @matrix, \@matValues );
		}
	}

	return \@matrix;
}

sub LoadClumppIndfileToColumnMatrices {
	my ( $clumppIndFile, $kSize, $numOfZerosAtEnd ) = @_;
	
	my $matRef = LoadClumppIndFileToMemoryMat( $clumppIndFile, $kSize, $numOfZerosAtEnd );
	
	my @mat = @$matRef;
	
	my $C = 0 + @mat;
	
	my @columnMatrices;

	for ( my $j = 0 ; $j < $kSize + $numOfZerosAtEnd ; $j++ ) {
		my @colMat;
		for ( my $i = 0 ; $i < $C ; $i++ ) {
			$colMat[$i][0] = $mat[$i][$j];
		}

		$columnMatrices[$j] = \@colMat;
	}
	
	return (\@columnMatrices, $matRef);
}


sub UpdateClumppOutputToClosestPermutationForLargeK {
	my ( $clumppIndOutputFile, $kSize, $smallerIndOutputFile, $smallerKSize ) = @_;

	print "Calculating best Average Distance between K=$smallerKSize and K=$kSize..\n";

	print "Loading file $smallerIndOutputFile to memory\n";
	my ($smallercolumnMatricesRef, $smallMatrixRef) = LoadClumppIndfileToColumnMatrices( $smallerIndOutputFile, $smallerKSize, $kSize - $smallerKSize );
	my @smallerColumnMatricesArr = @$smallercolumnMatricesRef;

	print "Loading file $clumppIndOutputFile to memory\n";
	my ($clumppColumnMatricesRef, $clumppMatrixRef) = LoadClumppIndfileToColumnMatrices( $clumppIndOutputFile, $kSize, 0 );
	my @clumppColumnMatricesArr = @$clumppColumnMatricesRef;

	my @allNormData;
	
	print "Calculating Forbenious norm for each pair of columns..\n";
	
	for (my $smallMatIndex = 0; $smallMatIndex < $kSize; $smallMatIndex++) {
		for (my $largeMatIndex = 0; $largeMatIndex < $kSize; $largeMatIndex ++) {
				 my $smallerColumnMatrixRef = $smallerColumnMatricesArr[$smallMatIndex];
				 my $columnMatrixRef = $clumppColumnMatricesArr[$largeMatIndex];
				 
				 my $curNorm = CalcForbeniusNorm( $smallerColumnMatrixRef, $columnMatrixRef, 1 );
				 
				 my %curNormData;
				 $curNormData{"smallMatIndex"} = $smallMatIndex;
				 $curNormData{"largeMatData"} = $largeMatIndex;
				 $curNormData{"normValue"} = $curNorm;
				 
				 push (@allNormData, \%curNormData);
		}
	}

	my @allNormDataSorted = sort {
		my %aHash  = %$a;
		my %bHash  = %$b;
		my $aNormSize = $aHash{'normValue'};
		my $bnormSize = $bHash{'normValue'};
		return $bnormSize <=> $aNormSize;
	} @allNormData;

	my %usedSmallIndices;
	my %largeIndexToSmallIndex;
	
	print "Searching for best permutaion..\n";
	
	foreach my $curNormDataRef (@allNormDataSorted) {
		my %curNormData = %$curNormDataRef;
		
		my $smallMatIndex = $curNormData{"smallMatIndex"};
		my $largeMatIndex = $curNormData{"largeMatData"};
		
		if ((!exists $usedSmallIndices{$smallMatIndex}) && (!exists $largeIndexToSmallIndex{$largeMatIndex})) {
			$largeIndexToSmallIndex{$largeMatIndex} = $smallMatIndex;
			$usedSmallIndices{$smallMatIndex} = 1;		
		}
		
		my $curNorm = $curNormData{"normValue"};
	}

	print "best permutaion: ";
	my @permutaion =  sort { return $largeIndexToSmallIndex{$a} <=> $largeIndexToSmallIndex{$b} } keys %largeIndexToSmallIndex;
	print join(" ", @permutaion), "\n";
	my $permutatedMatrix = GetPermutetedMatrix( $clumppMatrixRef, \@permutaion );
	
	SaveBestPermutationToIndFile( $clumppIndOutputFile, $permutatedMatrix );
}

1;
