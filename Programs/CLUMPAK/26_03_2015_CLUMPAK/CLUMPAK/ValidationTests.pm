package ValidationTests;

use strict;
use warnings;

#use lib "/bioseq/CLUMPAK";
use lib "../";
use File::Slurp;

use ZipHandler;
use StructureOutputFilesAccessor;
use AdmixtureOutputFilesAccessor;
use BestKByEvannoAccessor;
use CompareDifferentProgramsDataAccessor;
use ClumppAccessor;

use vars qw(@ISA @EXPORT);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(CLUMPAKValidationTests BestKByEvannoValidationTests DistructForManyKsValidationTests CompareDifferentProgramsValidationTests);

sub CallValidationTest {
	my ($validationTestRef, @testParams) = @_;
	
	my (@testReturnParams) = $validationTestRef->(@testParams);
	
	return (@testReturnParams);
}

sub CLUMPAKValidationTests {
	my ($inputFile, $inputType, $jobId, $jobDir, $labelsFile, $admixtureIndToPopfile, $clumppRepeats, $clumppSearchMethod, $clumppGreedyOption) = @_;
	
	# checking input file format is ok
	my ($inputFiledArrRef)     = &CallValidationTest(\&ExtractStructureFiles, $inputFile, $jobId, $jobDir);
	if ( $inputType eq "admixture" ) {
		my ($convertedAdmixtureFilesArr, $popIdToPopNameFileName)= &CallValidationTest(\&ConvertAdmixtureFilesToStructureFormat, $inputFiledArrRef, $jobDir, $admixtureIndToPopfile );
		$inputFiledArrRef = $convertedAdmixtureFilesArr;
	}
	
	my ($sortedStructureFilesDict, $maxKInFiles, $maxKFile) = &SortStructureFilesDict($inputFiledArrRef);
	my %inputFiles = %$sortedStructureFilesDict;
	#my @keys = (keys %inputFiles);
	
	# soritng keys desc to get largest K val
	my @keys = sort {
		$a =~ /(\d+)/;
	    my $numA = $1;
    	$b =~ /(\d+)/;
    	my $numB = $1;
    	return $numB <=> $numA;
	} keys %inputFiles;
	
	my $largestKKey = $keys[0];	
	my $largestKFileArrRef = $inputFiles{$largestKKey};
	my @largestKFileArr = @$largestKFileArrRef; 
	
	if (defined $clumppSearchMethod || $clumppGreedyOption) {
		my $numOfRuns = 0+@largestKFileArr;
		my ( $numOfIndividuals, $numOfPopulations, $clumppIndFile ) = &ExtractIndTableFromStructureFiles( "$jobDir/CLUMPP.files", \@largestKFileArr );
		&CheckIfClumppParamsCalcLowerThanDAndCalcClumppRepeats($clumppRepeats, $numOfRuns, $numOfIndividuals, $numOfPopulations, $clumppSearchMethod, $clumppGreedyOption);
	}

	if (defined $labelsFile && $inputType eq "admixture") {
		my ($clumppPopFileName, $numOfPredefinedPopulations) = &ExtractPopTableFromStructureFiles("$jobDir", $largestKFileArr[0]);
		
		&CallValidationTest(\&CheckDistructLabelsFileFormat, $labelsFile, $clumppPopFileName);
	}
	
	
}

sub BestKByEvannoValidationTests {
	my ($inputFile, $jobId, $jobDir, $inputType) = @_;
	
	if ($inputType eq 'lnprobbyk') {
		&CallValidationTest(\&GetDataFromLbProbByKtableFile, $inputFile);
	}
	else {
		my ($inputFiledArrRef) = &CallValidationTest(\&ExtractStructureFiles, $inputFile, $jobId, $jobDir);
		my ($sortedStructureFilesDict, $maxKInFiles, $maxKFile) = &SortStructureFilesDict($inputFiledArrRef);
	
		&CallValidationTest(\&GetDataFromInputFiles, $sortedStructureFilesDict);
	}
	
	# checking input file format is ok
	
}

sub DistructForManyKsValidationTests {
	my ($inputFile, $jobId, $jobDir, $labelsFile, $inputType, $admixtureIndToPopfile) = @_;
	
	
	# checking input file format is ok
	my ($inputFiledArrRef) = &CallValidationTest(\&ExtractStructureFiles, $inputFile, $jobId, $jobDir);
	
	if ( $inputType eq "admixture" ) {
		my ($convertedAdmixtureFilesArr, $popIdToPopNameFileName)= &CallValidationTest(\&ConvertAdmixtureFilesToStructureFormat, $inputFiledArrRef, $jobDir, 
																															$admixtureIndToPopfile );
		$inputFiledArrRef = $convertedAdmixtureFilesArr;
	}
	elsif (defined $labelsFile) {
		my @inputFiles = @$inputFiledArrRef;
		my ($clumppPopFileName, $numOfPredefinedPopulations) = &ExtractPopTableFromStructureFiles($jobDir, $inputFiles[0]);
		&CallValidationTest(\&CheckDistructLabelsFileFormat, $labelsFile, $clumppPopFileName);
	}
}

sub CompareDifferentProgramsValidationTests {
	my ($firstInputFile, $firstInputType, $secondInputFile, $secondInputType, $jobId, $jobDir, $labelsFile, $indtopopFile, $clumppRepeats, $clumppSearchMethod, $clumppGreedyOption) = @_;
	
	my ($firstInputFilesArr, $secondInputFilesArr) = &CallValidationTest(\&CheckInputFilesDataValidationTest, $firstInputFile, $firstInputType, $secondInputFile, 
								$secondInputType, $jobId, $jobDir, $indtopopFile, $clumppRepeats, $clumppSearchMethod, $clumppGreedyOption);
	
	if (defined $labelsFile) {
		my @inputFiles = @$firstInputFilesArr;
		
		my ($clumppPopFileName, $numOfPredefinedPopulations) = &ExtractPopTableFromStructureFiles($jobDir, $inputFiles[0]);
		&CallValidationTest(\&CheckDistructLabelsFileFormat, $labelsFile, $clumppPopFileName);
	}
}




1;