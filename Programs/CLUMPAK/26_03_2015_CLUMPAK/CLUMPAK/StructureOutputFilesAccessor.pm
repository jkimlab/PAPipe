package StructureOutputFilesAccessor;

use File::Path;
use strict;
use warnings;
use List::Util qw(first);
use List::MoreUtils qw(any  first_index);
use File::Slurp;
use vars qw(@ISA @EXPORT);
use Scalar::Util qw(looks_like_number);
use File::Basename;

use lib "/bioseq/bioSequence_scripts_and_constants";
use CLUMPAK_CONSTS_and_Functions;

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw( ExtractIndTableFromStructureFiles ExtractPopTableFromStructureFiles ExtractLnProbFromStructureFilesHash ExtractLnProbFromStructureFilesArr ExtractPopTableFromAdmixtureFiles 
				ExtractPopTableFromStructureIndFiles SortStructureFilesDict ReadIndividualsTableFromFile CheckStructureDictIsValid GetMaxKFromStructureDictOrArray
				CheckDistructLabelsFileFormat );

sub ExtractLnProbFromStructureFilesHash
{
	my ($files) = @_;
	my @inputFiles = @$files;
	
	my $numOfPopulations = -1;
	my $numOfIndividuals = -1;
	my %lnProbByFile;	
	
	# foreach input file - read Ln Prob value
	foreach my $curFile (@inputFiles)
	{
		my ($curLnProb, $tempInd, $tempPop) = &ReadLnProbFromStructureFile($curFile, $numOfIndividuals, $numOfPopulations);
		
		if (!defined $curLnProb)
		{
			my ($fileName) = fileparse($curFile);
	  		die "Can't extract LnProb from file $fileName. File doesn't contain run parameters";
		}	
		
		$numOfIndividuals = $tempInd;
		$numOfPopulations = $tempPop;
		
		$lnProbByFile{$curFile} = $curLnProb;		
	}
	
	return (\%lnProbByFile, $numOfIndividuals, $numOfPopulations);
}

sub ExtractLnProbFromStructureFilesArr
{
	my ($files) = @_;
	my @inputFiles = @$files;
	my @lnProbValues;	
	
	# foreach input file - read Ln Prob value
	foreach my $curFile (@inputFiles)
	{
		my ($curLnProb, $tempInd, $tempPop) = &ReadLnProbFromStructureFile($curFile, -1, -1);
		
		if (!defined $curLnProb)
		{
			last;
		}	
		else {
			push(@lnProbValues, $curLnProb);
		}
	}
	
	return (\@lnProbValues);
}

sub ExtractPopTableFromStructureFiles
{
	my ($clumppDirectory, $inputFile) = @_;
			
	my $clumppPopFileName = "$clumppDirectory/ClumppPopFile";
	
	# Reading individuals table from current file
	my $numOfPredefinedPopulations = &ReadPopulationsTableFromFileAndInsertToOutputFile($inputFile, $clumppPopFileName);
	
	return ($clumppPopFileName, $numOfPredefinedPopulations);
}

sub ExtractIndTableFromStructureFiles
{
	my ($clumppDirectory, $files, $clumppIndFileName) = @_;
	my $numOfIndividuals = -1;
	my $kSize = -1;
	
	my @inputFiles ;
	
	if (ref ($files) eq "ARRAY"){
		@inputFiles = @$files;
	}
	else {
		push(@inputFiles, $files);
	}
	
	# Create new input file for clumpp 
	mkpath($clumppDirectory);
		
	if (!defined $clumppIndFileName) {
		$clumppIndFileName = "ClumppIndFile";
	}
	
	$clumppIndFileName = "$clumppDirectory/$clumppIndFileName";
	
	my @inputFileToIndexLines;

	# foreach input file - read individuals table and insert into clumpp input file
	for (my $i = 0; $i < 0+@inputFiles; $i++) {
		my $curFile = $inputFiles[$i]; 
		# Reading individuals table from current file
		my ($tempInd, $tempKsize) = &ReadIndividualsTableFromFileAndInsertToOutputFile($curFile, $clumppIndFileName, $numOfIndividuals, $kSize);
		$numOfIndividuals = $tempInd;
		$kSize = $tempKsize;
		
		my ($curFileName) = fileparse($curFile);
		$curFileName =~ s/^\s+//;
		$curFileName =~ s/\s+$//;
		push (@inputFileToIndexLines, "$i\t$curFileName\n");
	}
	
	write_file("$clumppDirectory/FilesToIndex", @inputFileToIndexLines);
	
	return ($numOfIndividuals, $kSize, $clumppIndFileName);
}

#this sub gets the table part needed for clumpp for one file, and appends it for the current k
sub ReadIndividualsTableFromFileAndInsertToOutputFile { 
	my ($inputFile, $outputFile, $numOfIndividuals, $kSize) = @_;
	
	print "Importing Individuals table from file $inputFile\n";
	
	my $outputLinesRef;
	($outputLinesRef, $numOfIndividuals, $kSize) = &ReadIndividualsTableFromFile($inputFile, $numOfIndividuals, $kSize);
	
	my @outputLines = @$outputLinesRef;
	append_file($outputFile, @outputLines);	
	
	return ($numOfIndividuals, $kSize);
	
}

#this sub returns the actual table part needed for clumpp for a single file
sub ReadIndividualsTableFromFile 
{
	my ($inputFile, $numOfIndividuals, $kSize) = @_;

	# open input and output file
	chomp($inputFile);         # removing newline if exsits because file slurpe cant handle it
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

	@inputLines = @tempLines;
	
	my $inidvidualsInFile = -1;
	my $kSizeInfile = -1;
	
	
	# if file contains run parameters than its from structure, else its only ind file 
	my $foundRunParameters = any { /Run parameters/ } @inputLines;
	
	if ($foundRunParameters)
	{
		# getting individuals
		my $individualsLine = first { /[0-9] individuals/ } @inputLines;
		
		if (!defined $individualsLine)
		{
			my ($fileName) = fileparse($inputFile);
	  		die "No individuals parameter in file $fileName";
		}	
	
		($inidvidualsInFile) = $individualsLine =~ /(\d+)/;
	  			
	  	# compare number of individuals in currnet file to other files
	  	if (($numOfIndividuals != -1) && ($inidvidualsInFile != $numOfIndividuals))
	  	{
	  		die "Number of Individulas is not consistent between files";  			
	  	}
	  	
	  	
	  	# getting individuals
		my $populationsLine = first { /[0-9] populations assumed/ } @inputLines;
		
		if (!defined $populationsLine)
		{
			my ($fileName) = fileparse($inputFile);
	  		die "No population parameter in file $fileName";
		}	
		
		($kSizeInfile) = $populationsLine =~ /(\d+)/;
	  			
	  	# compare number of individuals in currnet file to other files
	  	if (($kSize != -1) && ($kSizeInfile != $kSize))
	  	{
	  		die "K size is not consistent between files";  			
	  	}
	  	
	  	my $indexOfIndTableHeader = first_index { /Inferred ancestry of individuals/ } @inputLines;
	  	
	  	#getting first line of table index
	  	my $tableStartAfterHeader;
	  	my $foundFirstTableRow = 0;
	  	
	  	for ($tableStartAfterHeader = 1; !$foundFirstTableRow; $tableStartAfterHeader++) {
	  		my $curLine = $inputLines[$indexOfIndTableHeader + $tableStartAfterHeader];
	  		
	  		if (index($curLine, ":") != -1) {
	  			my $splitIndex = rindex($curLine, ":");
				my $colPart = substr($curLine, $splitIndex+1);
#	  			my $colPart = (split(":", $curLine))[1];
	
				$colPart =~ s/^\s+//;
				$colPart =~ s/\s+$//;
		
				my @populations = split(/\s+/, $colPart);
				
				if( looks_like_number ($populations[0])) {
					$foundFirstTableRow = 1;
					last;					
				}
	  		}
	  	}
	  	
	  	my $outputLinesRef = &GetIndividualsTable($indexOfIndTableHeader + $tableStartAfterHeader, $inidvidualsInFile, \@inputLines, $kSizeInfile);
	  	@outputLines = @$outputLinesRef;
	}
	else {
		# assuming file only contains ind table
		
		# checking if lines contain ':'
		my $firstLine = $inputLines[0];
		
		if (index($firstLine, ':') == -1){
			die "Format of file is invalid. Expected Structure format data.\nMust contain run parameters or valid structure individuals table (without header)";			
		}
		else {
			my $splitIndex = rindex($firstLine, ":");
			my $kPart = substr($firstLine, $splitIndex+1);
#			my $kPart = (split(':', $firstLine))[1];
			
			if ($kPart !~ m/^[\d\.\s]+$/){ 
#			if ($kPart !~ m/^[-?\d\.\s]+$/){
				die "Format of file is invalid. Expected Structure format data. Must contain run parameters or valid structure individuals table (without header)";
			}
		}
		
		$inidvidualsInFile = 0+@inputLines;
		
		print "Number of individuals in file: $inidvidualsInFile\n";
	  			
	  	# compare number of individuals in currnet file to other files
	  	if (($numOfIndividuals != -1) && ($inidvidualsInFile != $numOfIndividuals))
	  	{
	  		die "Number of Individulas is not consistent between files";  			
	  	}
	  	
	  	$kSizeInfile = &GetPopulationsFromLine($firstLine); #checking K value in this file (from first line)
	  	
	  	print "Number of populations in file: $kSizeInfile\n";
	  			
	  	# compare number of individuals in currnet file to other files
	  	if (($kSize != -1) && ($kSizeInfile != $kSize))
	  	{
	  		die "K size is not consistent between files";  			
	  	}
	  	
	  	my $outputLinesRef = &GetIndividualsTable(0, $inidvidualsInFile, \@inputLines, $kSizeInfile);
	  	@outputLines = @$outputLinesRef;
	}
	
	return (\@outputLines, $inidvidualsInFile, $kSizeInfile);
}

sub GetPopulationsFromLine
{
	my ($line) = @_;
	
	my $splitIndex = rindex($line, ":");
	my $colPart = substr($line, $splitIndex+1);
#	my $colPart = (split(":", $line))[1];
	
	$colPart =~ s/^\s+//;
	$colPart =~ s/\s+$//;
	
	my @populations = split(/\s+/, $colPart);
	
	return 0+@populations;
}
	
sub GetIndividualsTable
{
	my ($indexInArray, $numOfIndividuals, $arrayRef, $kSize) = @_;
	my @array = @$arrayRef;
	my @outputLines;

#	my @tempLines;
#	foreach my $line (@array) {
#		$line =~ s/^\s+//;
#		$line =~ s/\s+$//;
#		my $length = length ($line);
#		
#		if ($length != 0){
#			push (@tempLines, "$line\n");
#		}
#	}
#	
#	@array = @tempLines;
	
	for (my $counter = 0; $counter < $numOfIndividuals; $counter++)
	{
		my $index = $indexInArray + $counter;
		my $curLine = $array[$index];
		
		# removing leading and trailing whitespaces 
#		$curLine =~ s/^\s+//;
#		$curLine =~ s/\s+$//;
		
		
		my $splitIndex = rindex($curLine, ':');
		my $indIdPart = substr($curLine, 0, $splitIndex);
		my $tablePart = substr($curLine, $splitIndex + 1);
		
#		my @lineParts = split(':', $curLine);
#		my $indIdPart = $lineParts[0];
#		my $tablePart = $lineParts[1];
		
		$indIdPart =~ s/^\s+//;
		$indIdPart =~ s/\s+$//;
		$tablePart =~ s/^\s+//;
		$tablePart =~ s/\s+$//;
		
		#changing individual id
		my @indIdParts = split(/\s+/, $indIdPart);
		$indIdParts[1] = $indIdParts[0];
		
		# adding pop data if missing (popId =1)
		my $indIdPartsLength = 0+@indIdParts;
		
		if ($indIdPartsLength == 3) {
			push (@indIdParts, 1);
#			print "POPDATA is missing in individauls table. Adding Default popId.\n";
		}
		
		# removing extra data after ind tables if exists		
		my @tableParts = split(/\s+/, $tablePart);
		my $tablePartsSize = 0+@tableParts;
		
		if ($tablePartsSize < $kSize) {
			die "Ind Table is too small. number of columns is smaller than K.";
		}
		elsif ($tablePartsSize > $kSize) {
			splice (@tableParts, $kSize-$tablePartsSize);
		}
		
		
		# concatinating edited line
		my $outputLine = join(' ', @indIdParts)." : ".join(' ', @tableParts)."\n";
		
		# adding line to output file
		push (@outputLines, $outputLine); 
 	} 
 	
 	return \@outputLines;
}

sub ReadPopulationsTableFromFileAndInsertToOutputFile
{
	my ($inputFile, $clumppPopFileName) = @_;
	
	# open input and output file
	
	print "Opening file $inputFile..\n";
	
	chomp($inputFile);         # removing newline if exsits because file slurp cant handle it
	my @inputLines = read_file($inputFile);
	my @outputLines;
	
	my $numOfPredefinedPopulations = 0;
	
	# if file contains run parameters than its from structure, else its only ind file 
	my $foundRunParameters = (any { /Run parameters/ } @inputLines) && (any { /population in each of the/ } @inputLines);
	
	if (!$foundRunParameters){
		
		my ($indOutputLinesRef, $numOfIndividuals, $kSize) = &ReadIndividualsTableFromFile($inputFile, -1, -1);
		
		my $outputLinesRef;
		($numOfPredefinedPopulations, $outputLinesRef) = &CreatePopulationTableFromIndTable($indOutputLinesRef, $clumppPopFileName);
		@outputLines = @$outputLinesRef;
	}
	else {
		print "Searching file for populations table..\n";
		
		my $indexOfIndTableHeader = first_index { /population in each of the/ } @inputLines;
	  	
		print "Importing populations table to output file..\n";
		
		my $finishedReadingTable = 0;
		
		my $curLineIndex = $indexOfIndTableHeader + 5;
		
		while (!$finishedReadingTable)
		{
			my $curLine = $inputLines[$curLineIndex];
			
			# checking if finished reading pop table
			if (index($curLine, "----------") != -1)
			{
				$finishedReadingTable = 1;
			}		
			else
			{
				# adding line to output file
				push(@outputLines, $curLine);
				$numOfPredefinedPopulations++;
			}
			
			$curLineIndex++;
	 	} 
		
	}

	print "Finished importing populations table - $numOfPredefinedPopulations predefined populations.\n";

	write_file($clumppPopFileName, @outputLines);
		
	# return table
	return $numOfPredefinedPopulations;
}

sub CreatePopulationTableFromIndTable
{
#	my ($indTableFile, $clumppPopFileName) = @_;
#	my @indLines = read_file($indTableFile);

	my ($indTableLinesRef, $clumppPopFileName) = @_;
	my @indLines = @$indTableLinesRef;
	
	
	my @tempLines;
	foreach my $line (@indLines) {
		$line =~ s/^\s+//;
		$line =~ s/\s+$//;
		my $length = length ($line);
		
		if ($length != 0){
			push (@tempLines, "$line\n");
		}
	}
	
	@indLines = @tempLines;

	my $splitIndex = rindex($indLines[0], ":");
	my $kPart = substr($indLines[0], $splitIndex+1);
#	my @firstLineParams = split (":", $indLines[0]);	
#	my $kPart = $firstLineParams[1];
	$kPart =~ s/^\s+//;
	$kPart =~ s/\s+$//;
	
	my @kParts = split (/\s+/, $kPart);
	
	my $kSize = 0+@kParts;
	
	
	my %popSizeByPopId;
	
	foreach my $curIndLine (@indLines) {
		
		$curIndLine =~ s/^\s+//;
		$curIndLine =~ s/\s+$//;
		my @curIndLineParams = split (/\s+/, $curIndLine);	
		my $curPopId = $curIndLineParams[3];
		
		# checking if popId id missing (then $curPopId will be ':')
		# if so, setting all popIds to '1'
		if ($curPopId eq ':'){
			$curPopId = 1;
#			print "POPDATA is missing. Adding deafault popId";
		}
		
		if (!exists $popSizeByPopId{$curPopId}){
			$popSizeByPopId{$curPopId} = 0;
		}
		
		$popSizeByPopId{$curPopId}++;
	}
	
	my @clumppPopfileLines;
	foreach my $popId (keys %popSizeByPopId)
	{
		my $popFileLine = "$popId:\t"."0.0 " x $kSize."\t$popSizeByPopId{$popId}\n";
		
		push (@clumppPopfileLines, $popFileLine);
	}
	
	return (0+(keys %popSizeByPopId), \@clumppPopfileLines);
}

sub ReadLnProbFromStructureFile
{
	my ($inputFile, $numOfIndividuals, $numOfPopulations) = @_;

	# open input and output file
	chomp($inputFile);         # removing newline if exsits because file slurpe cant handle it
	my @inputLines = read_file($inputFile);

	my $foundRunParameters = any { /Run parameters/ } @inputLines;
	
	if (!$foundRunParameters)
	{
		return (undef,undef,undef);
	}
	else {
		my $inidvidualsInFile = -1;
		my $populationsInFile = -1;
		
		# getting individuals
		my $individualsLine = first { /[0-9] individuals/ } @inputLines;
		
		if (!defined $individualsLine)
		{
			my ($fileName) = fileparse($inputFile);
	  		die "No individuals parameter in file $fileName";
		}	
	
		($inidvidualsInFile) = $individualsLine =~ /(\d+)/;
	  			
	  	# compare number of individuals in currnet file to other files
	  	if (($numOfIndividuals != -1) && ($inidvidualsInFile != $numOfIndividuals))
	  	{
	  		die "Number of Individulas is not consistent between files";  			
	  	}
	  	else
	  	{
	  		$numOfIndividuals = $inidvidualsInFile;
	  	}
		  	
	  	# getting populations
		my $populationsLine = first { /[0-9] populations assumed/ } @inputLines;
		
		if (!defined $populationsLine)
		{
	  		my ($fileName) = fileparse($inputFile);
	  		die "No population parameter in file $fileName";
		}	
		
		($populationsInFile) = $populationsLine =~ /(\d+)/;
	  			
	  	# compare number of individuals in currnet file to other files
	  	if (($numOfPopulations != -1) && ($populationsInFile != $numOfPopulations))
	  	{
	  		die "Number of populations is not consistent between files";  			
	  	}
	  	else
	  	{
	  		$numOfPopulations = $populationsInFile;
	  	}
		  	
		# reading Ln Prob
		my $lnProbLine = first { /Estimated Ln Prob of Data/ } @inputLines;	
	
	#	my ($lnProb) = $lnProbLine =~ /(-?\d+)/;
		my ($lnProb) = $lnProbLine =~ m{(-?\d+\.?\d+)};
		
		return ($lnProb, $numOfIndividuals, $numOfPopulations);
	}
}

sub ExtractPopTableFromStructureIndFiles {
	my ($jobDir, $structureIndFile, $kSize) = @_;
	
	my $clumppPopFileName = "$structureIndFile.ClumppPopFile";
	
	my $numOfPredefinedPopulations = &ReadPopulationsTableFromFileAndInsertToOutputFile($structureIndFile, $clumppPopFileName);
	
	return ($clumppPopFileName, $numOfPredefinedPopulations);	
}

sub ExtractPopTableFromStructureIndFilesOLD {
	my ($jobDir, $structureIndFile, $kSize) = @_;
	
	my @structureFileLines = read_file($structureIndFile);
	
	my $clumppPopFileName = "$structureIndFile.ClumppPopFile";
	my $numOfPredefinedPopulations;
	
	
	my $foundPopTable = any { /Proportion of membership of each pre-defined/ } @structureFileLines;
	
	if ($foundPopTable) {
		$numOfPredefinedPopulations = &ReadPopulationsTableFromFileAndInsertToOutputFile($structureIndFile, $clumppPopFileName);
	}
	else
	{
		my %popSizeByPopId;
		
		foreach my $curIndLine (@structureFileLines){
			$curIndLine =~ s/^\s+//;
			$curIndLine =~ s/\s+$//;
				
			my @curIndLineParams = split (/\s+/, $curIndLine);
			
			my $curPopId = $curIndLineParams[3];
			
			if (!defined $popSizeByPopId{$curPopId}){
				$popSizeByPopId{$curPopId} = 0;
			}
			
			my $popSize = $popSizeByPopId{$curPopId};
			$popSize += 1;
			$popSizeByPopId{$curPopId} = $popSize;
		}
		
		my @clumppPopfileLines;
		foreach my $popId (keys %popSizeByPopId)
		{
			my $popFileLine = "$popId:\t"."0.0 " x $kSize."\t$popSizeByPopId{$popId}\n";
		
			push (@clumppPopfileLines, $popFileLine);
		}
	
		write_file($clumppPopFileName, @clumppPopfileLines);
		
		$numOfPredefinedPopulations = scalar (keys %popSizeByPopId);
	}
	
	return ($clumppPopFileName, $numOfPredefinedPopulations);	
}

sub SortStructureFilesDict {
	my ($structureFilesRef) = @_;
	my @structurefiles = @$structureFilesRef;
	
	my %sortedStructureFilesByKey;
	
	my $maxK = -1;
	my $maxKFile = "";
	
	foreach my $curStructureFile (@structurefiles) {
		
		my ($outputLinesRef, $numOfIndividuals, $kSize) = &ReadIndividualsTableFromFile($curStructureFile, -1, -1);
		
		if ($kSize > $maxK) {
			$maxK = $kSize;
			$maxKFile = $curStructureFile;
		}
		
		if (!exists $sortedStructureFilesByKey{"K=$kSize"}){
			my @curKfiles;
			$sortedStructureFilesByKey{"K=$kSize"} = \@curKfiles;
		}
		
		my $curKStructureFilesRef = $sortedStructureFilesByKey{"K=$kSize"};
		my @curKStructureFiles = @$curKStructureFilesRef;
		
		push (@curKStructureFiles, $curStructureFile);
		$sortedStructureFilesByKey{"K=$kSize"} = \@curKStructureFiles;
	}
	
	return (\%sortedStructureFilesByKey, $maxK, $maxKFile);
}

# this validation test checks:
# 1. is max k lower than allowed
# 2. if more than one key, checks if each key contains only one k 
sub CheckStructureDictIsValid {
	my ($structureFilesByKeyRef) = @_;
	
	die "after change in zip handler and in permutation algorithm (no need for max k) this test is not needed.";
	
	my %structureFilesByKey = %$structureFilesByKeyRef;

	my $maxKAllowed = CLUMPAK_CONSTS_and_Functions::MAX_K;
	my $maxKInFiles = -1;
	my $maxKFile = "";
	
#	print "Checking maxK is lower than max k allowed - k=$maxKAllowed\n";
	
	
	my $numOfKeys = scalar keys %structureFilesByKey;
	
	if ($numOfKeys == 1) {
		my ($sortedStructureFilesDict, $maxK, $maxKFile)  = &SortStructureFilesDict(\%structureFilesByKey);
		$maxKInFiles = $maxK;
	} 
	else {
		foreach my $key ( keys %structureFilesByKey ) {
			my $structureFilesArr = $structureFilesByKey{$key};
			my @structureFiles    = @$structureFilesArr;
			
			my $kSizeInCurKey = -1;
			
			foreach my $curStructureFile (@structureFiles) {
				my ($outputLinesRef, $numOfIndividuals, $kSize) = ReadIndividualsTableFromFile($curStructureFile, -1, -1);
		
				if ($kSizeInCurKey == -1){
					$kSizeInCurKey = $kSize;
				}
				elsif ($kSizeInCurKey != $kSize) {
					die "K size in key $key is not consistent. All files in same key must have the same k size."
				}
			}
			
			$maxKInFiles = $kSizeInCurKey;
			$maxKFile = $structureFiles[0];
		}
	}
	
#	print "Max k in files is $maxKInFiles\n";
#	
#	if ($maxKAllowed < $maxKInFiles) {
#		my $file = fileparse($maxKFile);
#		
#		die "K size in file $file is larger than $maxKAllowed. Currently CLUMPAK's webserver doesn't support K>$maxKAllowed";
#	}	
}

sub GetMaxKFromStructureDictOrArray {
	my ($structureFilesByKeyRef) = @_;
	
	if (ref ($structureFilesByKeyRef) eq "HASH") {
		my %structureFilesByKey = %$structureFilesByKeyRef;
	
		my $maxKInFiles = -1;
		
		print "Checking maxK in structure files dict\n";
		
		foreach my $key ( keys %structureFilesByKey ) {
			my $structureFilesArr = $structureFilesByKey{$key};
			my @structureFiles    = @$structureFilesArr;
			
			my ($outputLinesRef, $numOfIndividuals, $kSize) = ReadIndividualsTableFromFile($structureFiles[0], -1, -1);
			
			if ($maxKInFiles < $kSize) {
				$maxKInFiles = $kSize;
			}
		}
		
		print "Max k in files is $maxKInFiles\n";
		
		return ($maxKInFiles);	
	}
	elsif (ref ($structureFilesByKeyRef) eq "ARRAY") {
		my @structureFiles = @$structureFilesByKeyRef;
	
		my $maxKInFiles = -1;
		
		print "Checking maxK in structure files dict\n";
		
		foreach my $structureFile ( @structureFiles ) {
			
			my ($outputLinesRef, $numOfIndividuals, $kSize) = ReadIndividualsTableFromFile($structureFile , -1, -1);
			
			if ($maxKInFiles < $kSize) {
				$maxKInFiles = $kSize;
			}
		}
		
		print "Max k in files is $maxKInFiles\n";
		
		return ($maxKInFiles);
	}
	else {
		return undef;
	}
}

# this validation test checks that provided distruct lables file is in format of "pop_id label_text" 
sub CheckDistructLabelsFileFormat {
	my ($labelsFile, $clumppPopFileName) = @_;
	
	my @labelFileLines = read_file($labelsFile);
	
	my %labelsFilePopId;
	for (my $i = 0; $i < 0+@labelFileLines; $i++){
		my $curLine = $labelFileLines[$i];
		$curLine =~ s/^\s+//;
		$curLine =~ s/\s+$//;
		
		if (length($curLine) > 0) {
			my @lineParts = split (/\s+/, $curLine);
			my $firstPart = $lineParts[0];
			
			if (($firstPart !~  /^-?\d+\z/) || (0+@lineParts <= 1)){
				die "provided labels file format is invalid. bad format at row $i."
			}
			
			$labelsFilePopId{$firstPart} = $firstPart;
		}
	}
	
	if (defined $clumppPopFileName) {
		my @popFileLines = read_file($clumppPopFileName);
		
		if (0+@labelFileLines < 0+@popFileLines){
				die "provided labels file is invalid. Has fewer lines than the number of populations in provided data files.".
				"If labels file was created in a non-unix-like OS check end of line characters";
		}
		
		foreach my $popLine (@popFileLines) {
			$popLine =~ s/^\s+//;
			$popLine =~ s/\s+$//;
			
			if (length($popLine) > 0) {

				my $splitIndex = rindex($popLine, ":");
				my $firstPart = substr($popLine, 0, $splitIndex);
#				my @lineParts = split (":", $popLine);
#				my $firstPart = $lineParts[0];
			
				if (!exists $labelsFilePopId{$firstPart}) {
					die "provided labels file is invalid. Does not contain pop Id $firstPart, which is in provided data files.";
				}
			}
		}
	}
}

sub CheckIndTableContainsPopData {
#	my ($indLine) = @_;
#	
#	$indLine =~ s/^\s+//;
#	$indLine =~ s/\s+$//;
#	
#	my @tableParts = split (/\s+/, $indLine);
#	
#	my $tablePartsLength = 0+@tableParts;	
#	
#	
#	if (($tablePartsLength > 5) && ($tableParts[3] =~ /\D/)){
#		
#	}
	
}


1;