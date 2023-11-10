package ClumppAccessor;

use strict;
use warnings;
use File::Basename;
use File::Slurp;
use List::Util qw(first);
use List::MoreUtils qw(any  first_index);
use CLUMPAK_CONSTS_and_Functions;

use vars qw(@ISA @EXPORT);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(ExecuteCLUMPPGetPairMatrix ExecuteCLUMPPGetOutputFile CheckIfClumppParamsCalcLowerThanDAndCalcClumppRepeats);

sub ExecuteCLUMPPGetPairMatrix 
{
	my ($jobId, $clumppInputFile, $numOfIndividuals, $numOfPopulations, $numOfRuns, $clumppRepeats, $clumppGreedyOption, $clumppSearchMethod) = @_;

	my $directory      = dirname("$clumppInputFile.misc");
	my $outputFileName = "$directory/ClumppPairMatrix";
	
	if ($numOfPopulations ==1 ) {
		MockExecuteCLUMPPforKOne($clumppInputFile, $numOfIndividuals, $numOfRuns);
	}
	else
	{
		&ExeceuteCLUMPP($jobId, $clumppInputFile, $numOfIndividuals, $numOfPopulations, $numOfRuns, $clumppRepeats, $clumppGreedyOption, $clumppSearchMethod);
		&ExtractPairMatrixToFile( "$clumppInputFile.misc", $outputFileName, $numOfRuns );
	}
	
	return $outputFileName;
}

sub ExecuteCLUMPPGetOutputFile 
{
	my ($jobId, $clumppInputFile, $numOfIndividuals, $numOfPopulations, $numOfRuns, $clumppRepeats, $clumppGreedyOption, $clumppSearchMethod) = @_;

	if ($numOfPopulations == 1 ) {
		MockExecuteCLUMPPforKOne($clumppInputFile, $numOfIndividuals, $numOfRuns);
	}
	else
	{
		&ExeceuteCLUMPP($jobId, $clumppInputFile, $numOfIndividuals, $numOfPopulations, $numOfRuns, $clumppRepeats, $clumppGreedyOption, $clumppSearchMethod);
	}
	return "$clumppInputFile.output";
}

sub ExeceuteCLUMPP
{
	my ($jobId, $clumppInputFile, $numOfIndividuals, $numOfPopulations, $numOfRuns, $clumppRepeats, $clumppGreedyOption, $clumppSearchMethod) = @_;

	$clumppRepeats = &CheckIfClumppParamsCalcLowerThanDAndCalcClumppRepeats($clumppRepeats, $numOfRuns, $numOfIndividuals, 
						$numOfPopulations, $clumppSearchMethod, $clumppGreedyOption);

#	$clumppRepeats = &CalculateClumppRepeats($clumppRepeats, $numOfRuns, $numOfIndividuals, $numOfPopulations, $clumppSearchMethod);
#	&CheckIfClumppParamsCalcLowerThanD($clumppRepeats, $numOfRuns, $numOfIndividuals, $numOfPopulations, $clumppSearchMethod);

	print "building clumpp command..\n";
	my $clumppBashFile = &CreateCLUMPPBashFile( $jobId, $clumppInputFile, $numOfIndividuals, $numOfPopulations, $numOfRuns, $clumppRepeats, $clumppGreedyOption, $clumppSearchMethod);

	print "clumpp bash file: $clumppBashFile\n";
	print "calling clumpp...\n";
	
	my $clumppOutput = `bash $clumppBashFile 2>&1`;
  
   	print "Clumpp output:\n$clumppOutput\n";

	# checking clumpp output for errors or if misc and output files exists
    if (index($clumppOutput, "Error:") != -1) {
		die "Error occurred running Clumpp.\nClumpp error:\n$clumppOutput";
    }
    elsif (index($clumppOutput, "Segmentation fault") != -1) {
    	die "Error occurred running Clumpp: Clumpp produced Segmentation fault, please check your input files.";
    }
    elsif (index($clumppOutput, $clumppBashFile) != -1) {
    	my $substrError = substr($clumppOutput, index($clumppOutput, $clumppBashFile) + length($clumppBashFile) + 1);
    	$substrError = substr($substrError , 0, index($substrError, "\n"));
    	
    	die "Error occurred running Clumpp.\nClumpp error:\n$substrError";
    }
    elsif (!(-e "$clumppInputFile.misc") || !(-e "$clumppInputFile.output")) {
    	die "Error occurred- clumpp output files are missing.";
    }
    else {
		print "\nclumpp finished its run\n";
    }
}

sub CreateCLUMPPBashFile
{
	my ($jobId, $clumppInputFile, $numOfIndividuals, $numOfPopulations, $numOfRuns, $clumppRepeats, $clumppGreedyOption, $clumppSearchMethod) = @_;

	my @clummpCommands;
	my $defaultParamFile = "/PAPipe/Programs/CLUMPAK/26_03_2015_CLUMPAK/CLUMPAK/CLUMPP/paramfile";
	my $paramFileName = "clumpp.paramfile";
	my $CLUMPPexe        = "/PAPipe/Programs/CLUMPAK/26_03_2015_CLUMPAK/CLUMPAK/CLUMPP/CLUMPP";

	my $directory      = dirname($clumppInputFile);

	push (@clummpCommands, "#!/bin/bash\n");
	
	# creating temp dir that contains curent run files
	my $mkdirCmd = "mkdir $jobId\n";
	push (@clummpCommands, $mkdirCmd);
	
	# copy indfile to executing dir / temp job dir in order to run clumpp
	my $clumppInputFileName = basename($clumppInputFile);
	my $cpCmd = "cp $clumppInputFile $jobId/$clumppInputFileName\n";
	push (@clummpCommands, $cpCmd);

	my $newParamFile = "$directory/$paramFileName";
	&CreateParamFileForCLUMPPRun($defaultParamFile, $newParamFile, $clumppRepeats, $clumppGreedyOption);
	$cpCmd = "cp $newParamFile $jobId/$paramFileName\n";
	push (@clummpCommands, $cpCmd);

	my $outputFile = "$clumppInputFileName.output";
	my $miscFile = "$clumppInputFileName.misc";

	my $CLUMPPCommand = "$CLUMPPexe $jobId/$paramFileName -i $jobId/$clumppInputFileName -o $jobId/$outputFile -j $jobId/$miscFile -c $numOfIndividuals ";
	$CLUMPPCommand = $CLUMPPCommand . "-m $clumppSearchMethod ";
	$CLUMPPCommand = $CLUMPPCommand . "-k $numOfPopulations -r $numOfRuns\n";
	print "CLUMPP command: $CLUMPPCommand\n";
	push (@clummpCommands, $CLUMPPCommand);
	
	# moving output and misc file from runnig dir to clumpp output dir
	my $mvCmd = "mv $jobId/$outputFile $jobId/$miscFile $directory\n";
	push (@clummpCommands, $mvCmd);

	# removing copied indfile
	my $rmCmd = "rm $jobId/$clumppInputFileName $jobId/$paramFileName\n"; 
	push (@clummpCommands, $rmCmd);
	
	# deletibng temp dir
	my $rmdirCmd = "rmdir $jobId\n";
	push (@clummpCommands, $rmdirCmd);
	
	my $clumpptBashFile = "$directory/ClumppCommands.sh";
	write_file($clumpptBashFile, @clummpCommands);
	
	return $clumpptBashFile;
}

sub CreateParamFileForCLUMPPRun {
	my ($defaultParamFile, $newParamfile,  $repeats, $greedyOption) = @_;
	
	my @lines = read_file($defaultParamFile);
	my @updatedLines;
	
	foreach my $curLine (@lines)
    {
    	my $origLine = $curLine;
    	$curLine =~ s/^\s+//;
		$curLine =~ s/\s+$//;
		
    	if (index($curLine, "REPEATS") == 0)
    	{
    		push (@updatedLines, "REPEATS $repeats					# If GREEDY_OPTION = 2, then REPEATS\n");
    	}
    	elsif (index($curLine, "GREEDY_OPTION") == 0) {
    		push (@updatedLines, "GREEDY_OPTION $greedyOption					# 1 = All possible input orders,\n");
    	}
    	else
    	{
    		push (@updatedLines, $origLine);
    	}
    }
	
	write_file($newParamfile, @updatedLines);	
}

sub ExtractPairMatrixToFile {
	my ( $clumppMiscFile, $outputFile, $matrixSize ) = @_;

	my @inputLines = read_file($clumppMiscFile);
	my @tempLines;
	foreach my $line (@inputLines) {
		$line =~ s/^\s+//;
		$line =~ s/\s+$//;
		my $length = length ($line);
		
		if ($length != 0){
			push (@tempLines, "$line\n");
		}
	}
	
	@inputLines = @tempLines;

	my $indexOfPairwiseMatrixHeader = first_index { /The pairwise G' values for each pair of runs where the cluster/ } @inputLines;
	
	if ($indexOfPairwiseMatrixHeader == -1) {
		die "Cannot find clumpp pairwise matrix in file, $!";
	}
	else {
		print "Pairwise matrix found..\n";
		print "Extracting Pairwise matrix..\n";
		print "Pairwise matrix:\n";
	
		# getting pairwise matrix
		my @matrixLines;
		for ( my $i = 0 ; $i < $matrixSize ; $i++ ) {
			my $curMatLine  = $inputLines[$indexOfPairwiseMatrixHeader+$i+2];
			push(@matrixLines, $curMatLine);
		}
	
		write_file($outputFile, @matrixLines);
	}
}

sub MockExecuteCLUMPPforKOne {
	my ($clumppInputFile, $numOfIndividuals, $numOfRuns) = @_;
	my $directory      = dirname($clumppInputFile);
	
	# creating pair matrix file
	my @pairMatrixFileLines;
	for (my $row = 0; $row < $numOfRuns; $row++) {
		my $curLine;
		for (my $col = 0; $col < $numOfRuns; $col++) {
			$curLine = $curLine."1.000 ";
		}
		
		$curLine = $curLine."\n";
		
		push(@pairMatrixFileLines, $curLine);
	}
	
	my $pairMatrixFileName = "$directory/ClumppPairMatrix";
	write_file($pairMatrixFileName, @pairMatrixFileLines);
	
	#create indFile.output
	my @clumppInputFileLines = read_file($clumppInputFile);
	
	my $indOutputfile = "$clumppInputFile.output";
	
	splice (@clumppInputFileLines, $numOfIndividuals, $numOfIndividuals*($numOfRuns-1));
	write_file($indOutputfile, @clumppInputFileLines);
}

#sub CalculateClumppRepeats {
#	my ($clumppRepeats, $numOfRuns, $numOfIndividuals, $numOfPopulations, $searchMethod) = @_;
#	 
#	my $clumppRepeatsDefaultValue = CLUMPAK_CONSTS_and_Functions::CLUMPP_REPEATS_DEFAULT_VALUE;
#
#	if (!defined $clumppRepeats){
#		print "Using default value of clumpp repeats - $clumppRepeatsDefaultValue repeats\n";
#		return $clumppRepeatsDefaultValue;
#	}
#	else {
#		print "User provided clumpp repeats value - $clumppRepeats repeats.\nCalculating if value is below max repeats allowed..\n";
#		
#		my $isParamCalcLowerThanD = &IsClumppParamsCalcLowerThanD($clumppRepeats, $numOfRuns, $numOfIndividuals, $numOfPopulations, $searchMethod);
#		
#		if ($isParamCalcLowerThanD) {
#			print "User provided value is OK. clumpp repeats - $clumppRepeats\n";
#			return $clumppRepeats;
#		}
#		else {
#			print "User provided value is to high. Using default value - $clumppRepeatsDefaultValue repeats\n";
#			
#			return $clumppRepeatsDefaultValue;
#		}
#	}
#}

sub IsClumppParamsCalcLowerThanD {
	my ($clumppRepeats, $numOfRuns, $numOfIndividuals, $numOfPopulations, $searchMethod, $greedyOption) = @_;

	my $checkComputeTime = CLUMPAK_CONSTS_and_Functions::COMPUTE_TIME_CHECK;

	if ($checkComputeTime) {
		my $maxDValue = CLUMPAK_CONSTS_and_Functions::MAX_D;
		my $R = $numOfRuns;
		my $C = $numOfIndividuals;
		my $k = $numOfPopulations;
		
		# greedy option - 1, all possible input orders - repeats will be R! 
		if (defined $greedyOption && $greedyOption == 1) {
			$clumppRepeats = &Factorial($R);
		}
		
		#full search
		if ($searchMethod == 1) { 
			my $fact = &Factorial($k);
			my $T = ($fact**($R-1))*($R*($R-1))*$C*$k/2;
			my $D = $T*$C;		
			print "k=$k\nk!=$fact\nR=$R\nC=$C\nN=1\nT=$T\nD=$D\nMaxD=$maxDValue\n";
			return ($D <= $maxDValue);
		}
		# greedy
		elsif ($searchMethod == 2) {
			my $fact = &Factorial($k);
			my $T = $fact*($R*($R-1))*$C*$k/2;
			my $D = $T*$C*$clumppRepeats;	
			print "k=$k\nk!=$fact\nR=$R\nC=$C\nN=$clumppRepeats\nT=$T\nD=$D\nMaxD=$maxDValue\n";
				
			return ($D <= $maxDValue);
		}
		# large k greedy
		elsif ($searchMethod == 3) {
			my $T = ($R-1)*$R*$C*$k*$k/2;
			my $D = $T*$C*$clumppRepeats;
			print "k=$k\nR=$R\nC=$C\nN=$clumppRepeats\nT=$T\nD=$D\nMaxD=$maxDValue\n";
			
			return ($D <= $maxDValue);
		}
	}
	
	return 1;
}

sub CheckIfClumppParamsCalcLowerThanD {
	my ($clumppRepeats, $numOfRuns, $numOfIndividuals, $numOfPopulations, $searchMethod, $greedyOption) = @_;
	
	if ($searchMethod != CLUMPAK_CONSTS_and_Functions::CLUMPP_SEARCH_METHOD_DEFAULT ||
			$greedyOption != CLUMPAK_CONSTS_and_Functions::CLUMPP_GREEDY_OPTION_DEFAULT) {
		print "checking if estimated running time for user provided clumpp params is not too long.\n";
		
		my $isParamCalcLowerThanD = &IsClumppParamsCalcLowerThanD($clumppRepeats, $numOfRuns, $numOfIndividuals, $numOfPopulations, $searchMethod, $greedyOption);
		
		if (!$isParamCalcLowerThanD) {
			die "Estimated running time is too long. Please choose different clumpp settings, or download CLUMPAK to your own machine.\n";
		} 
	}
}

sub CheckIfClumppParamsCalcLowerThanDAndCalcClumppRepeats {
	my ($clumppRepeats, $numOfRuns, $numOfIndividuals, $numOfPopulations, $searchMethod, $greedyOption) = @_;
	
	my $clumppRepeatsDefaultValue = CLUMPAK_CONSTS_and_Functions::CLUMPP_REPEATS_DEFAULT_VALUE;
	
	# 1 - full search
	if ($searchMethod == 1) {
		&CheckIfClumppParamsCalcLowerThanD($clumppRepeats, $numOfRuns, $numOfIndividuals, $numOfPopulations, $searchMethod);		
		return 1; # returning 1 and not undef because clumpp expects an integer even when going on all possible input oreders 
	}
	# 2 - greedy
	elsif ($searchMethod == 2) {
		if (defined $greedyOption && $greedyOption == 1) {
			print "User selected GREEDY_OPTION = 1 (All possible input orders).\nCalculating Estimated running time..\n";
			&CheckIfClumppParamsCalcLowerThanD($clumppRepeats, $numOfRuns, $numOfIndividuals, $numOfPopulations, $searchMethod, $greedyOption);
			return 1; # returning 1 and not undef because clumpp expects an integer even when going on all possible input oreders
		}
		elsif (defined $clumppRepeats) {
			&CheckIfClumppParamsCalcLowerThanD($clumppRepeats, $numOfRuns, $numOfIndividuals, $numOfPopulations, $searchMethod, $greedyOption);
			return $clumppRepeats;
		}
		else {
			$clumppRepeats = $clumppRepeatsDefaultValue;
			
			my $isParamCalcLowerThanD = &IsClumppParamsCalcLowerThanD($clumppRepeats, $numOfRuns, $numOfIndividuals, $numOfPopulations, $searchMethod);
			
			if ($isParamCalcLowerThanD) {
				return $clumppRepeats;
			}
			else {
				die "Estimated running time for $clumppRepeatsDefaultValue repeats (default value) with greedy search method option is too long. Please choose different clumpp settings, or download CLUMPAK to your own machine.\n";
			}
		}
	}
	# largeKGreedy
	elsif ($searchMethod == 3) {
		if (defined $greedyOption && $greedyOption == 1) {
			print "User selected GREEDY_OPTION = 1 (All possible input orders).\nCalculating Estimated running time..\n";
			&CheckIfClumppParamsCalcLowerThanD($clumppRepeats, $numOfRuns, $numOfIndividuals, $numOfPopulations, $searchMethod, $greedyOption);
			return 1; # returning 1 and not undef because clumpp expects an integer even when going on all possible input oreders
		}
		elsif (!defined $clumppRepeats){
			print "Using default value of clumpp repeats - $clumppRepeatsDefaultValue repeats\n";
			return $clumppRepeatsDefaultValue;
		}
		elsif ($clumppRepeats <= $clumppRepeatsDefaultValue) {
			print "User provided clumpp repeats value - $clumppRepeats repeats.\n";
			print "Provided value is lower than the default repeats number ($clumppRepeatsDefaultValue)\nUsing provided value..\n";
			return $clumppRepeats;
		}
		else {
			print "User provided clumpp repeats value - $clumppRepeats repeats.\nCalculating if value is below max repeats allowed..\n";
			
			my $isParamCalcLowerThanD = &IsClumppParamsCalcLowerThanD($clumppRepeats, $numOfRuns, $numOfIndividuals, $numOfPopulations, $searchMethod);
			
			if ($isParamCalcLowerThanD) {
				print "User provided value is OK. clumpp repeats - $clumppRepeats\n";
				return $clumppRepeats;
			}
			else {
				print "User provided value is to high. Using default value - $clumppRepeatsDefaultValue repeats\n";	
				return $clumppRepeatsDefaultValue;
			}
		}
	}
}

sub Factorial {
	my ($number) = @_;
	
	my $value = 1;
	
	for (my $i = 1;$i <= $number; $i++) {
		$value = $value * $i;
	}
	
	return $value;
}


1;
