package BestKByEvannoAccessor;

use strict;
use warnings;
use ZipHandler;
use StructureOutputFilesAccessor;
#use GraphAccessor;
use GD;
use GD::Graph;
use GD::Graph::lines; 
use GD::Graph::linespoints; 
use GD::Graph::Data; 
use File::Slurp;
use List::Util qw(max);

use lib "/bioseq/bioSequence_scripts_and_constants";
use CLUMPAK_CONSTS_and_Functions;

use vars qw(@ISA @EXPORT);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(BestKByEvanno BestKByPritchard GetDataFromInputFiles GetDataFromLbProbByKtableFile average stdev);

	
sub BestKByEvanno {
	my ($jobDir, $meanByKDict, $stddevByKDict, $log) = @_;
	
	my %meanByK = %$meanByKDict;
	my %stddevByK = %$stddevByKDict;

	my @sortedKs = sort {$a <=> $b} keys %meanByK;
	my $numOfKs = 0+@sortedKs;
	
	my %lnPrimeByK;
	my $lastK = -1;
	
	print "\ncalculating Ln'(K) for each K..\n";
	
	for (my $kIndex = 1; $kIndex < $numOfKs; $kIndex++)	{
		my $lastK = $sortedKs[$kIndex - 1];
		my $curK = $sortedKs[$kIndex];
		
		if ($lastK + 1 != $curK){
			die "Bad K's. K's should be consecutive \n";
		}
		
		my $lnPrime = $meanByK{$curK} - $meanByK{$lastK};
	
		print "Ln'(K=$curK) = $lnPrime\n";
		&WriteToFileWithTimeStamp($log, "Ln'($curK) = $lnPrime");
		
		$lnPrimeByK{$curK} = $lnPrime;
	}
	
	print "\ncalculating |Ln''(K)| for each K..\n";
	
	my %lndPrimeByK;
	
	for (my $kIndex = 1; $kIndex < $numOfKs -1 ; $kIndex++)	{
		my $nextK = $sortedKs[$kIndex + 1];
		my $curK = $sortedKs[$kIndex];
		
		my $lndPrime = abs($lnPrimeByK{$nextK} - $lnPrimeByK{$curK});
		print "|Ln''(K=$curK)| = $lndPrime\n";
		&WriteToFileWithTimeStamp($log, "|Ln''(K=$curK)| = $lndPrime");
		
		
		$lndPrimeByK{$curK} = $lndPrime;
	}
	
	print "\ncalculating Delta K for each K..\n";
	
	my %deltaKByK;
	
	foreach my $curK ( sort {$a <=> $b} keys %lndPrimeByK)	{
		my $curLndPrime = $lndPrimeByK{$curK};
		my $curStddev = $stddevByK{$curK};
		my $deltaK = $curLndPrime / $curStddev;
		
		print "Delta(K=$curK) = $deltaK\n";
		&WriteToFileWithTimeStamp($log, "Delta(K=$curK) = $deltaK");
		
		$deltaKByK{$curK} = $deltaK;
	}
	
	my $kForMaxDelta = (sort { $deltaKByK{$b} <=> $deltaKByK{$a} } keys %deltaKByK)[0];
	my $maxDeltaK = $deltaKByK{$kForMaxDelta};

	print "Max Delta K: $maxDeltaK\n";
	&WriteToFileWithTimeStamp($log, "Max Delta K: $maxDeltaK");
		
	print "Optimal K by Evanno is: $kForMaxDelta.\n";
	&WriteToFileWithTimeStamp($log, "Optimal K by Evanno is: $kForMaxDelta");
	
	my $deltaKGraph = &CreateDeltaKGraph($jobDir, \%deltaKByK);
	
	return $kForMaxDelta, $deltaKGraph;
}

sub BestKByPritchard {
	my ($jobDir, $medianByKDict, $log) = @_;
	my %medianByK = %$medianByKDict;
	
	my $maxMedian = max values %medianByK;
	print "max median is $maxMedian\n";
	
	my %expByK;
	my $expSum = 0;
	
	print "calculating exp(median) for every k\n";

	foreach my $k (sort keys %medianByK) {
		my $median = $medianByK{$k};
		my $val = $median - $maxMedian;
		my $exp = exp($val);
		$expByK{$k} = $exp;
		$expSum += $exp;
			
		print "k: $k\n";
		print "median: $median\n";
		print "median-max: $val\n";
		print "exp value: $exp\n";		
	}
	
	print "sum of all exp: $expSum\n";
	
	print "calculating probability for each k:\n";
	
	my %probByk;
#	my $maxProb = 0;
#	my $kForMaxProb;
	
	foreach my $k (sort keys %expByK) {
		my $exp = $expByK{$k};
		
		my $prob = $exp / $expSum; 

		$probByk{$k} = $prob;
		
		print "Prob(K=$k) = $prob\n";
		&WriteToFileWithTimeStamp($log, "Prob(K=$k) = $prob")		
	}
		
	my $kForMaxProb = (sort { $probByk{$b} <=> $probByk{$a} } keys %probByk)[0];
	my $maxProb = $probByk{$kForMaxProb};
	
	print "best k by Pritchard: $kForMaxProb\n";
	print "max prob: $maxProb\n";
	
	print "Max Probability: $maxProb\n";
	&WriteToFileWithTimeStamp($log, "Max Probability: $maxProb");
	
	print "Optimal K by Pritchard is: $kForMaxProb.\n";
	&WriteToFileWithTimeStamp($log, "The k for which Prob(K=k) obtains the highest value is: $kForMaxProb");
	
	my $probByKGraph = &CreateProbKGraph($jobDir, \%probByk);
	
	return $kForMaxProb, $probByKGraph;
}

sub GetDataFromInputFiles {
	my ($structureFilesDict) = @_;
	my %structureFilesByKey = %$structureFilesDict;
	
	# checking number of different K's, should be more than 3.
	if (scalar(keys %structureFilesByKey) < 4){
		die "The minimum number of different K's required for this calculation is 4.";
	}
	
	my %keyByK;
	my %meanByK;
	my %stddevByK;
	my %medianByK;
	
	my $numOfIndividuals = -1;
	my $numOfruns = -1;
	
	foreach my $key (sort keys %structureFilesByKey) {
		my $structureFilesArr = $structureFilesByKey{$key};
		my @structureFiles = @$structureFilesArr;
		
		my $curNumOfRuns = 0+@structureFiles;
		
		if (($numOfruns != -1) && ($curNumOfRuns != $numOfruns))	  	{
	  		die "Number of runs is not consistent between K's";  			
	  	}
	  	else	  	{
	  		$numOfruns = $curNumOfRuns;
	  	}	
		
		my ($lnProbByFileRef, $curNumOfIndividuals, $k) = &ExtractLnProbFromStructureFilesHash(\@structureFiles);
		my %lnProbByFile = %$lnProbByFileRef;
	
		if (exists $keyByK{$k})			{
			die "Both $keyByK{$k} and $key have the same K size - $k\n";
		}
		

		
		if (($numOfIndividuals != -1) && ($curNumOfIndividuals != $numOfIndividuals))	  	{
	  		die "Number of individuals is not consistent between K's";  			
	  	}
	  	else	  	{
	  		$numOfIndividuals = $curNumOfIndividuals;
	  	}
		
		$keyByK{$k} = $key;
		
		my @values = values %lnProbByFile;
		

	
		my $mean = &average(\@values);
		my $stddev = &stdev(\@values);
		my $median = &median(\@values);
		
		if ($stddev == 0 ){
			die "Cannot calculate best k by Evanno because Standard deviation of 'Ln Prob of Data' for K=$k is zero.";
		}

#		print "K: $k\n";		
#		print "Values:\n", join("\n", @values), "\n";
#		print "mean: $mean\n", "stddev: $stddev\n", "median: $median\n";

		$meanByK{$k} = $mean;
		$stddevByK{$k} = $stddev;
		$medianByK{$k} = $median;
	}
	
	my @sortedKs = sort {$a <=> $b} keys %meanByK;
	
	for (my $i = 0; $i< 0+@sortedKs-1; $i++){
		if ($sortedKs[$i] + 1 != $sortedKs[$i+1]) {
			die "invalid K values. K's must be consecutive";
		}
	}
	
	return (\%meanByK, \%stddevByK, \%medianByK);
}

sub GetDataFromLbProbByKtableFile {
	my ($inputFile) = @_;
	
	my @inputLines = read_file($inputFile);
	my @outputLines;
	
	#removing empty lines 
	my @tempLines;
	foreach my $line (@inputLines) {
		$line =~ s/^\s+//;
		$line =~ s/\s+$//;
		my $length = length ($line);
		
		if ($length != 0){
			push (@tempLines, "$line\n");
		}
	}
	
	my %valuesByK;

	@inputLines = @tempLines;
	my $errMsg = "Format of file is invalid. Input file lines format shpuld be: 'K\tLn_Prob'";
	
	foreach my $curLine (@inputLines) {
		my @lineParts = split(/\s+/, $curLine);
		
		my $length = 0+@lineParts;
		if ($length != 2) {
			die $errMsg;
		}
		else {
			my $k = $lineParts[0];
			my $lnProb = $lineParts[1];
			
			if (($k =~ /^[+-]?\d+((\.){1}\d+)?$/ ) && ($lnProb =~ /^[+-]?\d+((\.){1}\d+)?$/)) {
				if (!defined $valuesByK{$k}) {
					my @values;
					$valuesByK{$k} = \@values;
				}
				
				my $curValues = $valuesByK{$k};
				my @values = @$curValues;
				push(@values, $lnProb);
				$valuesByK{$k} = \@values;
			}
			else {
				die $errMsg;
			}
		}
	}
	
	my %keyByK;
	my %meanByK;
	my %stddevByK;
	my %medianByK;
	my $numOfruns = -1;
	
	foreach my $k (sort { $a <=> $b } keys %valuesByK) {
		my $valuesRef = $valuesByK{$k};
		my @values = @$valuesRef;
		my $curNumOfRuns = 0+@values;

		if (($numOfruns != -1) && ($curNumOfRuns != $numOfruns))	  	{
	  		die "Number of runs is not consistent between K's";  			
	  	}
	  	else {
	  		$numOfruns = $curNumOfRuns;
	  	}	
				
		
		my $mean = &average($valuesRef);
		my $stddev = &stdev($valuesRef);
		
		if ($stddev == 0 ){
			die "Cannot calculate best k because Standard deviation of 'Ln Prob of Data' for K=$k is zero.";
		}
		
		my $median = &median($valuesRef);
		
#		print "Values:\n", join("\n", @values), "\n";
#		print "mean: $mean\n", "stddev: $stddev\n", "median: $median\n";
		
		$meanByK{$k} = $mean;
		$stddevByK{$k} = $stddev;
		$medianByK{$k} = $median
	}
	
	return (\%meanByK, \%stddevByK, \%medianByK);
}

sub stdev
{
        my($data) = @_;
        if(@$data == 1){
                return 0;
        }
        my $average = &average($data);
        my $sqtotal = 0;
        foreach(@$data) {
                $sqtotal += ($average-$_) ** 2;
        }
        my $std = ($sqtotal / (@$data-1)) ** 0.5;
        return $std;
}

sub average
{
        my($data) = @_;
        if (not @$data) {
                die("Empty array\n");
        }
        my $total = 0;
        foreach (@$data) {
                $total += $_;
        }
        my $average = $total / @$data;
        return $average;
}


sub median
{
        my($data) = @_;
        if (not @$data) {
                die("Empty array\n");
        }
        
        my @sortedData = sort { $a <=> $b } @$data;
        my $length = 0+@sortedData;
        
        my $isLengthOddNum = $length % 2;
        
        my $median;
        
        if ($isLengthOddNum){
        	my $medianIndex = ($length - 1) / 2;
        	$median = $sortedData[$medianIndex];
        }
        else {
        	# avg of two middle elements
        	my $index = $length / 2;
        	my $firstElement = $sortedData[$index - 1];
        	my $secondElement = $sortedData[$index];
        	
        	$median = ($firstElement + $secondElement) / 2; 
        }
        
#        print "values:\n", join("  ", @sortedData), "\nmedian\n$median\n";
               
        return $median;
}

sub CreateDeltaKGraph
{
	my ($jobDir, $deltaKByKRef) = @_;
	
	my $imgfile = "$jobDir/Best_K_By_Evanno-DeltaKByKGraph.png";
	
	&CreateValueByKGraph($jobDir, $deltaKByKRef, 'Delta K', 'Delta K = mean(|L\'\'(K)|) / stdev[L(K)]', $imgfile);
	
	return $imgfile;
}

sub CreateProbKGraph
{
	my ($jobDir, $probByKRef) = @_;
	
	my $imgfile = "$jobDir/Best_K_By_Pritchard-ProbByKGraph.png";
	
	&CreateValueByKGraph($jobDir, $probByKRef, 'Prob(K)', 'Prob(K)', $imgfile);
	
	return $imgfile;
}


sub CreateValueByKGraph
{
	my ($jobDir, $valueByKRef, $yLabel, $grpahTitle, $imgfile) = @_;
	my  %valueByK = %$valueByKRef;

	my @xAxisValues;
	my @yAxisValues;

	foreach my $k (sort {$a<=>$b} keys %valueByK)
	{
		push (@xAxisValues, $k);
		#roundin the deltaByKVal
		my $val = $valueByK{$k};
		my $roundedVal = &Round($val);
		
		push (@yAxisValues, $roundedVal);
	} 

	my @graphData;
	push (@graphData, \@xAxisValues);
	push (@graphData, \@yAxisValues);
	
#	my $graph = GD::Graph::lines->new( 800, 600 );
#	my $graph = GD::Graph::points->new( 800, 600 );
	my $graph = GD::Graph::linespoints->new( 800, 600 );
	
	$graph->set( 
		x_label	 			=> 'K', 
		x_label_position   => 0.5,
		x_ticks            => 0,
		y_label 			=> $yLabel, 
		title 				=> $grpahTitle, 
		transparent        	=> 0,
    	bgclr              	=> 'white',
    	box_axis           	=> 0,
    	tick_length        	=> -4,
	    axis_space         	=> 6,
	    fgclr              	=> '#bbbbbb',
	    axislabelclr       	=> '#333333',
    	labelclr           	=> '#333333',
    	textclr            	=> '#333333',
    	valuesclr			=> '#333333',
    	dclrs				=> ['#4d7296'],
    	show_values 		=> 1,
    	line_types 			=> [1], # setting solid line
    	line_width			=> 3,
    	markers				=> [7], # setting point as filled circle
    	marker_size			=> 6
	) or warn $graph->error; 
	
	my $fontFile = 'fonts/FreeSans.ttf';
	
	$graph->set_title_font($fontFile, 20);
	$graph->set_x_label_font($fontFile, 16);
	$graph->set_y_label_font($fontFile, 16);
	$graph->set_x_axis_font($fontFile, 11);
	$graph->set_y_axis_font($fontFile, 11);
	$graph->set_values_font($fontFile, 11);
	
	my $image = $graph->plot( \@graphData );
	
	my $pngData = $image->png();
	open(IMG, ">$imgfile") or die $!;
	binmode IMG;
	print IMG $pngData;
	close IMG;

	return $imgfile;
}
sub Round {
	my ($value) = @_;
	
	my $numOfDigits = 3;
	
	my $factor = 10**$numOfDigits;
	
	my $tempVal = $value * $factor;
	$tempVal = int($tempVal + 0.5);
	$tempVal = $tempVal / $factor;
	my $roundedVal  = sprintf("%.3f", $tempVal);
	
	return $roundedVal;	
}


1;
