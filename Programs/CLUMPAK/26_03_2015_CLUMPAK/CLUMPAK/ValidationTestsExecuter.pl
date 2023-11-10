use strict;
use warnings;

use Getopt::Long;
use ValidationTests;
use CLUMPAK_CONSTS_and_Functions;

#my $jobId;
#my $archiveFile;
#my $jobDir;
#my $labelsBelowFigureFile;
#my $inputFilesType = "structure";
#my $admixtureIndToPopfile;
#my $clusterPermutationAndColorsFile;
#my $drawParamsFile;
#my $mclThreshold;
#my $clumppSearchMethod; #= CLUMPAK_CONSTS_and_Functions::CLUMPP_SEARCH_METHOD_DEFAULT;
#my $clumppGreedyOption; #= CLUMPAK_CONSTS_and_Functions::CLUMPP_GREEDY_OPTION_DEFAULT;
#my $clumppRepeats;
#my $mclMinClusterFraction; #= CLUMPAK_CONSTS_and_Functions::MCL_MIN_CLUSTER_FRACTION;
#
#GetOptions(
#	"id=s"        				=> \$jobId,
#	"dir=s"      				=> \$jobDir,
#	"file=s"      				=> \$archiveFile,
#	"labels=s"    				=> \$labelsBelowFigureFile,
#	"inputtype=s" 				=> \$inputFilesType,
#	"indtopop=s"  				=> \$admixtureIndToPopfile,
#	"colors=s"	  				=> \$clusterPermutationAndColorsFile,
#	"drawparams=s" 				=> \$drawParamsFile,
#	"mclthreshold=f" 			=> \$mclThreshold,
#	"clumpprepeats=i" 			=> \$clumppRepeats,
#	"clumppgreedyoption=i" 		=> \$clumppGreedyOption,
#	"clumppsearchmethod=i" 		=> \$clumppSearchMethod,
#	"mclminclusterfraction=f" 	=> \$mclMinClusterFraction
#);
#
#
#&CLUMPAKValidationTests($archiveFile, $inputFilesType, $jobId, $jobDir, $labelsBelowFigureFile, $admixtureIndToPopfile, $clumppRepeats, $clumppSearchMethod);

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
	"clumppgreedyoption=i" 		=> \$clumppGreedyOption,
	"clumppsearchmethod=i" 		=> \$clumppSearchMethod,
	"mclminclusterfraction=f" 	=> \$mclMinClusterFraction
);

&CompareDifferentProgramsValidationTests($firstArchiveFile, $firstInputFilesType, $secondArchiveFile, $secondInputFilesType, $jobId, $jobDir, $labelsBelowFigureFile, $admixtureIndToPopfile);


print "Done validating\n";
exit (0);