package CompareDifferentProgramsAccessor;

use strict;
use warnings;
use ZipHandler;
use File::Basename;
use File::Slurp;
use ZipHandler;
use StructureOutputFilesAccessor;
use AdmixtureOutputFilesAccessor;
use ClumppAccessor;
use ClumppIndMatrixAccessor;
use MCLAccessor;
use CompareDifferentProgramsDataAccessor;
use Statistics::Distributions;
use ClusterAccessor;
use lib "/bioseq/bioSequence_scripts_and_constants";
use CLUMPAK_CONSTS_and_Functions;


use vars qw(@ISA @EXPORT);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(GetProgramInputFiles GetProgramClumppIndFile CalculateChiSquarePValue RunCLUMPPandMCLonProgram RunDistructOnBothPrograms CheckInputFilesDataValidationTest RunClumppOnMergedModes);

# subroutines  "GetProgramInputFiles" and "GetProgramClumppIndFile" are under the module CompareDifferentProgramsDataAccessor.
# this subroutines are declared here because the comapre script uses only this accessor and not the data accessor.
# the data accessor mocule is seperated from this module because of the validation method.


sub RunClumppOnMergedModes {
	my ($jobId, $jobDir, $firstProgramLargeClusterDataRef, $firstProgramMinorClustersDataRef, $secondProgramLargeClusterDataRef, 
			$secondProgramMinorClustersDataRef, $clumppRepeats, $clumppGreedyOption, $clumppSearchMethod) = @_;
	
	my %firstProgramLargeClusterHash    = %$firstProgramLargeClusterDataRef;
	my @firstProgramMinorClustersData = @$firstProgramMinorClustersDataRef;
	
	my %secondProgramLargeClusterHash    = %$secondProgramLargeClusterDataRef;
	my @secondProgramMinorClustersData = @$secondProgramMinorClustersDataRef;
			
	my $outputPairMatrixFileName = "Comparison.Of.Models.txt";
	my $mergedModesClumppfilesDir = "$jobDir/Merged.Modes.CLUMPP.files";
	
	# create merged ind file
	my @programModesIndFiles;
	my @programModesNames;
	print ("Creating merged clumpp ind file fot all modes\n");
	
	# first program modes
	push(@programModesIndFiles, $firstProgramLargeClusterHash{'clumppOutputFile'});
	push(@programModesNames, $firstProgramLargeClusterHash{'clusterText'});
	
	foreach my $firstProgramMinorClusterDataRef (@firstProgramMinorClustersData)
	{
		my %minorClusterData = %$firstProgramMinorClusterDataRef;
		push(@programModesIndFiles, $minorClusterData{'clumppOutputFile'});
		push(@programModesNames, $minorClusterData{'clusterText'});
	}
	
	# second program modes
	push(@programModesIndFiles, $secondProgramLargeClusterHash{'clumppOutputFile'});
	push(@programModesNames, $secondProgramLargeClusterHash{'clusterText'});
	
	foreach my $secondProgramMinorClusterDataRef (@secondProgramMinorClustersData)
	{
		my %minorClusterData = %$secondProgramMinorClusterDataRef;
		push(@programModesIndFiles, $minorClusterData{'clumppOutputFile'});
		push(@programModesNames, $minorClusterData{'clusterText'});
		
	}
	
	my ( $numOfIndividuals, $numOfPopulations, $clumppIndFile ) = &ExtractIndTableFromStructureFiles( $mergedModesClumppfilesDir, \@programModesIndFiles );
	
	# run clumpp on data and get pair matrix
	print ("Executing clumpp for merged file\n"); 
	my $clumppPairMatrixFile = &ExecuteCLUMPPGetPairMatrix($jobId, $clumppIndFile, $numOfIndividuals, $numOfPopulations, 0+@programModesIndFiles, $clumppRepeats, $clumppGreedyOption, $clumppSearchMethod);
				
	# adding data to pair matrix file			
	my @clumppPairMatrixFileLines = read_file($clumppPairMatrixFile);
	my @clumppPairMatrixWithExtraDataFileLines;
	my @programModesNamesLines;
	
	my $firstLine = '* ';
	
	for (my $i = 0; $i < 0+@clumppPairMatrixFileLines; $i++){
		my $displayIndex = $i + 1;

		# building first line
		$firstLine = $firstLine."$displayIndex      ";
		
		#building table lines
		my $curLine = $clumppPairMatrixFileLines[$i];
		my $lineWithData = "$displayIndex $curLine";
		push(@clumppPairMatrixWithExtraDataFileLines, $lineWithData);
		
		# building index to mode lines
		my $curModeName = $programModesNames[$i];
		my $modeTextLine = "$displayIndex - $curModeName\n";
		push(@programModesNamesLines, $modeTextLine);
	}
	
	$firstLine = "$firstLine\n";
	
	# insetring first line to the top of the table
	unshift(@clumppPairMatrixWithExtraDataFileLines, $firstLine);
	
	# adding index to mode lines to file
 	push(@clumppPairMatrixWithExtraDataFileLines, "\n\n");
 	push(@clumppPairMatrixWithExtraDataFileLines, @programModesNamesLines);
 	
 	# saving eddited file
 	my $outputPairMatrixFile = "$jobDir/$outputPairMatrixFileName"; 
	write_file($outputPairMatrixFile, @clumppPairMatrixWithExtraDataFileLines);
	 			
	# return pair matrix file
	return $outputPairMatrixFile;
}


sub RunDistructOnBothPrograms {
	my ($firstArchiveFileName, $firstProgramLargeClusterDataRef, $firstProgramMinorClustersDataRef, $secondArchiveFileName, $secondProgramLargeClusterDataRef, 
			$secondProgramMinorClustersDataRef, $labelsBelowFigureFile, $log, $jobDir, $outputFiles, $imagesToDisplay) = @_;
	
	my %firstProgramLargeClusterHash    = %$firstProgramLargeClusterDataRef;
	my @firstProgramMinorClustersData = @$firstProgramMinorClustersDataRef;
	
	my %secondProgramLargeClusterHash    = %$secondProgramLargeClusterDataRef;
	my @secondProgramMinorClustersData = @$secondProgramMinorClustersDataRef;

	# first program large cluster
	&WriteToFileWithTimeStamp( $log, "Ordering clusters by size for $firstArchiveFileName large cluster");	
	&OrderClumppOutputByFirstPopClusters( $firstProgramLargeClusterHash{'clumppOutputFile'}, $firstProgramLargeClusterHash{'kSize'}, $labelsBelowFigureFile ); 
	print "Calling distruct for $firstArchiveFileName large cluster\n";
	&WriteToFileWithTimeStamp( $log, "Calling distruct for $firstArchiveFileName large cluster" );
	RunClusterBashFile($firstProgramLargeClusterDataRef, $jobDir, $outputFiles, $imagesToDisplay);


	# second program large cluster
	&WriteToFileWithTimeStamp( $log, "Calculating best Average Distance between $firstArchiveFileName large cluster and $secondArchiveFileName large cluster");
	&UpdateClumppOutputToClosestPermutation($secondProgramLargeClusterHash{'clumppOutputFile'}, $secondProgramLargeClusterHash{'kSize'}, 
											$firstProgramLargeClusterHash{'clumppOutputFile'}, $firstProgramLargeClusterHash{'kSize'});

	print "Calling distruct for $secondProgramLargeClusterDataRef large cluster\n";
	&WriteToFileWithTimeStamp( $log, "Calling distruct for $secondArchiveFileName large cluster" );
	&RunClusterBashFile($secondProgramLargeClusterDataRef, $jobDir, $outputFiles, $imagesToDisplay);

	#distruct for minor clusters
	&RunDistructForMinorClusters($firstProgramMinorClustersDataRef, $firstProgramLargeClusterDataRef, $log, $jobDir, $outputFiles, $imagesToDisplay);
	&RunDistructForMinorClusters($secondProgramMinorClustersDataRef, $secondProgramLargeClusterDataRef, $log, $jobDir, $outputFiles, $imagesToDisplay);
}

sub RunDistructForMinorClusters {
	my ($minorClustersDataRef, $largeClusterHashRef, $log, $jobDir, $outputFiles, $imagesToDisplay) = @_;
	
	my @minorClustersData = @$minorClustersDataRef;
	my %largeClusterHash = %$largeClusterHashRef;
	
	foreach my $minorClusterDataRef (@minorClustersData)
	{
		my %minorClusterData = %$minorClusterDataRef;
		
		my $clusterName = $minorClusterData{'clusterName'};
		my $largeClusterName =  $largeClusterHash{'clusterName'};
		&WriteToFileWithTimeStamp( $log, "Calculating best Average Distance between $clusterName and $largeClusterName");
		
		&UpdateClumppOutputToClosestPermutation($minorClusterData{'clumppOutputFile'}, $minorClusterData{'kSize'}, 
												$largeClusterHash{'clumppOutputFile'}, $largeClusterHash{'kSize'});

		print "Calling distruct for $clusterName\n";
		&WriteToFileWithTimeStamp( $log, "Calling distruct for $clusterName" );
		&RunClusterBashFile($minorClusterDataRef, $jobDir, $outputFiles, $imagesToDisplay);
	}
}

sub RunClusterBashFile {
	my ($clusterHashRef, $jobDir, $outputFiles, $imagesToDisplay) = @_;
	my %clusterHash = %$clusterHashRef;
	my $bashFile = $clusterHash{'distructBash'};
	print "bash file: $bashFile\n";
	
	my $distructOutput = `bash $bashFile 2>&1`;
	my $image      = $clusterHash{'distructImage'};
	my $clusterName = $clusterHash{'clusterName'};
	
	if (index($distructOutput, "Error:") != -1) {
		die "Error occurred running distruct for $clusterName.\ndistruct error:\n$distructOutput"
    }
    elsif (index($distructOutput, "Segmentation fault") != -1) {
    	die "Error occurred running Distruct: Distruct produced Segmentation fault.";
	}
	elsif (index($distructOutput, $bashFile) != -1) {
		my $substrError = substr($distructOutput, index($distructOutput, $bashFile) + length($bashFile) + 1);
	    $substrError = substr($substrError , 0, index($substrError, "\n"));
	    	
	    die "Error occurred running Distruct. Distruct error: $substrError";
	}
	elsif (!-e $image) {
		print "Distruct output:\n$distructOutput";
	    die "Error occurred- distruct output image is missing.";
	}
    else {
    	print $distructOutput, "\n";
		my $cpImageCmd = "cp $image $jobDir/$clusterName.png";
		print `$cpImageCmd`;
	
		my $curK = $clusterHash{'kSize'};
		my $clusterText = $clusterHash{'clusterText'};
		&WriteToFile( $imagesToDisplay, "K=$curK\t$clusterText\t$clusterName\t$clusterName.png" );
    }
}

sub RunCLUMPPandMCLonProgram {
	my ($jobId, $jobDir, $programFileName, $clumppIndFile, $numOfIndividuals,  $numOfPopulations, $numOfRuns, $inputFilesRef, $labelsBelowFigureFile, $inputFilesType, 
				$admixtureIndToPopfile, $log, $clusterPermutationAndColorsFile, $drawparams, $mclThreshold, $mclMinClusterFraction, $clumppRepeats, $clumppGreedyOption, $clumppSearchMethod) = @_;
	
	my $clumppPairMatrixFile = &ExecuteCLUMPPGetPairMatrix($jobId, $clumppIndFile, $numOfIndividuals, $numOfPopulations, $numOfRuns, $clumppRepeats, $clumppGreedyOption, $clumppSearchMethod);

	# mcl
	&WriteToFileWithTimeStamp( $log, "Clustering $programFileName with mcl." );
	my ( $largeCluster, $minorClustersRef ) = &GetMCLClustersFromCLUMPPPairMatrixFile( $jobDir, $clumppPairMatrixFile, $numOfRuns, $mclMinClusterFraction, $mclThreshold); #, $programFileName);
	my @minorClusters = @$minorClustersRef;
	
	my %largeClusterData;
	my @minorClustersData;
	
	if ( $largeCluster != -1 ) {

		# large cluster
		&WriteToFileWithTimeStamp( $log, "Executing CLUMPP for $programFileName major cluster." );

		my ( $largeClusterClumppOutputFile, $distructCommandsFile,$distructPdfOutputFile, $distructImageOutputFile, $newLabelsFile ) = 
				&ExecuteCLUMPPForCluster($jobId, "$jobDir/MajorCluster", $largeCluster, $inputFilesRef, $numOfPopulations, $labelsBelowFigureFile, 
											$inputFilesType,$admixtureIndToPopfile, $clusterPermutationAndColorsFile, $drawparams, $clumppRepeats, $clumppGreedyOption, $clumppSearchMethod);

		$labelsBelowFigureFile = $newLabelsFile;

#		$largeClusterData{'key'}   = $key;
		$largeClusterData{'clusterName'} = "$programFileName.LargeCluster";
		$largeClusterData{'kSize'} = $numOfPopulations;
		$largeClusterData{'clumppOutputFile'} = $largeClusterClumppOutputFile;
		$largeClusterData{'distructBash'}  = $distructCommandsFile;
		$largeClusterData{'distructPdf'}   = $distructPdfOutputFile;
		$largeClusterData{'distructImage'} = $distructImageOutputFile;

		my $clusterSize = 0 + @$largeCluster;
		$largeClusterData{'clusterText'} = "Major cluster for $programFileName, $clusterSize/$numOfRuns";


		#minor clusters
		if ( 0 + @minorClusters > 0 ) {
			&WriteToFileWithTimeStamp( $log, "Executing CLUMPP for $programFileName minor clusters." );
			print "number of minor clusters:" . ( 0 + @minorClusters );
			my @curKeyMinorClustersData;

			for ( my $i = 0 ; $i < 0 + @minorClusters ; $i++ ) {
				my $minorCluster = $minorClusters[$i];

				print "minor cluster: $minorCluster\n";
				print "first minor cluster:\t", join( "\t", @$minorCluster ), "\n";

				my $minorClusterId = "MinorCluster" . ( $i + 1 );
				my %minorClusterData;
				my ($minorClusterClumppOutputFile,$minorDistructCommandsFile,	$minorDistructPdfOutputFile, $minorDistructImageOutputFile, $newLabelsFile) = 
					&ExecuteCLUMPPForCluster($jobId, "$jobDir/$minorClusterId", $minorCluster, $inputFilesRef,
					$numOfPopulations, $labelsBelowFigureFile, $inputFilesType, $admixtureIndToPopfile, $clusterPermutationAndColorsFile, $drawparams, $clumppRepeats, $clumppGreedyOption, $clumppSearchMethod);
				$labelsBelowFigureFile = $newLabelsFile;

				$minorClusterData{'minorClusterId'} = $minorClusterId;
				$minorClusterData{'clusterName'} = "$programFileName.$minorClusterId";
				$minorClusterData{'clumppOutputFile'} = $minorClusterClumppOutputFile;
				$minorClusterData{'distructBash'} = $minorDistructCommandsFile;
				$minorClusterData{'distructPdf'} = $minorDistructPdfOutputFile;
				$minorClusterData{'distructImage'} = $minorDistructImageOutputFile;
				$minorClusterData{'kSize'} = $numOfPopulations;

				my $clusterSize = 0 + @$minorCluster;
				$minorClusterData{'clusterText'} = "Minor cluster #".($i+1)." for $programFileName, $clusterSize/$numOfRuns";

				push( @minorClustersData, \%minorClusterData );
			}
		}
	}
		
	return ( \%largeClusterData, \@minorClustersData, $labelsBelowFigureFile );
}


sub CalculateChiSquarePValue {
	my ($allClustersRef, $secondProgramFirstIndex) = @_;
	my @allClusters = @$allClustersRef;
	
	my $observedMatrixRef = BuildObservedMatrix($allClustersRef, $secondProgramFirstIndex);
	my @observedMatrix = @$observedMatrixRef;
	
	my $expectedMatrixRef = BuildExpectedMatrix($observedMatrixRef);
	my @expectedMatrix = @$expectedMatrixRef;
	
	my $chiSquare = &CalcChiSquare($observedMatrixRef, $expectedMatrixRef);
	
	my $dof = +@allClusters - 1;
	print "Calculating p value..\ndof = $dof\nchi square = $chiSquare\n";
	my $p_value = Statistics::Distributions::chisqrprob ($dof,$chiSquare);
	
	return ($chiSquare, $p_value, $dof);
}

sub BuildObservedMatrix {
	my ($allClustersRef, $secondProgramFirstIndex) = @_;
	my @allClusters = @$allClustersRef;
	
	my @observedMatrix;
	my $numOfRows = 2;
	my $numOfCols = 0+@allClusters;
	
	for( my $j = 0; $j < $numOfCols; $j++){
		my $curClusterRef = $allClusters[$j];
		my @curClster = @$curClusterRef;
		
		my $firstProgramCounter = 0;
		my $secondProgramCounter = 0;
		
		foreach my $curClusterMember (@curClster) {
			if ($curClusterMember < $secondProgramFirstIndex){
				$firstProgramCounter++;
			}
			else{
				$secondProgramCounter++;
			}
		} 

		$observedMatrix[0][$j] = $firstProgramCounter;
		$observedMatrix[1][$j] = $secondProgramCounter;
	}
	
	print "Observed Matrix:\n";
	
	for (my $i = 0; $i <$numOfRows; $i++){
		for( my $j = 0; $j < $numOfCols; $j++){
			print "$observedMatrix[$i][$j]\t";
		}
		print "\n";
	}
	print "\n";
	
	return \@observedMatrix;	
}

sub BuildExpectedMatrix {
	my ($observedMatrixRef) = @_;
	my @observedMatrix = @$observedMatrixRef;
	
	my @expectedMatrix;
	
	my $numOfRows = 2;
	my $numOfCols = scalar(@{$observedMatrix[0]});
	
	my $totalSum = &SumMatrix($observedMatrixRef);
	
	for (my $i = 0; $i <$numOfRows; $i++){
		for( my $j = 0; $j < $numOfCols; $j++){
			$expectedMatrix[$i][$j] = &SumRow($i, $observedMatrixRef)*&SumCol($j, $observedMatrixRef)/$totalSum;
		}
	}
	
	print "Expected Matrix:\n";
	
	for (my $i = 0; $i <$numOfRows; $i++){
		for( my $j = 0; $j < $numOfCols; $j++){
			print "$expectedMatrix[$i][$j]\t";
		}
		print "\n";
	}
	print "\n";
	
	return \@expectedMatrix;	
}

sub SumMatrix {
	my ($matrixRef) = @_;
	my @matrix = @$matrixRef;
	
	my $numOfRows = scalar(@matrix);
	my $numOfCols = scalar(@{$matrix[0]});
	
	my $sum = 0;
	
	for (my $i = 0; $i < $numOfRows; $i++) {
	
		for (my $j = 0; $j < $numOfCols; $j++) {
			$sum += $matrix[$i][$j];
		}
	}
	return $sum;
}

sub SumRow {
	my ($row, $matrixRef) = @_;
	my @matrix = @$matrixRef;
	
	my $numOfCols = scalar(@{$matrix[$row]});
	
	my $sum = 0;
	
	for (my $j = 0; $j < $numOfCols; $j++) {
		$sum += $matrix[$row][$j];
	}
	
	return $sum;
}

sub SumCol {
	my ($col, $matrixRef) = @_;
	my @matrix = @$matrixRef;
	
	my $numOfRows = scalar(@matrix);
	
	my $sum = 0;
	
	for (my $i = 0; $i < $numOfRows; $i++) {
		$sum += $matrix[$i][$col];
	}
	
	return $sum;
}

sub CalcChiSquare {
	my ($observedMatrixRef, $expectedMatrixRef) = @_;
	my @observedMatrix = @$observedMatrixRef;
	my @expectedMatrix = @$expectedMatrixRef;
	
	my $numOfRows = scalar(@observedMatrix);
	my $numOfCols = scalar(@{$observedMatrix[0]});
	
	my $chiSquare = 0;
	
	for (my $i = 0; $i < $numOfRows; $i++) {
	
		for (my $j = 0; $j < $numOfCols; $j++) {
			
			$chiSquare += (($observedMatrix[$i][$j] - $expectedMatrix[$i][$j])**2)/$expectedMatrix[$i][$j];
		}
	}
	
	print "Chi square: $chiSquare\n";
	
	return $chiSquare;
}

1;