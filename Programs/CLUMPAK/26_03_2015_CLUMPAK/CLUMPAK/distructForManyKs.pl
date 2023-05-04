use strict;
use warnings;
use Getopt::Long;;
use ZipHandler;
use File::Basename;
use File::Slurp;
use ClusterAccessor;
use ClumppIndMatrixAccessor;
use AdmixtureOutputFilesAccessor;
use StructureOutputFilesAccessor;
use PDFCreator;

use lib "/bioseq/bioSequence_scripts_and_constants";
use CLUMPAK_CONSTS_and_Functions;

my $jobId;
my $archiveFile;
my $jobDir;
my $labelsBelowFigureFile;
my $inputFilesType = "structure";
my $admixtureIndToPopfile;
my $clusterPermutationAndColorsFile;
my $drawParamsFile;

GetOptions(
	"id=s"        => \$jobId,
	"dir=s"       => \$jobDir,
	"file=s"      => \$archiveFile,
	"labels=s"    => \$labelsBelowFigureFile,
	"inputtype=s" => \$inputFilesType,
	"indtopop=s"  => \$admixtureIndToPopfile,
	"colors=s"	  => \$clusterPermutationAndColorsFile,
	"drawparams=s" => \$drawParamsFile
);

$inputFilesType = lc($inputFilesType);

my $outputFiles =
  "$jobDir/" . CLUMPAK_CONSTS_and_Functions::OUTPUT_FILES_LIST;
my $imagesToDisplay =
  "$jobDir/" . CLUMPAK_CONSTS_and_Functions::IMAGES_TO_DISPLAY_LIST;
my $log    = "$jobDir/" . CLUMPAK_CONSTS_and_Functions::LOG_FILE;
my $errLog = "$jobDir/" . CLUMPAK_CONSTS_and_Functions::ERROR_STATUS_LOG_FILE;

&WriteToFileWithTimeStamp( $log, "Job $jobId started running." );



eval { &main() };
if ($@) {
	print "Error: $@\n";

	my $rindex = rindex($@, " at");
	my $errMsg = substr($@, 0, $rindex);
	
	&WriteToFileWithTimeStamp( $log, "error occurred - $errMsg." );
	&WriteToFile( $errLog, $@ );
	
	use POSIX qw(strftime);
	my $date = strftime('%F %H:%M:%S', localtime);
	my $logPath = CLUMPAK_CONSTS_and_Functions::LOG_DIR_ABSOLUTE_PATH; 
	$logPath = $logPath.CLUMPAK_CONSTS_and_Functions::DISTRUCT_FOR_MANY_K_ERROR_LOG;
	my $errorInOneLine = $@;
	$errorInOneLine =~ s/\n/ /g;
	
	my $username = getpwuid( $< );
	
	if ($username eq CLUMPAK_CONSTS_and_Functions::WEB_USERNAME){
		&WriteToFile( $logPath, "$jobId\t$date\t\t$errorInOneLine");
	}
}

sub main {
	&CheckInputTypeValid($inputFilesType);
	
	# printing job params
	&PrintJobParams();
	
	# extracting input file
	my ($archiveFileName) = fileparse($archiveFile);
	&WriteToFileWithTimeStamp( $log, "Extracting file: \"$archiveFileName\"." );
	
	my $clumppOutputFilesRef = &ExtractStructureFiles( $archiveFile, $jobId, $jobDir );
	
	my @clumppOutputFiles = @$clumppOutputFilesRef;

	if ( $inputFilesType eq "admixture" ) {
		# send array to admixture accessor and edit admixture files
		
		my ($convertedAdmixtureFilesArr, $popIdToPopNameFileName)= &ConvertAdmixtureFilesToStructureFormat($clumppOutputFilesRef, $jobDir, $admixtureIndToPopfile );
		@clumppOutputFiles = @$convertedAdmixtureFilesArr;		
		
		$labelsBelowFigureFile = $popIdToPopNameFileName;
	}

	my @dataForDistructForeachK;

	my $maxKInFiles = &GetMaxKFromStructureDictOrArray(\@clumppOutputFiles);
	
	print "max k in files is k=$maxKInFiles\n";

	if (defined $clusterPermutationAndColorsFile) {
		print "Checking and sorting user provided clusters and permutations file\n";
		&WriteToFileWithTimeStamp( $log, "Checking and sorting user provided clusters and permutations file\n");
		$clusterPermutationAndColorsFile = CheckAndSortUserClustersPermutationsAndColorsFile($jobDir, $clusterPermutationAndColorsFile, $maxKInFiles);
	}

	&WriteToFileWithTimeStamp( $log, "Extracting parameters from popfile file and output file" );

	my $alignedFilesDir = "$jobDir/aligned.files";

	foreach my $curInputFile ( @clumppOutputFiles ) {
		my ($curFileName, $curFileDir) = fileparse($curInputFile);
		my ( $numOfIndividuals, $kSize, $clumppfileForDistruct ) = &ExtractIndTableFromStructureFiles($alignedFilesDir, $curInputFile, $curFileName);

		my $maxIndividualsAllowed = CLUMPAK_CONSTS_and_Functions::MAX_INDIVIDUALS_ALLOWED;
		
		if ($numOfIndividuals > $maxIndividualsAllowed){
			die "Error: Number of individuals in provided files is $numOfIndividuals, it is larger than max value allowed. CLUMPAK currently supports up to $maxIndividualsAllowed individuals";
		} 
		
		my ($clumppPopFile, $numOfPredefinedPopulations)= &ExtractPopTableFromStructureIndFiles($jobDir, $clumppfileForDistruct, $kSize);
		

		my ($distructCommandsFile,    $distructPdfOutputFile, $distructImageOutputFile, $newLabelsFile ) = 
				&CreateDistructCommands($jobId, $jobDir, $numOfIndividuals, $kSize, $clumppfileForDistruct, $clumppPopFile, $numOfPredefinedPopulations, 
		  									$labelsBelowFigureFile, basename($curInputFile), $clusterPermutationAndColorsFile, $drawParamsFile);

		$labelsBelowFigureFile = $newLabelsFile;

		my %dataForDistruct;

		# $dataForDistruct{'key'} = $key;
		$dataForDistruct{'kSize'}            = $kSize;
		$dataForDistruct{'clumppOutputFile'} = $clumppfileForDistruct;
		$dataForDistruct{'distructBash'}     = $distructCommandsFile;
		$dataForDistruct{'distructPdf'}      = $distructPdfOutputFile;
		$dataForDistruct{'distructImage'}    = $distructImageOutputFile;

		my ( $imageName, $dir, $ext ) = fileparse( $distructImageOutputFile, ".png" );
		$dataForDistruct{'imageName'} = $imageName;
		
		push( @dataForDistructForeachK, \%dataForDistruct );

	}

	@dataForDistructForeachK= sort {
		my %aHash  = %$a;
		my %bHash  = %$b;
		my $aKsize = $aHash{'kSize'};
		my $bKsize = $bHash{'kSize'};
		return $aKsize <=> $bKsize;
	} @dataForDistructForeachK;

	my $smallerKClumppIndFile;
	my $smallerKSize = -1;

	&WriteToFileWithTimeStamp( $log, "Calling distruct for each K" );

	foreach my $dataForDistructRef (@dataForDistructForeachK) {
		my %dataForDistruct = %$dataForDistructRef;
		my $curK            = $dataForDistruct{'kSize'};

		my $clumppIndOutputFile = $dataForDistruct{'clumppOutputFile'};

		if ( $smallerKSize != -1 ) {
			&WriteToFileWithTimeStamp( $log, "Calculating best Average Distance between K=$smallerKSize and K=$curK..");
			&UpdateClumppOutputToClosestPermutation($clumppIndOutputFile, $curK, $smallerKClumppIndFile, $smallerKSize);
		}
		else {
			&WriteToFileWithTimeStamp( $log,
				"Ordering clusters by size for smallest K" );

			&OrderClumppOutputByFirstPopClusters( $clumppIndOutputFile, $curK,
				$labelsBelowFigureFile );
		}

		$smallerKClumppIndFile = $clumppIndOutputFile;
		$smallerKSize          = $curK;

		# call distruct
		print "Calling distruct for $clumppIndOutputFile\n";
		my $bashFile = $dataForDistruct{'distructBash'};
		print "bash file: $bashFile\n";

		my $distructOutput = `bash $bashFile 2>&1`;
		my $image      = $dataForDistruct{'distructImage'};
	
		if (index($distructOutput, "Error:") != -1) {
			die "Error occurred running distruct.\ndistruct error:\n$distructOutput"
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
		
			my $imageName = $dataForDistruct{'imageName'};
			&WriteToFile( $imagesToDisplay, "K=$curK\t$imageName\t$imageName.png" );
	    }
	}
	
	# creating summary pdf
	&WriteToFileWithTimeStamp( $log, "Creating job summary PDF" );
	my $pdfFileName = &CreateDistructForManyKsPDF($jobId, $jobDir, \@dataForDistructForeachK);
	&WriteToFile( $outputFiles, $pdfFileName);

	#	creating zip file
	&WriteToFileWithTimeStamp( $log, "Creating job zip file" );
	my $zipFileName = CreateZipFile($jobId, $jobDir);
	&WriteToFile( $outputFiles, $zipFileName);
	
	&WriteToFileWithTimeStamp( $log, "Job $jobId has finished running." );
	print "Done!\n";
}

sub PrintJobParams {
	&WriteToFileWithTimeStamp( $log, "Job Parameters:" );
	
	my ($archiveFileName) = fileparse($archiveFile);
	&WriteToFileWithTimeStamp( $log, "Input file: $archiveFileName" );
	&WriteToFileWithTimeStamp( $log, "Input type: ".uc($inputFilesType) );
	
	if (defined $labelsBelowFigureFile) {
		my ($labelsBelowFigureFileName) = fileparse($labelsBelowFigureFile);
		&WriteToFileWithTimeStamp( $log, "Labels file: $labelsBelowFigureFileName" );
	}
	
	if (($inputFilesType eq "admixture") && defined $admixtureIndToPopfile) {
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
}