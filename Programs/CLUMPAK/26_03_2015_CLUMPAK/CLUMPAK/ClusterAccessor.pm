package ClusterAccessor;

use strict;
use warnings;
use File::Path;
use StructureOutputFilesAccessor;
use AdmixtureOutputFilesAccessor;
use ClumppAccessor;
use File::Basename;
use File::Slurp;
use PDFCreator;
#use ValidationTests;

use vars qw(@ISA @EXPORT);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(ManageClusters ExecuteCLUMPPForCluster CreateDistructCommands CheckAndSortUserClustersPermutationsAndColorsFile);

sub ExecuteCLUMPPForCluster
{
	my ($jobId, $clusterDir, $clusterMembersRef, $allFiles, $kSize, $labelsBelowFigureFile, $inputFilesType, $admixtureIndToPopfile, 
					$clusterPermutationAndColorsFile, $drawParamsFile, $clumppRepeats, $clumppGreedyOption, $clumppSearchMethod) = @_;
	my @allInputFiles = @$allFiles;
	my @clusterMembers = @$clusterMembersRef;
	
	my @inputFiles;
	my @inputFilesNames;
	foreach my $member (@clusterMembers)
	{
		my $curFile = "$allInputFiles[$member]";
		push (@inputFiles, "$curFile\n");
		
		my ($curFileName) = fileparse($curFile);
		push (@inputFilesNames, "$curFileName\n");
	}
	
	# creating cluster directory
	mkpath($clusterDir);
	
	# creating file with cluster file names	
	write_file("$clusterDir/clusterFiles", @inputFilesNames);
	
	# creating individuals file for clumpp
	
	
	my ($numOfIndividuals, $numOfPopulations, $clumppIndFile, $clumppPopFileName, $numOfPredefinedPopulations);
		
	print "\n\nExtracting Cluster Individuals table..\n";
	($numOfIndividuals, $numOfPopulations, $clumppIndFile) = &ExtractIndTableFromStructureFiles("$clusterDir/CLUMPP.files", \@inputFiles);

	print "\n\nExtracting Cluster predefined populations table..\n";	
	($clumppPopFileName, $numOfPredefinedPopulations) = &ExtractPopTableFromStructureFiles("$clusterDir/CLUMPP.files", $inputFiles[0]);
	
	# calling clumpp
	print "\nCall CLUMPP for cluster $clusterDir\n";
	my $clumppIndOutputFile = &ExecuteCLUMPPGetOutputFile($jobId, $clumppIndFile, $numOfIndividuals, $numOfPopulations, 0+@inputFiles, $clumppRepeats, $clumppGreedyOption, $clumppSearchMethod);
	
	# creating distruct bash file
	my  ($distructCommandsFile, $distructPdfOutputFile, $distructImageOutputFile, $newLabelsFile) =
		 &CreateDistructCommands($jobId, $clusterDir, $numOfIndividuals, $numOfPopulations, $clumppIndOutputFile, $clumppPopFileName, $numOfPredefinedPopulations, 
		 	$labelsBelowFigureFile, "distructOutput", $clusterPermutationAndColorsFile, $drawParamsFile);
	
	# reading likelihoods from structure files
	my $clusterLnProbValuesRef = &ExtractLnProbFromStructureFilesArr(\@inputFiles); 
	
	return ($clumppIndOutputFile, $distructCommandsFile, $distructPdfOutputFile, $distructImageOutputFile, $newLabelsFile, $clusterLnProbValuesRef);
}

sub CreateDistructCommands
{
	my ($jobId, $clusterDir, $numOfIndividuals, $numOfPopulations, $clumppIndOutputFile, $clumppPopFileName, $numOfPredefinedPopulations, $labelsBelowFigureFile, 
			$outputFilename, $clusterPermutationAndColorsFile, $drawParamsFile) = @_;

	my $distructOuptputFileTempName = "out.ps";
	my $distructOuptputFile = "$outputFilename.ps";
	
	if (!defined $clusterPermutationAndColorsFile) {
		print "ClustersPermutationandcolors file was not provided by the user or it's in the wrong format. using default file.\n";
		$clusterPermutationAndColorsFile = "distruct/ClustersPermutationsAndColorsFile";
	}	
	
	# check if labels file is defined, if not create one.
	if (!defined $labelsBelowFigureFile)
	{
		$labelsBelowFigureFile = "$clusterDir/labelsBelowFigure";
		&CreateLabelsBelowFigureFile($clumppPopFileName, $labelsBelowFigureFile)
	}
	else
	{
		#checking if label file is valid
		&CheckDistructLabelsFileFormat($labelsBelowFigureFile, $clumppPopFileName);
	}

	# creating new drawparams file with new calculated indivwidth parameter
	if (!defined $drawParamsFile) {
		$drawParamsFile = "/PAPipe/Programs/CLUMPAK/26_03_2015_CLUMPAK/CLUMPAK/distruct/drawparams";
	}
	
	my $newDrawparams = "$clusterDir/drawparams";
	&ChangeIndividualWidthParameterInDrawparams($drawParamsFile, $newDrawparams , $numOfIndividuals);
	
	my @distructCommands;
	
	push (@distructCommands, "#!/bin/bash\n");
	
	# creating temp dir that contains curent run files
	my $mkdirCmd = "mkdir $jobId\n";
	push (@distructCommands, $mkdirCmd);
	
	# copy files to executing dir in order to run distruct
	my $popTempFileName = "pop";
	my $cpCmd = "cp $clumppPopFileName $jobId/$popTempFileName\n";
	push (@distructCommands, $cpCmd);
	
	my $indTempFileName = "ind";
	$cpCmd = "cp $clumppIndOutputFile $jobId/$indTempFileName\n";
	push (@distructCommands, $cpCmd);

	my $labelsFileName = "labels"; #basename($labelsBelowFigureFile);
	$cpCmd = "cp $labelsBelowFigureFile $jobId/$labelsFileName\n";
	push (@distructCommands, $cpCmd);
	
	my $clusterPermutationAndColorsFileName = "perm";
	$cpCmd = "cp $clusterPermutationAndColorsFile $jobId/$clusterPermutationAndColorsFileName\n";
	push (@distructCommands, $cpCmd);

	my $drawParamsFileName = "drawparams";
	$cpCmd = "cp $newDrawparams $jobId/$drawParamsFileName\n";	
	push (@distructCommands, $cpCmd);
	
	#building distruct cmd
	my $distructExe = "/PAPipe/Programs/CLUMPAK/26_03_2015_CLUMPAK/CLUMPAK/distruct/distruct1.1";
	
	my $distructCmd = "$distructExe -K $numOfPopulations -M $numOfPredefinedPopulations -N $numOfIndividuals -p $jobId/$popTempFileName";
	$distructCmd = $distructCmd." -i $jobId/$indTempFileName -o $jobId/$distructOuptputFileTempName -b $jobId/$labelsFileName";
	$distructCmd = $distructCmd." -c $jobId/$clusterPermutationAndColorsFileName -d $jobId/$drawParamsFileName\n";
	# K - num of clusters $numOfPopulations
	# M - num of populations from pop file $numOfPredefinedPopulations
	# N - num of individulas $numOfIndividuals
	# p - pop Qmat file $clumppPopFileName
	# i - ind Qmat file $clumppIndFile
	# o - output file
	# a, b - labels index file
	# c - cluster permutaion file
	# d - parameters file
	
	
	push (@distructCommands, $distructCmd);

	# moving output file to cluster dir and deleting copied files	
	my $mvCmd = "mv $jobId/$distructOuptputFileTempName $clusterDir/$distructOuptputFile\n";
	push (@distructCommands, $mvCmd);
	my $rmCmd = "rm $jobId/$popTempFileName $jobId/$indTempFileName $jobId/$labelsFileName $jobId/$drawParamsFileName $jobId/$clusterPermutationAndColorsFileName\n"; 
	push (@distructCommands, $rmCmd);
	
	# deletibng temp dir
	my $rmdirCmd = "rmdir $jobId\n";
	push (@distructCommands, $rmdirCmd);
	
	# converting distruct output from postscript to pdf	
	my $pdfOutput = "$clusterDir/$outputFilename.pdf";
	my $ps2pdfCmd = "ps2pdf $clusterDir/$distructOuptputFile $pdfOutput\n";
	push (@distructCommands, $ps2pdfCmd);
	
	
	
	# cropping distruct image to seperate png
	my $imageOutput = "$clusterDir/$outputFilename.png";
	my $gsCmd = "gs -sDEVICE=png16m -r600 -sOutputFile=$imageOutput -dNOPAUSE -dBATCH -c \"<< /PageSize [495 120] /PageOffset [-55 455] >> setpagedevice\" -f $clusterDir/$distructOuptputFile";
	push (@distructCommands, $gsCmd);
	
	
	# adding all commands to file
	my $distructBashFile = "$clusterDir/$outputFilename.sh";
	write_file($distructBashFile, @distructCommands);
	
	return ($distructBashFile, $pdfOutput, $imageOutput, $labelsBelowFigureFile);
}

sub ChangeIndividualWidthParameterInDrawparams
{
	my ($oldDrawparamsFile, $newDrawParamsLocation, $numOfIndividuals) = @_;
	
	my $totalImageWidth = 468; # width in pt
	
	my $newIndividualWidth = $totalImageWidth / $numOfIndividuals;
	
	my @lines = read_file($oldDrawparamsFile);
	my @updatedLines;
	
	foreach my $curLine (@lines)
    {
    	if (index($curLine, "#define INDIVWIDTH") != -1) {
    		push (@updatedLines, "#define INDIVWIDTH $newIndividualWidth	// (d) width of an individual\n");
    	}
    	elsif (index($curLine, "#define PRINT_LABEL_ATOP") != -1) {
    		push (@updatedLines, "#define PRINT_LABEL_ATOP  0  // (B) print labels above figure\n");
    	}
    	else
    	{
    		push (@updatedLines, $curLine);
    	}
    }
	
	write_file($newDrawParamsLocation, @updatedLines);	
}	
	
sub CreateLabelsBelowFigureFile
{
	my ($clumppPopFileName, $labelsFile) = @_;
	
	my @lines = read_file($clumppPopFileName);
	
	my @labelsFileLines;
	
	foreach my $curLine (@lines)
	{
		$curLine =~ s/^\s+//;
		$curLine =~ s/\s+$//;
		my $length = length ($curLine);
		
		if ($length != 0){
			my @columns = split (':', $curLine);
			
			my $curPopId = $columns[0];
			$curPopId =~ s/^\s+//;
			$curPopId =~ s/\s+$//;
			
			my $curLabelLine = "$curPopId $curPopId\n";
			
			push (@labelsFileLines, $curLabelLine);
		}
	}
	
	write_file($labelsFile, @labelsFileLines);
}

sub CheckAndSortUserClustersPermutationsAndColorsFile {
	my ($jobDir, $userClustersPermutationsAndColorsFile, $maxKInFiles) = @_;
	
	my @lines = read_file($userClustersPermutationsAndColorsFile);
	
	my %colorById;
	
	#sorting given file
	foreach my $curLine (@lines)
	{
		$curLine =~ s/^\s+//;
		$curLine =~ s/\s+$//;
		my $length = length ($curLine);
		
		if ($length != 0){
			my @columns = split (/\s+/, $curLine);
			
			$colorById{$columns[0]} = $columns[1];
		}
	}
	
	my @sortedIds = sort {$a<=>$b} keys %colorById;
	my $expectedMaxId = 0+@sortedIds; #length of arr
	my $maxId = $sortedIds[$expectedMaxId-1];
	
	# check if max id is larger than max k
	if ($maxId < $maxKInFiles) {
		print "max id in given clusters and permutation file is $maxId. This value is lower than max K in files. can't use given file. will use default file\n";
		return undef;
	}
	else {
		# check if contains all numbers
		if ($maxId != $expectedMaxId) {
			print "max id in given clusters and permutation file is different than the number of lines in the file. can't use given file. will use default file\n";
			return undef;
		}
		else {
			my @sortedLines;
			foreach my $curId (@sortedIds) {
				my $curColor = $colorById{$curId};
				push (@sortedLines, "$curId $curColor\n");
			}
			
			my ($fileName) = fileparse($userClustersPermutationsAndColorsFile);
			
			my $sortedClustersPermutationsAndColorsFile = "$jobDir/$fileName.Sorted";
			
			write_file($sortedClustersPermutationsAndColorsFile, @sortedLines);
			
			return $sortedClustersPermutationsAndColorsFile;
		}
	}
}




1;
