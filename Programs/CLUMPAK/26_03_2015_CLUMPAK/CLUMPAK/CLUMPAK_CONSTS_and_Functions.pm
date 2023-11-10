package CLUMPAK_CONSTS_and_Functions;

use strict;
use warnings;
use File::Slurp;
use File::Path;# qw(make_path);
use File::Basename;


use vars qw(@ISA @EXPORT);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(WriteToFile WriteToFileWithTimeStamp ReadFromFile CheckInputTypeValid);



######### Consts ###########

use constant SERVER_NAME => "CLUMPAK";
use constant RESULTS_DIR_ABSOLUTE_PATH => "PATH_TO_YOUR_OUTPUT_FOLDER";
use constant RESULTS_LINK => "CLUMPAK_results";
use constant LOG_FILE => "output.log";
use constant DETECTED_MODES_SUMMERY_LOG_FILE => "detectedModesSummery.log"; # ofer
use constant ERROR_STATUS_LOG_FILE => "error.OU";
use constant OUTPUT_FILES_LIST => "output_files.dat";
use constant IMAGES_TO_DISPLAY_LIST => "images_to_display.dat";
use constant QSUB_JOB_NUM_FILE => "qsub_job_num.dat";
use constant JOB_TYPE_FILE => "job_type.dat";
use constant RESULTS_PAGE_URL => "/results.html";
use constant VALID_INPUT_FILE_TYPES => {
	'structure' => 'structure',
	'admixture' => 'admixture',
	'lnprobbyk' => 'lnprobbyk',
};
use constant MAX_K => 8;
use constant MAX_D => 10**13;
use constant COMPUTE_TIME_CHECK => 1;
use constant MCL_MIN_CLUSTER_FRACTION => 0.1;

use constant LOG_DIR_ABSOLUTE_PATH => "PATH_TO_YOUR_LOGS_FOLDER";
use constant MAIN_PIPELINE_LOG => "logSubmitMainPipeline.log";
use constant BEST_K_LOG => 'logSubmitBestK.log';
use constant COMPARE_PROGRAMS_LOG => 'logSubmitCompare.log';
use constant DISTRUCT_FOR_MANY_K_LOG => 'logSubmitDistruct.log';
use constant MAIN_PIPELINE_ERROR_LOG => "logErrorMainPipeline.log";
use constant BEST_K_ERROR_LOG => 'logErrorBestK.log';
use constant COMPARE_PROGRAMS_ERROR_LOG => 'logErrorCompare.log';
use constant DISTRUCT_FOR_MANY_K_ERROR_LOG => 'logErrorDistruct.log';
use constant CLUMPP_GREEDY_OPTION_DEFAULT => 2;
use constant CLUMPP_SEARCH_METHOD_DEFAULT => 3;
use constant CLUMPP_SEARCH_METHODS => {
	1 => 'FullSearch',
	2 => 'Greedy',
	3 => 'LargeKGreedy',
};
use constant CLUMPP_REPEATS_DEFAULT_VALUE => 2000;
use constant EXCLUDED_FILE_EXTENSIONS => {
	 '.sh' => '.sh',
	 '.out' => '.out',
	 '.ER' => '.ER',
	 '.OU' => '.OU',
	 '.dat' => '.dat', 
	 '.png' => '.png',
};
use constant MAX_INDIVIDUALS_ALLOWED => 5000;
use constant PERL_MODULE_TO_LOAD => 'perl/perl518';
use constant WEB_USERNAME => 'YOUR_USERNAME';

######### Functions ############

sub WriteToFileWithTimeStamp
{
	my ($file, $message) = @_;
	
	my $timestamp = localtime();
	
	&WriteToFile($file, "$timestamp: $message");
}

sub WriteToFile
{
	my ($file, $message, $shouldOverwrite) = @_;
	
	# creating file dir if doesnt exist
	my ($fileName, $fileDir) = fileparse($file);
	#make_path($fileDir);
	mkpath($fileDir);
	
	$message =~ s/^\s+//;
	
	if (defined $shouldOverwrite && $shouldOverwrite){
		write_file($file, "$message\n");
	}
	else {
		append_file($file, "$message\n");
	}	
}


sub ReadFromFile
{
	my ($file, $defaultValue) = @_;
	
	if (defined $defaultValue)
	{
		if (-e $file)
		{
			my $line = read_file($file);
			return $line;
		}
		else
		{
			# this is ugly. delete this after renaming all relevant files to dat.
			my ($name, $dir, $ext) = fileparse($file, ".dat");
		 	if ($ext eq ".dat")	{
		 		my $newFile = substr($file, 0, -4);
		 		
		 		if (-e $newFile) {
					my $line = read_file($newFile);
					return $line;
				}
		 	}
			
			return $defaultValue;
		}
	}
	else
	{
		my @lines;
		
		if (-e $file)
		{
			@lines = read_file($file);
		}
		else {
			# this is ugly. delete this after renaming all relevant files to dat.
			my ($name, $dir, $ext) = fileparse($file, ".dat");
		 	if ($ext eq ".dat")	{
		 		my $newFile = substr($file, 0, -4);
		 		
		 		if (-e $newFile) {
					@lines = read_file($newFile);
				}
		 	}
		}
		
		return @lines;
	}
}

sub CheckInputTypeValid {
	my ($inputType) = @_;
	
	if (!defined VALID_INPUT_FILE_TYPES->{$inputType})
	{
		die "Input file type $inputType is invalid\n";
	}
}

1; # modules always end with this 1;