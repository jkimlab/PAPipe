package CompareDifferentProgramsDataAccessor;

use strict;
use warnings;
use File::Basename;
use File::Slurp;
use ZipHandler;
use StructureOutputFilesAccessor;
use AdmixtureOutputFilesAccessor;
use ClumppAccessor;

use lib "/bioseq/bioSequence_scripts_and_constants";
use CLUMPAK_CONSTS_and_Functions;


use vars qw(@ISA @EXPORT);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(GetProgramInputFiles GetProgramClumppIndFile CheckInputFilesDataValidationTest);

sub GetProgramClumppIndFile {
	my ($jobDir, $inputFilesRef, $inputFilesType) = @_;
	
	my ($numOfIndividuals, $numOfPopulations, $clumppIndFile) = &ExtractIndTableFromStructureFiles( $jobDir, $inputFilesRef);
	
	return ( $numOfIndividuals, $numOfPopulations, $clumppIndFile )
}

sub GetProgramInputFiles{
	my ($archiveFile, $jobId, $jobDir, $inputFilesType, $admixtureIndToPopfile, $structureIndTable) = @_;
	
	my ($archiveFileName) = fileparse($archiveFile, ".zip");
	
	my $inputFilesArrRef = &ExtractStructureFiles($archiveFile, $jobId, $jobDir); #, $archiveFileName);
#	my %inputFilesByKey = %$inputFilesDict;
	
	my $newLabelsBelowFigureFile;
	
	if ( $inputFilesType eq "admixture" ) {
		# send dictionary to admixture accessor and edit admixture files
		
		my ($convertedAdmixtureFilesArr, $popIdToPopNameFileName)= &ConvertAdmixtureFilesToStructureFormat($inputFilesArrRef, $jobDir, $admixtureIndToPopfile, 
																													$structureIndTable );
		$inputFilesArrRef = $convertedAdmixtureFilesArr;
		
		if (defined $popIdToPopNameFileName) {
			$newLabelsBelowFigureFile = $popIdToPopNameFileName;
		}
	}
		
	my ($sortedStructureFilesDict, $maxKInFiles, $maxKFile) = &SortStructureFilesDict($inputFilesArrRef);
	my %inputFilesByKey = %$sortedStructureFilesDict;
		
	my $numOfKeys = scalar(keys %inputFilesByKey);
		
	if ($numOfKeys != 1) {
		die "Input file $archiveFileName contains $numOfKeys K values. The input files to the compare program should contain only a single K value.";
	}
		
	
		
	my $key = (keys %inputFilesByKey)[0];
	my $inputFilesArr = $inputFilesByKey{$key};
	
	return ($inputFilesArr, $newLabelsBelowFigureFile);
}

# this validation test checks:
# 1. both files have the same number of individuals and same k size
# 2. only one K per zip
sub CheckInputFilesDataValidationTest {
	my ($firstInputFile, $firstInputType, $secondInputFile, $secondInputType, $jobId, $jobDir, $indtopop, $clumppRepeats, $clumppSearchMethod, $clumppGreedyOption) = @_;

	# Getting first program data
	my ($firstArchiveFileName) = fileparse($firstInputFile, ".zip");
	my ($firstInputFilesArr, $newLabelsBelowFigure) = 
					&GetProgramInputFiles($firstInputFile, $jobId, $jobDir, $firstInputType, $indtopop);
	my @firstInputFiles = @$firstInputFilesArr;

	my ( $firstProgramNumOfIndividuals, $firstProgramNumOfPopulations, $firstProgramClumppIndFile ) = 
					&GetProgramClumppIndFile ($jobDir, $firstInputFilesArr, $firstInputType);
	
	# Getting second program data
	
	#checking if first type was structure
	my $structureIndTable;
	if ($firstInputType eq "structure") {
		$structureIndTable = $firstInputFiles[0]; 
	}
	
	my ($secondArchiveFileName) = fileparse($secondInputFile, ".zip");
	my ($secondInputFilesArr, $secondNewLabelsBelowFigure) = 
					&GetProgramInputFiles($secondInputFile, $jobId, $jobDir, $secondInputType, $indtopop, $structureIndTable);
	my @secondInputFiles = @$secondInputFilesArr;
	
	
	my ( $secondProgramNumOfIndividuals, $secondProgramNumOfPopulations, $secondProgramClumppIndFile ) = 
					&GetProgramClumppIndFile ($jobDir, $secondInputFilesArr, $secondInputType);
	
	# checking if two files have the same parameters
	if (($firstProgramNumOfIndividuals != $secondProgramNumOfIndividuals) ||
		($firstProgramNumOfPopulations != $secondProgramNumOfPopulations)) {
		die "First and second program files have different parameters!";
	}	
	
	# checking if clumpp params are valid
	if (defined $clumppSearchMethod || defined $clumppGreedyOption) {
		my $numOfRuns = (0+@secondInputFiles) + (0+@secondInputFiles);
		&CheckIfClumppParamsCalcLowerThanDAndCalcClumppRepeats($clumppRepeats, $numOfRuns, $firstProgramNumOfIndividuals, $firstProgramNumOfPopulations, $clumppSearchMethod);
	}
	
	return ($firstInputFilesArr, $secondInputFilesArr);
}





1;