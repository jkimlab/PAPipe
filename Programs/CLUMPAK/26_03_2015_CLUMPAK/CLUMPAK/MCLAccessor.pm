package MCLAccessor;

use strict;
use warnings;
use File::Path;
use File::Slurp;
use List::MoreUtils qw(any  first_index last_index indexes);

use vars qw(@ISA @EXPORT);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw( GetMCLClustersFromCLUMPPPairMatrixFile ConvertClusterIdsToFileName );

sub GetMCLClustersFromCLUMPPPairMatrixFile
{
	my ($curJobDirectory, $clumppPairMatrixFile, $matrixSize, $minClusterFraction, $threshold, $mclDirPrefix) = @_;
	
	my $mclFilesDirName = "MCL.files";
	
	if (defined $mclDirPrefix)
	{
		$mclFilesDirName = "$mclDirPrefix.MCL.files";
	}
	
	my $mclFilesDir = "$curJobDirectory/$mclFilesDirName";
		
	mkpath($mclFilesDir);
		
	my ($mclOutputFile, $usedCutoff) = &ExecuteMclSmartThreshold ($mclFilesDir, $clumppPairMatrixFile, $matrixSize, $threshold); 
		
	my $mat = &ReadCLUMPPPairMatrix($clumppPairMatrixFile);
	my @matrix = @$mat;
	
	print "Clusters found by MCL:\n";
	my @allClusters = read_file($mclOutputFile);
	my @clustersWithAvgDst;
	
	my %avgDstByCluster;
	my @minorClusters;
	
	my @arrAvgDist; # ofer - array to store avg distances
	
	foreach my $curLine (@allClusters) 
	{
		# removing leading and trailing whitespaces 
		$curLine =~ s/^\s+//;
		$curLine =~ s/\s+$//;
		my $length = length ($curLine);
		
		if ($length != 0){
			my @curClusterValues = split(/\s+/, $curLine);
			@curClusterValues = sort {$a <=> $b} (@curClusterValues );
			
			
			push (@minorClusters, \@curClusterValues); #all clusters including the major first pushed into @minorClusters 
			
			print join("    ", @curClusterValues);
			my $avgDist = &CalculateAvgDistance (\@curClusterValues, \@matrix);
			$avgDstByCluster{\@curClusterValues} = $avgDist;
			push (@arrAvgDist, $avgDist); # ofer - save each avg dist for later
			push(@clustersWithAvgDst, "$curLine\t\t$avgDist\n");
		}
	}
	
	write_file($mclOutputFile, @clustersWithAvgDst);
	
	@minorClusters = sort {
		my @aArr = @$a;
		my @bArr = @$b;
		
		if (0+@aArr < 0+@bArr)
		{
			return 1;
		}
		elsif (0+@bArr < 0+@aArr)
		{
			return -1;
		}
		elsif (0+@aArr == 0+@bArr)
		{
			return $avgDstByCluster{$b} <=> $avgDstByCluster{$a};
		}
	} @minorClusters;
	
	my $largeCluster = $minorClusters[0];
	splice(@minorClusters, 0, 1); #major cluster is removed from the @minorClusters arr
	
	print "Major Cluster is:\n";
	print join ("\t", @$largeCluster);
	print "\n";
	
	my $minMinorClusterSize = int($matrixSize * $minClusterFraction);
	print "Min minor cluster fraction is $minClusterFraction, min size is $minMinorClusterSize\n";
	
	my @minorClustersAfterSizeFilter;
	
	foreach my $curMinorCulster (@minorClusters)
	{
		my $curClusterSize = 0+@$curMinorCulster;
		
		if ($curClusterSize >= $minMinorClusterSize)
		{
			push (@minorClustersAfterSizeFilter, $curMinorCulster);
		}
	}
	
	if (0+@minorClustersAfterSizeFilter > 0)
	{
		print "Minor Clusters are:\n";
		foreach my $minorCluster (@minorClustersAfterSizeFilter)
		{
			print join ("\t", @$minorCluster);
			print "\n";
		}
	}
	else
	{
		print "No minor clusters.\n";
	}
		
	#return $largeCluster, \@minorClustersAfterSizeFilter, $usedCutoff;
	return $largeCluster, \@minorClustersAfterSizeFilter, $usedCutoff, \@arrAvgDist; # ofer - return also the  AvgDist to be printed to file and html by CLUMPAK.pl
}

sub ConvertClusterIdsToFileName
{
	my ($clustersIds, $structureFiles) = @_;
	
	print "Clusters translated to file IDs:\n";

	foreach my $curCluster (@$clustersIds)
	{
		my @curClusterArray = split(/\s+/, $curCluster);
		
		foreach my $curFileID (@curClusterArray)
		{
			my $str = "@$structureFiles[$curFileID]\n";			
			my ($first_num) = $str =~ /run(\d+)/;

			print "$first_num ";
		}
		
		print "\n";	
	}
}

sub CalculateAvgDistance
{
	my ($no, $mat) = @_;
	
	my @nodes = @$no;
	my @matrix = @$mat;
	
	my $size = 0 + @nodes; 
	
	if ($size < 2) {
		return 0;
	}
	else {
		my $count = 0;
		my $total = 0;
		
		for (my $i = 0; $i < $size; $i++)
		{
			for (my $j = $i + 1; $j < $size; $j++)
			{
				$total += $matrix[$nodes[$i]][$nodes[$j]];
				$count++;
			}
		}
		
		my $avg = $total / $count;
		
		print "\t\tAverage distance: $avg \n";
		
		return $avg;
	}
}

sub ExecuteMclSmartThreshold {
	my ($mclFilesDir, $clumppPairMatrixFile, $matrixSize, $threshold) = @_;
	
	my $mclExe = "/PAPipe/Programs/CLUMPAK/26_03_2015_CLUMPAK/CLUMPAK/mcl/bin/mcl";
	my $mcxarrayExe = "/PAPipe/Programs/CLUMPAK/26_03_2015_CLUMPAK/CLUMPAK/mcl/bin/mcxarray";
	my $mcxExe = "/PAPipe/Programs/CLUMPAK/26_03_2015_CLUMPAK/CLUMPAK/mcl/bin/mcx";
	
	my $clumppPairMatrixFileChoped = "$mclFilesDir/clumppPairMatrixChoped";
	my @clumppPairMatrixLines = read_file($clumppPairMatrixFile);
	my @clumppPairMatrixChopedLines;
	foreach my $line (@clumppPairMatrixLines) {
		chop $line;
		$line =~ s/\s+$//;
		$line =~ s/\s+/\t/g;
		push(@clumppPairMatrixChopedLines, "$line\n");
	}
	
	write_file($clumppPairMatrixFileChoped, @clumppPairMatrixChopedLines);
	
	if (defined $threshold) {
		print "Using user predefined threshold - $threshold\n";
	}
	else {
		print "Calculating dynamic threshold..\n";
		$threshold = &CalculateCutoff($mclFilesDir, $clumppPairMatrixFileChoped, $matrixSize, $mcxarrayExe, $mcxExe);
		
		print "Calculation result:\n";
		
		if ($threshold == -1){
			print "Not using any threshold.\n\n";
		}
		else {
			print "The chosen threshold is $threshold.\n\n";
		}
	}
	
	my $clumppPairMatrixFileClustersOutput = "$mclFilesDir/MCL.out";
	
	my $cmd = "$mcxarrayExe -co 0 -data $clumppPairMatrixFileChoped -write-data - | $mclExe - -I 2";
	
	 # only if the result of the dynamic threshold choosing process led to no threshold 
	if ($threshold != -1) {
		$cmd = $cmd." -tf \'gq($threshold), add(-$threshold)\'";
	}
	
	$cmd = $cmd." -o $clumppPairMatrixFileClustersOutput"; #defines the output file for MCL results

	print "mcxarray and mcl command:\n\"$cmd\"\n\n";
	
	print "Executing command..\n";
	
	print `$cmd`;
	
	# Reading clusters from mcl output file
	my $mclClustersFile = ReadMclClustersFromMclOutput($mclFilesDir, $clumppPairMatrixFileClustersOutput);
	
	return ($mclClustersFile, $threshold);
}

sub CalculateCutoff {
	my ($mclFilesDir, $clumppPairMatrixFileChoped, $matrixSize, $mcxarrayExe, $mcxExe) = @_;
	
	my $mcxOutputTableFile = "$mclFilesDir/mcxtable";
	
	my $cmd = "$mcxarrayExe -co 0 -data $clumppPairMatrixFileChoped -write-data - | $mcxExe query -imx - -vary-threshold 0.5/1.0/50  -o $mcxOutputTableFile";

	print "mcx command \"$cmd\"\n\n";
	
	print "\nCalling mcx algorithm..\n";
	
	print `$cmd`;
	
	my @mcxTableLines = read_file($mcxOutputTableFile);
	
	my $tableHeaderIndex = first_index { /EWmean [^\S\r\n] EWmed/ } @mcxTableLines;
	my $indexOfTablefirstRow = $tableHeaderIndex + 2;
	
	my $tableFooterIndex = last_index { /----------------/ } @mcxTableLines;
	
	my $cutoffcolIndex = 14;
	my $NDmeanColIndex = 9;
	my $singletonNodesPercentageColIndex = 3;
	my $maxNDmean = $matrixSize / 2;
	my $minSingletonNodesPercentage = 10;
	
	
	my $finalCutoff = -1;
	my $previousCutoff = -1;
		
	for (my $index = $indexOfTablefirstRow; $index < $tableFooterIndex; $index++) {
		my $line = $mcxTableLines[$index];
		
		$line =~ s/^\s+//;
		my @line_arr = split (/\s+/, $line);
		
		my $cutoff = $line_arr[$cutoffcolIndex];
		
		if ($previousCutoff == -1){
			$previousCutoff = $cutoff
		}
		
		if ($line_arr[$singletonNodesPercentageColIndex] > $minSingletonNodesPercentage || 
								$line_arr[$NDmeanColIndex] < $maxNDmean)
		{
			$finalCutoff = $previousCutoff;
			
			last; 
		}

		$previousCutoff = $cutoff;
	}
	
	return $finalCutoff;
}


sub ReadMclClustersFromMclOutput {
	my ($mclFilesDir, $mclOutputFile) = @_;
	
	my @mclOutputLines = read_file($mclOutputFile);
	
	my $startOfMclmatrixIndex = first_index { /\(mclmatrix/ } @mclOutputLines;
	
	my @bracketIndexes = indexes {/\)/} @mclOutputLines;
	
	my $endBracketIndex = first_index { $_ > $startOfMclmatrixIndex } @bracketIndexes;
	
	my $endOfMclmatrixIndex = $bracketIndexes[$endBracketIndex];
	
	my @mclClustrs;
	
	my $lineEndsWithDollar = 1;
	my @curCluster;
	
	for(my $i = $startOfMclmatrixIndex + 2; $i < $endOfMclmatrixIndex; $i++) {
		my $curLine = $mclOutputLines[$i];
		
		$curLine =~ s/^\s+//;
		$curLine =~ s/\s+$//;
		
		my @line_arr = split (/\s+/, $curLine);

		# if last line ended with $ char removing cluster index
		if ($lineEndsWithDollar) {
			# removes cluster index
			shift (@line_arr);
		}
		
		push (@curCluster, @line_arr);
		
		# checking if cur line ends with $ char
		$lineEndsWithDollar = ($line_arr[0+@line_arr-1] eq "\$");
				
		if ($lineEndsWithDollar) {
			# removes $ char
			splice(@curCluster, 0+@curCluster-1, 1);
			
			push (@curCluster, "\n");
			push (@mclClustrs, join(" ", @curCluster));		
				
			undef @curCluster;
		}
	} 
	
	my $mclClustersFile = "$mclFilesDir/MCL.clusters";	
	
	write_file($mclClustersFile, @mclClustrs);
	
	return $mclClustersFile;
}


sub ReadCLUMPPPairMatrix
{
	my ($clumppPairMatrixFile) = @_;
	my @matrix;
	
	my @matrixLines = read_file($clumppPairMatrixFile);
	
	foreach my $curLine (@matrixLines) {
		push @matrix, [ split /\s+/, $curLine ];
	}
	
	return \@matrix;
}

1;
