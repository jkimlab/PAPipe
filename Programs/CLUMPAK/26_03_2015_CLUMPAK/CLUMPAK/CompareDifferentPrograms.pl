use strict;
use warnings;
use Getopt::Long;
use ZipHandler;
use File::Basename;
use File::Slurp;
use ZipHandler;
use StructureOutputFilesAccessor;
use AdmixtureOutputFilesAccessor;
use ClumppAccessor;
use ClumppIndMatrixAccessor;
use File::Slurp;
use MCLAccessor;
use Statistics::Distributions;
use ClusterAccessor;
use CompareDifferentProgramsAccessor;
use PDFCreator;
use lib "/bioseq/bioSequence_scripts_and_constants";
use CLUMPAK_CONSTS_and_Functions;

my $jobId;

my $jobDir;
my $firstArchiveFile;
my $secondArchiveFile;
my $labelsBelowFigureFile;
my $firstInputFilesType = "structure";
my $secondInputFilesType = "structure";
my $admixtureIndToPopfile;
my $drawParamsFile;
my $clusterPermutationAndColorsFile;
my $mclThreshold;
my $clumppRepeats;
my $clumppGreedyOption = CLUMPAK_CONSTS_and_Functions::CLUMPP_GREEDY_OPTION_DEFAULT;
my $clumppSearchMethod = CLUMPAK_CONSTS_and_Functions::CLUMPP_SEARCH_METHOD_DEFAULT;
my $mclMinClusterFraction = CLUMPAK_CONSTS_and_Functions::MCL_MIN_CLUSTER_FRACTION;

GetOptions(
	"id=s"        				=> \$jobId,
	"dir=s"       				=> \$jobDir,
	"firstfile=s"      			=> \$firstArchiveFile,
	"secondfile=s"      		=> \$secondArchiveFile,
	"labels=s"    				=> \$labelsBelowFigureFile,
	"firstinputtype=s" 			=> \$firstInputFilesType,
	"secondinputtype=s" 		=> \$secondInputFilesType,
	"indtopop=s"  				=> \$admixtureIndToPopfile,
	"drawparams=s" 				=> \$drawParamsFile,
	"colors=s"	  				=> \$clusterPermutationAndColorsFile,
	"mclthreshold=f" 			=> \$mclThreshold,
	"clumpprepeats=i" 			=> \$clumppRepeats,
#	"clumppgreedyoption=i" 		=> \$clumppGreedyOption,
	"clumppsearchmethod=i" 		=> \$clumppSearchMethod,
	"mclminclusterfraction=f" 	=> \$mclMinClusterFraction
);


$firstInputFilesType = lc($firstInputFilesType);
$secondInputFilesType = lc($secondInputFilesType);

my $outputFiles =
  "$jobDir/" . CLUMPAK_CONSTS_and_Functions::OUTPUT_FILES_LIST;
my $imagesToDisplay =
  "$jobDir/" . CLUMPAK_CONSTS_and_Functions::IMAGES_TO_DISPLAY_LIST;
my $log    = "$jobDir/" . CLUMPAK_CONSTS_and_Functions::LOG_FILE;
my $errLog = "$jobDir/" . CLUMPAK_CONSTS_and_Functions::ERROR_STATUS_LOG_FILE;

&WriteToFileWithTimeStamp( $log, "Job $jobId started running." );

eval { &main() };

if ($@)
{
	print "Error: $@\n";
	
	my $rindex = rindex($@, " at");
	my $errMsg = substr($@, 0, $rindex);
	
	&WriteToFileWithTimeStamp($log, "Error occurred - $errMsg.");
	&WriteToFile($errLog, $@);
	
	use POSIX qw(strftime);
	my $date = strftime('%F %H:%M:%S', localtime);
	my $logPath = CLUMPAK_CONSTS_and_Functions::LOG_DIR_ABSOLUTE_PATH; 
	$logPath = $logPath.CLUMPAK_CONSTS_and_Functions::COMPARE_PROGRAMS_ERROR_LOG;
	my $errorInOneLine = $@;
	$errorInOneLine =~ s/\n/ /g;
	
	my $username = getpwuid( $< );
	
	if ($username eq CLUMPAK_CONSTS_and_Functions::WEB_USERNAME){
		&WriteToFile( $logPath, "$jobId\t$date\t\t$errorInOneLine");
	}
	
}

sub main
{
	# switching order of files if first is admixture and second structure
	if (($firstInputFilesType eq "admixture") && ($secondInputFilesType eq "structure")) {
		my $tempVar = $firstArchiveFile;
		$firstArchiveFile = $secondArchiveFile;
		$secondArchiveFile = $tempVar;
		$firstInputFilesType = "structure";
		$secondInputFilesType = "admixture";
	}

	# printing job params
	&PrintJobParams();	
	
	# Getting first program data
	my ($firstArchiveFileName) = fileparse($firstArchiveFile, ".zip");
	my $firstArchiveDir = "$jobDir/$firstArchiveFileName";
	
	my ($firstInputFilesArr, $newLabelsBelowFigure) = 
					&GetProgramInputFiles($firstArchiveFile, $jobId, $firstArchiveDir, $firstInputFilesType, $admixtureIndToPopfile);
	my @firstInputFiles = @$firstInputFilesArr;
	
	if (defined $newLabelsBelowFigure) {
		$labelsBelowFigureFile = $newLabelsBelowFigure;
	}

	&WriteToFileWithTimeStamp( $log, "Extracting data from $firstArchiveFileName" );	
	
	my ( $firstProgramNumOfIndividuals, $firstProgramNumOfPopulations, $firstProgramClumppIndFile ) = 
					&GetProgramClumppIndFile ($firstArchiveDir, $firstInputFilesArr, $firstInputFilesType);
	
	my $maxIndividualsAllowed = CLUMPAK_CONSTS_and_Functions::MAX_INDIVIDUALS_ALLOWED;
	if ($firstProgramNumOfIndividuals > $maxIndividualsAllowed){
		die "Error: Number of individuals in provided files is $firstProgramNumOfIndividuals, it is larger than max value allowed. CLUMPAK currently supports up to $maxIndividualsAllowed individuals";
	} 
	
	# Getting second program data
	
	my ($secondArchiveFileName) = fileparse($secondArchiveFile, ".zip");
	my $secondArchiveDir = "$jobDir/$secondArchiveFileName";
	
	#checking if first type was structure
	my $structureIndTable;
	if ($firstInputFilesType eq "structure") {
		$structureIndTable = $firstInputFiles[0]; 
	}
	
	my ($secondInputFilesArr, $secondNewLabelsBelowFigure) = 
					&GetProgramInputFiles($secondArchiveFile, $jobId, $secondArchiveDir, $secondInputFilesType, $admixtureIndToPopfile, $structureIndTable);
	my @secondInputFiles = @$secondInputFilesArr;
	
	if (defined $secondNewLabelsBelowFigure) {
		$labelsBelowFigureFile = $secondNewLabelsBelowFigure;
	}
	
	&WriteToFileWithTimeStamp( $log, "Extracting data from $secondArchiveFileName" );	
	
	my ( $secondProgramNumOfIndividuals, $secondProgramNumOfPopulations, $secondProgramClumppIndFile ) = 
					&GetProgramClumppIndFile ($secondArchiveDir, $secondInputFilesArr, $secondInputFilesType);
	
	if ($secondProgramNumOfIndividuals > $maxIndividualsAllowed){
		die "Error: Number of individuals in provided files is $secondProgramNumOfIndividuals, it is larger than max value allowed. CLUMPAK currently supports up to $maxIndividualsAllowed individuals";
	} 
	
	# checking if two files have the same parameters
	if (($firstProgramNumOfIndividuals != $secondProgramNumOfIndividuals) ||
		($firstProgramNumOfPopulations != $secondProgramNumOfPopulations)) {
		die "First and second program files have different parameters!";
	}
	
	# run main pipeline on each file alone
	
	# checking and sorting clusters and permutations file
	if (defined $clusterPermutationAndColorsFile) {
		print "Checking and sorting user provided clusters and permutations file\n";
		&WriteToFileWithTimeStamp( $log, "Checking and sorting user provided clusters and permutations file\n");
		$clusterPermutationAndColorsFile = CheckAndSortUserClustersPermutationsAndColorsFile($jobDir, $clusterPermutationAndColorsFile, $firstProgramNumOfPopulations);
	}	
	
	&WriteToFileWithTimeStamp( $log, "Executing CLUMPP for $firstArchiveFileName." );
	
	my ($firstProgramLargeClusterDataRef, $firstProgramMinorClustersDataRef, $newLabelsBelowFigurefile) =  
				&RunCLUMPPandMCLonProgram($jobId, $firstArchiveDir, $firstArchiveFileName, $firstProgramClumppIndFile,$firstProgramNumOfIndividuals, $firstProgramNumOfPopulations,
											0+@firstInputFiles, \@firstInputFiles, $labelsBelowFigureFile, $firstInputFilesType, $admixtureIndToPopfile,
											 $log, $clusterPermutationAndColorsFile, $drawParamsFile, $mclThreshold, $mclMinClusterFraction, $clumppRepeats, $clumppGreedyOption, $clumppSearchMethod);
	
	$labelsBelowFigureFile = $newLabelsBelowFigurefile;
	
	&WriteToFileWithTimeStamp( $log, "Executing CLUMPP for $secondArchiveFileName." );
	
	my ($secondProgramLargeClusterDataRef, $secondProgramMinorClustersDataRef) =  
				&RunCLUMPPandMCLonProgram($jobId, $secondArchiveDir, $secondArchiveFileName, $secondProgramClumppIndFile,$secondProgramNumOfIndividuals, $secondProgramNumOfPopulations,
											0+@secondInputFiles, \@secondInputFiles, $labelsBelowFigureFile, $secondInputFilesType, $admixtureIndToPopfile,
											$log, $clusterPermutationAndColorsFile, $drawParamsFile, $mclThreshold, $mclMinClusterFraction, $clumppRepeats, $clumppGreedyOption, $clumppSearchMethod);
	
	
	# executing clumpp on the merged results of the clusters
	&WriteToFileWithTimeStamp( $log, "Executing CLUMPP for both programs major and minor modes." );
	my $mergedModesClumppPairMatrixFile = &RunClumppOnMergedModes($jobId, $jobDir, $firstProgramLargeClusterDataRef, $firstProgramMinorClustersDataRef, $secondProgramLargeClusterDataRef, 
			$secondProgramMinorClustersDataRef, $clumppRepeats, $clumppGreedyOption, $clumppSearchMethod);
	
	my $pairMatrixLines = read_file($mergedModesClumppPairMatrixFile);
	print "\n**************************\nThe similarity matrix below gives CLUMPP similarity scores between the modes 
			detected for both modesl:\n$pairMatrixLines\n**************************\n";
	&WriteToFileWithTimeStamp( $log, "Merged modes pair matrix:");
	&WriteToFile( $log, $pairMatrixLines);
	
	# running distruct
	&WriteToFileWithTimeStamp( $log, "Executing distruct for all modes." );
	&RunDistructOnBothPrograms($firstArchiveFileName, $firstProgramLargeClusterDataRef, $firstProgramMinorClustersDataRef, $secondArchiveFileName, 
					$secondProgramLargeClusterDataRef, $secondProgramMinorClustersDataRef, $labelsBelowFigureFile, $log,$jobDir, $outputFiles, $imagesToDisplay);
	
	# creating pdf file
	&WriteToFileWithTimeStamp( $log, "Creating job summary PDF" );
	my $pdfFileName = &CreateCompareDifferentProgramsPDF($jobId, $jobDir, $firstProgramLargeClusterDataRef, $firstProgramMinorClustersDataRef, $secondProgramLargeClusterDataRef, $secondProgramMinorClustersDataRef, $pairMatrixLines);
	&WriteToFile( $outputFiles, $pdfFileName);
	
	#	creating zip file
	&WriteToFileWithTimeStamp( $log, "Creating job zip file" );
	my $zipFileName = CreateZipFile($jobId, $jobDir);
	&WriteToFile( $outputFiles, $zipFileName);
	
	&WriteToFileWithTimeStamp($log, "Job $jobId has finished running.");
	print "Done!\n";
}

sub PrintJobParams {
	&WriteToFileWithTimeStamp( $log, "Job Parameters:" );
	
	my ($archiveFileName) = fileparse($firstArchiveFile);
	&WriteToFileWithTimeStamp( $log, "First input file: $archiveFileName" );
	&WriteToFileWithTimeStamp( $log, "First input type: ".uc($firstInputFilesType) );
	
	$archiveFileName = fileparse($secondArchiveFile);
	&WriteToFileWithTimeStamp( $log, "Second input file: $archiveFileName" );
	&WriteToFileWithTimeStamp( $log, "Second input type: ".uc($secondInputFilesType) );
	
	if (defined $labelsBelowFigureFile) {
		my ($labelsBelowFigureFileName) = fileparse($labelsBelowFigureFile);
		&WriteToFileWithTimeStamp( $log, "Labels file: $labelsBelowFigureFileName" );
	}
	
	if (($secondInputFilesType eq "admixture") && defined $admixtureIndToPopfile) {
		my ($admixtureIndToPopfileName) = fileparse($admixtureIndToPopfile);
		&WriteToFileWithTimeStamp( $log, "Admixture populations file: $admixtureIndToPopfileName" );
	}
	
	if (defined $clusterPermutationAndColorsFile) {
		my ($clusterPermutationAndColorsFileName) = fileparse($clusterPermutationAndColorsFile);
		&WriteToFileWithTimeStamp( $log, "Colors file: $clusterPermutationAndColorsFileName" );
	}
	
	if (defined $drawParamsFile) {
		my ($drawParamsFileName) = fileparse($drawParamsFile);
		&WriteToFileWithTimeStamp( $log, "Drawparams file: $drawParamsFileName" );
	}
	
	if (defined $mclThreshold) {
		&WriteToFileWithTimeStamp( $log, "MCL threshold: $mclThreshold" );
	}
	
	if (defined $clumppRepeats) {
		&WriteToFileWithTimeStamp( $log, "CLUMPP repeats: $clumppRepeats" );
	}
	
	my $clumppSearchMethodString = CLUMPAK_CONSTS_and_Functions::CLUMPP_SEARCH_METHODS->{$clumppSearchMethod};
	&WriteToFileWithTimeStamp( $log, "CLUMPP search method: $clumppSearchMethodString " );

	if ($mclMinClusterFraction != CLUMPAK_CONSTS_and_Functions::MCL_MIN_CLUSTER_FRACTION) {	
		&WriteToFileWithTimeStamp( $log, "MCL cluster size threshold: $mclMinClusterFraction" );
	}
	else {
		&WriteToFileWithTimeStamp( $log, "MCL cluster size threshold: $mclMinClusterFraction (default)" );
	}
}