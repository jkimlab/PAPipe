#!/usr/bin/perl -w

use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin";
use lib "/usr/local/share/perl/5.26.1";
use lib "/usr/local/lib/x86_64-linux-gnu/perl/5.26.1";
use Getopt::Long;
use File::Basename;
use StructureOutputFilesAccessor;
use AdmixtureOutputFilesAccessor;
use ClumppAccessor;
use ZipHandler;
use MCLAccessor;
#use MaxCliqueAccessor;
use ClusterAccessor;
use ClumppIndMatrixAccessor;
use File::Slurp;
use PDFCreator;
use BestKByEvannoAccessor;

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
my $mclThreshold;
my $clumppSearchMethod = CLUMPAK_CONSTS_and_Functions::CLUMPP_SEARCH_METHOD_DEFAULT;
my $clumppGreedyOption = CLUMPAK_CONSTS_and_Functions::CLUMPP_GREEDY_OPTION_DEFAULT;
my $clumppRepeats;
my $mclMinClusterFraction = CLUMPAK_CONSTS_and_Functions::MCL_MIN_CLUSTER_FRACTION;

GetOptions(
	"id=s"        				=> \$jobId,
	"dir=s"      				=> \$jobDir,
	"file=s"      				=> \$archiveFile,
	"labels=s"    				=> \$labelsBelowFigureFile,
	"inputtype=s" 				=> \$inputFilesType,
	"indtopop=s"  				=> \$admixtureIndToPopfile,
	"colors=s"	  				=> \$clusterPermutationAndColorsFile,
	"drawparams=s" 				=> \$drawParamsFile,
	"mclthreshold=f" 			=> \$mclThreshold,
	"clumpprepeats=i" 			=> \$clumppRepeats,
#	"clumppgreedyoption=i" 		=> \$clumppGreedyOption,
	"clumppsearchmethod=i" 		=> \$clumppSearchMethod,
	"mclminclusterfraction=f" 	=> \$mclMinClusterFraction
);

$inputFilesType = lc($inputFilesType);

my $outputFiles =
  "$jobDir/" . CLUMPAK_CONSTS_and_Functions::OUTPUT_FILES_LIST;
my $imagesToDisplay =
  "$jobDir/" . CLUMPAK_CONSTS_and_Functions::IMAGES_TO_DISPLAY_LIST;
my $log    = "$jobDir/" . CLUMPAK_CONSTS_and_Functions::LOG_FILE;

# ofer - added an output file - detectedModesSummery.log
my $detectedModesSummeryLogfile    = "$jobDir/" . CLUMPAK_CONSTS_and_Functions::DETECTED_MODES_SUMMERY_LOG_FILE;

my $errLog = "$jobDir/" . CLUMPAK_CONSTS_and_Functions::ERROR_STATUS_LOG_FILE;

&WriteToFileWithTimeStamp( $log, "Job $jobId started running." );

eval { &main() }; #call to main within a try-catch mechanism
if ($@) {
	print "Error: $@\n";

	my $rindex = rindex($@, " at");
	my $errMsg = substr($@, 0, $rindex);

	&WriteToFileWithTimeStamp( $log, "error occurred - $errMsg." ); #this function is at CLUMPAK_CONSTS_and_Functions
	&WriteToFile( $errLog, $@ );
	
	use POSIX qw(strftime);
	my $date = strftime('%F %H:%M:%S', localtime);
	my $logPath = CLUMPAK_CONSTS_and_Functions::LOG_DIR_ABSOLUTE_PATH; 
	$logPath = $logPath.CLUMPAK_CONSTS_and_Functions::MAIN_PIPELINE_ERROR_LOG;
	my $errorInOneLine = $@;
	$errorInOneLine =~ s/\n/ /g;
	
	my $username = getpwuid( $< );
	
	if ($username eq CLUMPAK_CONSTS_and_Functions::WEB_USERNAME){
		&WriteToFile( $logPath, "$jobId\t$date\t\t$errorInOneLine");
	}
		
	exit(1);
}

sub main {

	# ofer
	my %hashOfArrAvgDist = ();

	&CheckInputTypeValid($inputFilesType); # in CLUMPAK_CONSTS_and_Functions
	
	# printing job params
	&PrintJobParams();
		
	# extracting file
	my ($archiveFileName) = fileparse($archiveFile);
	&WriteToFileWithTimeStamp( $log, "Extracting file: \"$archiveFileName\"." );
	my $structureFilesArrRef = &ExtractStructureFiles( $archiveFile, $jobId, $jobDir ); #this part is regular unzipping, for structure or admixutre

	if ( $inputFilesType eq "admixture" ) {
		# send dictionary to admixture accessor and edit admixture files
		my ($convertedAdmixtureFilesArr, $popIdToPopNameFileName)= &ConvertAdmixtureFilesToStructureFormat($structureFilesArrRef, $jobDir, $admixtureIndToPopfile );

		$structureFilesArrRef = $convertedAdmixtureFilesArr;
		$labelsBelowFigureFile = $popIdToPopNameFileName; #clear from this part that we do not expect label file with the ADMIXTURE option
	}

	# sorting inputFiles
	print "Sorting input files by K\n";
	&WriteToFileWithTimeStamp( $log, "Sorting input files by K");
	
	my ($sortedStructureFilesDict, $maxKInFiles, $maxKFile) = &SortStructureFilesDict($structureFilesArrRef); #key is K, value is arr with file names
	my %structureFilesByKey = %$sortedStructureFilesDict; #de-referecing the hash 
 
	print "max k in files is k=$maxKInFiles\n";

	if (defined $clusterPermutationAndColorsFile) {
		print "Checking and sorting user provided clusters and permutations file\n";
		&WriteToFileWithTimeStamp( $log, "Checking and sorting user provided clusters and permutations file");
		$clusterPermutationAndColorsFile = &CheckAndSortUserClustersPermutationsAndColorsFile($jobDir, $clusterPermutationAndColorsFile, $maxKInFiles);
	}

	my @largeClustersData; #for each k one cluster, biggest. (for distruct)
	my %minorClustersDataByKey; # all minors. (for distruct)

	my @keys = sort {
		$a =~ /(\d+)/;
	    my $numA = $1;
    	$b =~ /(\d+)/;
    	my $numB = $1;
    	return $numA <=> $numB;
	} keys %structureFilesByKey;
	
	foreach my $key ( @keys ) {
		&WriteToFile( $detectedModesSummeryLogfile, "$key" );
		&WriteToFileWithTimeStamp( $log, "Working on $key" );
		my $structureFilesArr = $structureFilesByKey{$key};
		my @structureFiles    = @$structureFilesArr;
		my $numOfRuns         = 0 + @structureFiles;

		my $jobIdForK = "$jobDir/$key";

		my ( $numOfIndividuals, $numOfPopulations, $clumppIndFile ) = &ExtractIndTableFromStructureFiles( "$jobIdForK/CLUMPP.files", \@structureFiles );
	
		my $maxIndividualsAllowed = CLUMPAK_CONSTS_and_Functions::MAX_INDIVIDUALS_ALLOWED;
		
		if ($numOfIndividuals > $maxIndividualsAllowed){
			die "Error: Number of individuals in provided files is $numOfIndividuals, it is larger than max value allowed. CLUMPAK currently supports up to $maxIndividualsAllowed individuals";
		} 
	
		&WriteToFileWithTimeStamp( $log, "Executing CLUMPP for $key." );
		my $clumppPairMatrixFile = &ExecuteCLUMPPGetPairMatrix($jobId, $clumppIndFile, $numOfIndividuals, $numOfPopulations, $numOfRuns, $clumppRepeats, $clumppGreedyOption, $clumppSearchMethod);

		# mcl
		&WriteToFileWithTimeStamp( $log, "Clustering $key with mcl." );
		
		# ofer - added arrAvgDist as out param
		my ( $mclLargeCluster, $minorClustersRef, $usedCutoff, $arrAvgDist ) = 
						&GetMCLClustersFromCLUMPPPairMatrixFile( $jobIdForK, $clumppPairMatrixFile, $numOfRuns, $mclMinClusterFraction, $mclThreshold );
						
		
		# ofer - save the curr arrAvgDist for later - fro the image headers text
		$hashOfArrAvgDist{$key} = $arrAvgDist;
		#&WriteToFileWithTimeStamp( $log, "ofer avgDist: @$arrAvgDist" );
		#&WriteToFile( $detectedModesSummeryLogfile, "@$arrAvgDist" );
						
		my @minorClusters = @$minorClustersRef; #this is an arr of refs to arrs
		my $largeCluster  = $mclLargeCluster; #this is a ref to an arr
		
		if ($usedCutoff != -1) {
			&WriteToFileWithTimeStamp( $log, "cutoff used: $usedCutoff" );
		}
		else {
			&WriteToFileWithTimeStamp( $log, "no cutoff was used" );
		}

		if ( $largeCluster != -1 ) {

			# large cluster
			&WriteToFileWithTimeStamp( $log, "Executing CLUMPP for major cluster." );

			my ( $largeClusterClumppOutputFile, $distructCommandsFile,$distructPdfOutputFile, $distructImageOutputFile, $newLabelsFile, $clusterLnProbValuesRef) = 
					&ExecuteCLUMPPForCluster($jobId, "$jobIdForK/MajorCluster", $largeCluster, \@structureFiles, $numOfPopulations, $labelsBelowFigureFile, 
												$inputFilesType,$admixtureIndToPopfile, $clusterPermutationAndColorsFile, $drawParamsFile, $clumppRepeats, $clumppGreedyOption, $clumppSearchMethod);

			$labelsBelowFigureFile = $newLabelsFile;

			my %largeClusterData;
			$largeClusterData{'key'}   = $key;
			$largeClusterData{'kSize'} = $numOfPopulations;
			$largeClusterData{'clumppOutputFile'} = $largeClusterClumppOutputFile;
			$largeClusterData{'distructBash'}  = $distructCommandsFile;
			$largeClusterData{'distructPdf'}   = $distructPdfOutputFile;
			$largeClusterData{'distructImage'} = $distructImageOutputFile;
			
			# 	LnProb calculation
			if (0+@$clusterLnProbValuesRef) {
				print "Calculating Large Cluster LnProb mean and stddev..\n";
				&WriteToFileWithTimeStamp( $log, "Calculating major cluster LnProb mean and standard deviation." );
				my $mean = &average($clusterLnProbValuesRef);
				my $stddev = &stdev($clusterLnProbValuesRef);
				print "mean: $mean\n";
				print "standard deviation: $stddev\n";
				&WriteToFileWithTimeStamp( $log, "LnProb mean: $mean" );
				&WriteToFileWithTimeStamp( $log, "LnProb standard deviation: $stddev" );

				my $clusterSize = 0 + @$largeCluster;
				# ofer
				my $roundedMean 	= sprintf("%.3f", $mean);
				my $roundedAvgDist 	= sprintf("%.3f", @$arrAvgDist[0]);
				#&WriteToFile( $detectedModesSummeryLogfile, "$clusterSize/$numOfRuns\t\t\t\tLnProb mean: $mean\t\t\t\tMean similarity score: @$arrAvgDist[0]");
				&WriteToFile( $detectedModesSummeryLogfile, "$clusterSize/$numOfRuns\t\t\t\tLnProb mean: $roundedMean\t\t\t\tMean similarity score: $roundedAvgDist");

				$largeClusterData{'LnProbMean'} = $mean;
				$largeClusterData{'LnProbStdev'} = $stddev;
			}

			my $clusterSize = 0 + @$largeCluster;
#			$largeClusterData{'clusterText'} = "Major cluster, $clusterSize/$numOfRuns";
			$largeClusterData{'clusterText'} = "$clusterSize/$numOfRuns";
			
			push( @largeClustersData, \%largeClusterData );
			
			
			#minor clusters
			if ( 0 + @minorClusters > 0 ) {
				&WriteToFileWithTimeStamp( $log,
					"Executing CLUMPP for minor clusters." );
				print "number of minor clusters: " . ( 0 + @minorClusters ), "\n";
				my @curKeyMinorClustersData;

				for ( my $i = 0 ; $i < 0 + @minorClusters ; $i++ ) {
					my $minorCluster = $minorClusters[$i];

					print "first minor cluster:\t",
					  join( "\t", @$minorCluster ), "\n";

					my $minorClusterId = "MinorCluster" . ( $i + 1 );
					my %minorClusterData;
					my ($minorClusterClumppOutputFile,$minorDistructCommandsFile,	$minorDistructPdfOutputFile, $minorDistructImageOutputFile, $newLabelsFile, $clusterLnProbValuesRef) = 
						&ExecuteCLUMPPForCluster($jobId, "$jobIdForK/$minorClusterId", $minorCluster, \@structureFiles, $numOfPopulations, $labelsBelowFigureFile, 
									$inputFilesType, $admixtureIndToPopfile, $clusterPermutationAndColorsFile, $drawParamsFile, $clumppRepeats, $clumppGreedyOption, $clumppSearchMethod);
					$labelsBelowFigureFile = $newLabelsFile;
					
					
					
					$minorClusterData{'minorClusterId'} = $minorClusterId;
					$minorClusterData{'clumppOutputFile'} = $minorClusterClumppOutputFile;
					$minorClusterData{'distructBash'} = $minorDistructCommandsFile;
					$minorClusterData{'distructPdf'} = $minorDistructPdfOutputFile;
					$minorClusterData{'distructImage'} = $minorDistructImageOutputFile;
					
					# 		LnProb calculation
					if (0+@$clusterLnProbValuesRef) {
						print "Calculating $minorClusterId LnProb mean and stddev..\n";
						&WriteToFileWithTimeStamp( $log, "Calculating $minorClusterId LnProb mean and standard deviation." );
						my $mean = &average($clusterLnProbValuesRef);
						my $stddev = &stdev($clusterLnProbValuesRef);
						print "mean: $mean\n";
						print "standard deviation: $stddev\n";
						&WriteToFileWithTimeStamp( $log, "LnProb mean: $mean" );
						&WriteToFileWithTimeStamp( $log, "LnProb standard deviation: $stddev" );

						my $clusterSize = 0 + @$minorCluster;
						# ofer
						my $roundedMean 	= sprintf("%.3f", $mean);
						my $roundedAvgDist 	= sprintf("%.3f", @$arrAvgDist[$i + 1]);
						#&WriteToFile( $detectedModesSummeryLogfile, "$clusterSize/$numOfRuns\t\t\t\tLnProb mean: $mean\t\t\t\tMean similarity score: @$arrAvgDist[$i + 1]");
						&WriteToFile( $detectedModesSummeryLogfile, "$clusterSize/$numOfRuns\t\t\t\tLnProb mean: $roundedMean\t\t\t\tMean similarity score: $roundedAvgDist");
						


						$minorClusterData{'LnProbMean'} = $mean;
						$minorClusterData{'LnProbStdev'} = $stddev;
					}
					my $clusterSize = 0 + @$minorCluster;
#					$minorClusterData{'clusterText'} = "Minor cluster #".($i+1).", $clusterSize/$numOfRuns";
					$minorClusterData{'clusterText'} = "$clusterSize/$numOfRuns";
					
					push( @curKeyMinorClustersData, \%minorClusterData );
				}

				$minorClustersDataByKey{$key} = \@curKeyMinorClustersData;
			}
		}
	}

	@largeClustersData = sort {
		my %aHash  = %$a;
		my %bHash  = %$b;
		my $aKsize = $aHash{'kSize'};
		my $bKsize = $bHash{'kSize'};
		return $aKsize <=> $bKsize;
	} @largeClustersData;

	my $smallerKClumppIndFile;
	my $smallerKSize = -1;
	
	my %smallersKData;
	

	foreach my $largeClusterHashRef (@largeClustersData) {
		my %largeClusterHash    = %$largeClusterHashRef;
		my $curK                = $largeClusterHash{'kSize'};
		my $key                 = $largeClusterHash{'key'};
		my $clumppIndOutputFile = $largeClusterHash{'clumppOutputFile'};

		if ( $smallerKSize != -1 ) {
			&WriteToFileWithTimeStamp( $log, "Calculating best Average Distance between K=$smallerKSize and K=$curK..");
			&UpdateClumppOutputToClosestPermutation($clumppIndOutputFile, $curK, $smallerKClumppIndFile, $smallerKSize);
			
			# added to compare minor cluster to smaller K
			$largeClusterHash{'smallerKClumppIndFile'} = $smallerKClumppIndFile;
			$largeClusterHash{'smallerKSize'} =	$smallerKSize;
			$smallersKData{$key} = \%largeClusterHash;
		}
		else {
			&WriteToFileWithTimeStamp( $log, "Ordering clusters by size for K=$curK");
			&OrderClumppOutputByFirstPopClusters( $clumppIndOutputFile, $curK, $labelsBelowFigureFile ); 
		}

		$smallerKClumppIndFile = $clumppIndOutputFile;
		$smallerKSize          = $curK;

		my $clusterName = "$key.MajorCluster";

		# call distruct
		print "Calling distruct for $clusterName\n";
		&WriteToFileWithTimeStamp( $log, "Calling distruct for $clusterName" );

		my $bashFile = $largeClusterHash{'distructBash'};
		print "bash file: $bashFile\n";
		my $distructOutput = `bash $bashFile 2>&1`;
		my $image      = $largeClusterHash{'distructImage'};
	    	
	    print "Distruct output:\n$distructOutput\n";

    	if (index($distructOutput, "Error:") != -1) {
			die "Error occurred running distruct for $clusterName.\ndistruct error:\n$distructOutput"
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
	    	die "Error occurred- distruct output image is missing.";
	    }
    	else {
			my $cpImageCmd = "cp $image $jobDir/$clusterName.png";
			print `$cpImageCmd`;
	
			# ofer
			my $mean		= $largeClusterHash{'LnProbMean'};
			my $clusterText = $largeClusterHash{'clusterText'};

			my $roundedMean 	= sprintf("%.3f", $largeClusterHash{'LnProbMean'});
			my $roundedAvgDist 	= sprintf("%.3f", @{$hashOfArrAvgDist{$key}}[0]);

			#&WriteToFile( $imagesToDisplay, "K=$curK\t$clusterText, Mean(LnProb) = $mean, Mean(similarity score) = @{$hashOfArrAvgDist{$key}}[0]\t$clusterName.png" );
			&WriteToFile( $imagesToDisplay, "K=$curK\t$clusterText, Mean(LnProb) = $roundedMean, Mean(similarity score) = $roundedAvgDist\t$clusterName.png" );
    	}
	}

	foreach my $largeClusterHashRef (@largeClustersData) {
		my %largeClusterHash = %$largeClusterHashRef;
		my $curK             = $largeClusterHash{'kSize'};
		my $key              = $largeClusterHash{'key'};
		my $laregClusterClumppIndOutputFile =
		  $largeClusterHash{'clumppOutputFile'};

		if ( exists $minorClustersDataByKey{$key} ) {
			my $minorClustersDataRef = $minorClustersDataByKey{$key};
			my @minorClustersData    = @$minorClustersDataRef;

			my $count=0; #ofer
			foreach my $minorClusterDataRef (@minorClustersData) {
				$count ++;
				my %minorClusterData = %$minorClusterDataRef;

				my $minorClusterId  = $minorClusterData{'minorClusterId'};
				my $minorClusteName = "$key.$minorClusterId";
				my $minorClusterClumppIndoutputFile =
				  $minorClusterData{'clumppOutputFile'};

				&WriteToFileWithTimeStamp( $log, "Calculating best Average Distance between large cluster and $minorClusteName.." );
				
				if (exists $smallersKData{$key}){
					# added to compare minor cluster to smaller K
					
					my $dataForSmallerKRef = $smallersKData{$key};
					my %dataForSmallerK = %$dataForSmallerKRef;
					my $smallerK = $dataForSmallerK{'smallerKSize'};
					my $smallerKClumppIndFile = $dataForSmallerK{'smallerKClumppIndFile'};


					print "smallerKClumppIndFile exists for $key\n";

					print "Comparing $minorClusteName to large cluster of k=$smallerK\n";
					&UpdateClumppOutputToClosestPermutation($minorClusterClumppIndoutputFile, $curK, $smallerKClumppIndFile, $smallerK);
				}
				else {
					# compare to lare cluster of same K			
					&UpdateClumppOutputToClosestPermutation($minorClusterClumppIndoutputFile, $curK, $laregClusterClumppIndOutputFile, $curK);
				}


				# call distruct
				print "Calling distruct for $minorClusteName\n";
				&WriteToFileWithTimeStamp( $log,
					"Calling distruct for $minorClusteName" );

				my $bashFile = $minorClusterData{'distructBash'};
				print "bash file: $bashFile\n";
				my $distructOutput = `bash $bashFile 2>&1`;
				my $image      = $minorClusterData{'distructImage'};
				
				print "Distruct output:\n$distructOutput\n";
    			
    			if (index($distructOutput, "Error:") != -1) {
					die "Error occurred running distruct for $minorClusteName.\ndistruct error:\n$distructOutput"
					
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
			    	die "Error occurred - distruct output image is missing.";
			    }
    			else {
					my $cpImageCmd = "cp $image $jobDir/$minorClusteName.png";
					print `$cpImageCmd`;
	
					# ofer
					my $mean		= $minorClusterData{'LnProbMean'};
					#my $stddev		= $minorClusterData{'LnProbStdev'};
					my $clusterText = $minorClusterData{'clusterText'};

					my $roundedMean 	= sprintf("%.3f", $mean);
					my $roundedAvgDist 	= sprintf("%.3f", @{$hashOfArrAvgDist{$key}}[$count]);

					#&WriteToFile( $imagesToDisplay, "K=$curK\t$clusterText, Mean(LnProb) = $mean, Mean(similarity score) = @{$hashOfArrAvgDist{$key}}[$count]\t$minorClusteName.png");
					&WriteToFile( $imagesToDisplay, "K=$curK\t$clusterText, Mean(LnProb) = $roundedMean, Mean(similarity score) = $roundedAvgDist\t$minorClusteName.png");
    			}
			}
		}
	}
	
	# creating summary pdf
	&WriteToFileWithTimeStamp( $log, "Creating job summary PDF" );
	my $pdfFileName = CreateCLUMPAKPDF($jobId, $jobDir, \@largeClustersData, \%minorClustersDataByKey);
	&WriteToFile( $outputFiles, $pdfFileName);
	
	#creating zip file
	&WriteToFileWithTimeStamp( $log, "Creating job zip file" );
	my $zipFileName = CreateZipFile($jobId, $jobDir);
	&WriteToFile( $outputFiles, $zipFileName);
	
	&WriteToFileWithTimeStamp( $log, "Job $jobId has finished running." );
	print "Done!\n";
	exit(0);
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
