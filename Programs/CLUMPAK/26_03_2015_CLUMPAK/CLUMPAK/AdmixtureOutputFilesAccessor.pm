package AdmixtureOutputFilesAccessor;

use strict;
use warnings;
use File::Basename;
use File::Slurp;
use File::Path;
use File::Path qw(make_path remove_tree);
use StructureOutputFilesAccessor;

use vars qw(@ISA @EXPORT);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw( ConvertAdmixtureFilesToStructureFormat );

sub ConvertAdmixtureFilesToStructureFormat {
	my($admixtureFilesRef, $jobDir, $admixtureIndToPopfile, $structureIndTable)= @_;
	
	my $popIdToPopNameFileName;
	
	my $popIdByIndexArr;
	my @popIdByIndex;
	
	# Build pop name to id hash and file
	if (defined $structureIndTable) {
		print "Building popId by index array from structure ind table ";
		$popIdByIndexArr = &BuildPopIdByIndexFromStructureIndTable($structureIndTable);
		@popIdByIndex = @$popIdByIndexArr;
	}
	else {
		
		# building fictive ind to pop file if needed
		if (!defined $admixtureIndToPopfile) {
			my @admixtureFiles = @$admixtureFilesRef;
			my ($numOfInds, $inputLinesArrRef) = &GetIndLinesFromAdmixtureFile($admixtureFiles[0]);
			
			$admixtureIndToPopfile = "$jobDir/AdmixtureIndToPopFictiveFile";
			
			&BuildFictiveAdmixtureIndToPopFile($admixtureIndToPopfile, $numOfInds);
		}
		
		$popIdToPopNameFileName = "$jobDir/AdmixturePopIdToPopName";
		
		print "Building PopId To PopName file from indtopop file\n";
		$popIdByIndexArr = &BuildPopIdToNameFileAnPopIdByIndex($admixtureIndToPopfile, $popIdToPopNameFileName);
		@popIdByIndex = @$popIdByIndexArr;
	}
	
	my $convertedArrRef = &ConvertAdmixtureFilesToStructureFormatArr($admixtureFilesRef, $jobDir, $popIdByIndexArr);
		
	return ($convertedArrRef, $popIdToPopNameFileName);
}

sub ConvertAdmixtureFilesToStructureFormatArr {
	my($admixtureFilesArr, $jobDir, $popIdByIndexArr)= @_;
	my @admixtureFiles = @$admixtureFilesArr;

	my $curInputFilesDir = "$jobDir/converted.input.files";
	make_path($curInputFilesDir);
	
	
	my @convertedAdmixtureFiles;
	
	foreach my $curFile (@admixtureFiles) {
		my ($curFileName) = fileparse($curFile);

		my $outputFileName = "$curInputFilesDir/$curFileName.converted";
		&ConvertAdmixtureIndFilesToStructureFormat($curFile, $outputFileName, $popIdByIndexArr);
		
		push (@convertedAdmixtureFiles, $outputFileName);
	}
	
#	my $convertedAdmixtureFilesRef = &ConvertArrayOfAdmixtureIndFilesToStructureFormat($admixtureFilesArr, $curInputFilesDir, $popIdByIndexArr);
	return \@convertedAdmixtureFiles;
}

sub GetIndLinesFromAdmixtureFile {
	my ($inputFile) = @_;
	
	# open input and output file
	my @inputLines = read_file($inputFile);
	
	my @tempLines;
	foreach my $line (@inputLines) {
		$line =~ s/^\s+//;
		$line =~ s/\s+$//;
		my $length = length ($line);
		
		if ($length != 0){
			push (@tempLines, "$line\n");
		}
	}
	
	my $indsInInputFile = 0+@tempLines;
	
	return ($indsInInputFile, \@tempLines);
}

sub ConvertAdmixtureIndFilesToStructureFormat {
	my ($inputFile, $outputFile, $popIdByIndexArr) = @_;
	my @popIdByIndex = @$popIdByIndexArr;
	
	my ($indsInInputFile, $inputLinesArrRef) = &GetIndLinesFromAdmixtureFile($inputFile);
	my @inputLines = @$inputLinesArrRef;
	
	# checking if first line is at admixture format
	my $firstLine = $inputLines[0];
	$firstLine =~ s/^\s+//;
	$firstLine =~ s/\s+$//;
	if ($firstLine !~ m/^[\d\.\s]+$/){ 
		die "Format of file is invalid. Expected Admixture format data. Files Must contain only a simple Q-matrix (i.e. only membership coefficients)";
	}
	
	print "Number of individuals in file: $indsInInputFile\n";
	  			
	# checking if inputfile and indtopopfile are the same size
  	if ($indsInInputFile != 0+@popIdByIndex)
  	{
  		my ($fileName) = fileparse($inputFile);
  		die "Number of individuals in file $fileName is not consistent with the number of individuals in the populations file";  			
  	}
	
	print "Importing Individuals table from file $inputFile\n";
	my @outputLines;
		
	# adding data to admixture matrix for clumpp
	for (my $i = 0; $i < $indsInInputFile; $i++)
	{
		my $popId = $popIdByIndex[$i];

		my $indId = $i + 1;
		
		my $curLine = $inputLines[$i];
		$curLine =~ s/^\s+//;
		$curLine =~ s/\s+$//;
		
		my $outputLine = "$indId $indId (0) $popId : $curLine\n";
		
		push (@outputLines, $outputLine);
	}	
	
	write_file($outputFile, @outputLines);	
}

sub BuildPopIdToNameFileAnPopIdByIndex {
	my ($admixtureIndToPopfile, $popIdToPopNameFileName) = @_;
	
	my @popualtionNames = read_file($admixtureIndToPopfile);
	
	my @popIdByIndex;
	
	my %popIdByPopName;
	my $popIdCounter = 1;
		
	foreach my $popName (@popualtionNames)
	{
		$popName =~ s/^\s+//;
		$popName =~ s/\s+$//;
		my $length = length ($popName);
		
		if (($length != 0) && (!exists $popIdByPopName{$popName}))
		{
			# translating pop name to pop id
			$popIdByPopName{$popName} = $popIdCounter;
			$popIdCounter++;
		}
		
		push (@popIdByIndex, $popIdByPopName{$popName});
	}
		
	# writing pop id to pop name file - this is for the labels below figure file
	my @popIdPopName;
	
	foreach my $popName (sort { $popIdByPopName{$a} <=> $popIdByPopName{$b} } keys %popIdByPopName)
	{
		my $popId = $popIdByPopName{$popName};
		$popName =~ s/\n//g;
		push (@popIdPopName, "$popId $popName\n");
	}
	
	write_file($popIdToPopNameFileName, @popIdPopName);

	return (\@popIdByIndex);
}

sub BuildPopIdByIndexFromStructureIndTable {
	my ($structureIndTable) = @_;
	
	my ($structureIndTableLinesRef, $numOfIndividuals, $kSize) = ReadIndividualsTableFromFile($structureIndTable, -1, -1);
	my @structureIndTableLines = @$structureIndTableLinesRef;
	
	my @popIdByIndex;
	
	
	foreach my $curIndLine (@structureIndTableLines) {
		
		$curIndLine =~ s/^\s+//;
		$curIndLine =~ s/\s+$//;
		my $length = length ($curIndLine);
		
		if ($length != 0){
			my @curIndLineParams = split (/\s+/, $curIndLine);	
			my $curPopId = $curIndLineParams[3];
			
			push (@popIdByIndex, $curPopId);
		}
	}
	
	return (\@popIdByIndex);
}

sub BuildFictiveAdmixtureIndToPopFile {
	my ($admixtureIndToPopfile, $numOfInds) = @_;
	
	my @fileLines = map ("1\n",(1..$numOfInds));
	
	write_file($admixtureIndToPopfile, @fileLines);
}






1;