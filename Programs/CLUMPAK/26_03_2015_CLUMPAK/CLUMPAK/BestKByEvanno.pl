use strict;
use warnings;
use Getopt::Long;
use ZipHandler;
use StructureOutputFilesAccessor;
use BestKByEvannoAccessor;
use File::Basename;

use lib "/bioseq/bioSequence_scripts_and_constants";
use CLUMPAK_CONSTS_and_Functions;

my $jobId;
my $inputFile;
my $jobDir;
my $inputFilesType = "structure";


GetOptions(
	"id=s"        		=> \$jobId,
	"dir=s"      		=> \$jobDir,
	"file=s"      		=> \$inputFile,
	"inputtype=s" 		=> \$inputFilesType
);


my $outputFiles = "$jobDir/".CLUMPAK_CONSTS_and_Functions::OUTPUT_FILES_LIST;
my $log = "$jobDir/".CLUMPAK_CONSTS_and_Functions::LOG_FILE;
my $errLog = "$jobDir/".CLUMPAK_CONSTS_and_Functions::ERROR_STATUS_LOG_FILE;
my $imagesToDisplay = "$jobDir/".CLUMPAK_CONSTS_and_Functions::IMAGES_TO_DISPLAY_LIST;

&WriteToFileWithTimeStamp($log, "Job $jobId started running.");

eval {&main()};
if ($@)
{
	print "Error: $@\n";
	
	my $rindex = rindex($@, " at");
	my $errMsg = substr($@, 0, $rindex);	
	
	&WriteToFileWithTimeStamp($log, "error occurred - $errMsg.");
	&WriteToFile($errLog, $@);
	
	use POSIX qw(strftime);
	my $date = strftime('%F %H:%M:%S', localtime);
	my $logPath = CLUMPAK_CONSTS_and_Functions::LOG_DIR_ABSOLUTE_PATH; 
	$logPath = $logPath.CLUMPAK_CONSTS_and_Functions::BEST_K_ERROR_LOG;
	my $errorInOneLine = $@;
	$errorInOneLine =~ s/\n/ /g;
	
	my $username = getpwuid( $< );
	
	if ($username eq CLUMPAK_CONSTS_and_Functions::WEB_USERNAME){
		&WriteToFile( $logPath, "$jobId\t$date\t\t$errorInOneLine");
	}
}

sub main
{
	my ($sortedStructureFilesDict, $lnProbbyKTable);
	
	if ($inputFilesType eq 'lnprobbyk') {
		$lnProbbyKTable = $inputFile;
	}
	else {
		my $structureFilesArrRef = &ExtractStructureFiles( $inputFile, $jobId, $jobDir );
		my ($maxKInFiles, $maxKFile);
		($sortedStructureFilesDict, $maxKInFiles, $maxKFile) = &SortStructureFilesDict($structureFilesArrRef);
	
	}
	
	print "\nRetrieving data from files for each K\n"; 
	&WriteToFileWithTimeStamp($log, "Retrieving data from files for each K");
	
	my ($meanByKDict, $stddevByKDict, $medianByKDict);
	
	if (defined $sortedStructureFilesDict) {
		($meanByKDict, $stddevByKDict, $medianByKDict) = &GetDataFromInputFiles($sortedStructureFilesDict);
	}
	else {
		($meanByKDict, $stddevByKDict, $medianByKDict) = &GetDataFromLbProbByKtableFile($lnProbbyKTable);
	}
	
	my %meanByK = %$meanByKDict;
	my %stddevByK = %$stddevByKDict;
	my %medianByK = %$medianByKDict;
	
	foreach my $k (sort {$a <=> $b} keys %stddevByK) {
		print "Data for K=$k:\n";
		print "mean: $meanByK{$k}\n";
		print "standard deviation: $stddevByK{$k}\n";
		print "median: $medianByK{$k}\n";
		
		&WriteToFileWithTimeStamp($log, "K=$k mean: $meanByK{$k}");
		&WriteToFileWithTimeStamp($log, "K=$k standard deviation: $stddevByK{$k}");
		&WriteToFileWithTimeStamp($log, "K=$k median: $medianByK{$k}");
	}
	
	print "Calculating Best K by Evanno..\n";
	&WriteToFileWithTimeStamp($log, "Calculating Best K by Evanno");
	my ($kForMaxDelta, $deltaKGraph ) = &BestKByEvanno($jobDir, $meanByKDict, $stddevByKDict, $log);
	
	print "\nUsing median values of Ln Prob of Data to calculate Prob(K=k)..\n";
	&WriteToFileWithTimeStamp($log, "Using median values of Ln Prob of Data to calculate Prob(K=k):");
	my ($kForMaxProb, $probByKGraph ) = &BestKByPritchard($jobDir, $medianByKDict, $log);
	
	
	my ($deltaKGraphFileName) = fileparse($deltaKGraph);
	&WriteToFile($imagesToDisplay, "DeltaK graph\tOptimal K by Evanno is: $kForMaxDelta\t$deltaKGraphFileName");
	
	my ($probByKGraphFileName) = fileparse($probByKGraph);
	&WriteToFile($imagesToDisplay, "Probability By K graph\tUsing median values of Ln(Pr Data) the k for which Pr(K=k) is highest: $kForMaxProb\t$probByKGraphFileName");
	
	
	#	creating zip file
	&WriteToFileWithTimeStamp( $log, "Creating job zip file" );
	my $zipFileName = CreateZipFile($jobId, $jobDir);
	&WriteToFile( $outputFiles, $zipFileName);
		
	&WriteToFileWithTimeStamp($log, "Job $jobId has finished running.");
	print "Done!\n";
}
