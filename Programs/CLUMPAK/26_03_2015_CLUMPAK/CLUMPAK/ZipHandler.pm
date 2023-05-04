package ZipHandler;

use File::Path qw(make_path remove_tree);
use Archive::Extract;
use Archive::Zip;
use strict;
use warnings;
use File::Basename;
use CLUMPAK_CONSTS_and_Functions;

#use lib "ExternalModules";
#use File::Path qw(make_path remove_tree);


use vars qw(@ISA @EXPORT);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(ExtractStructureFiles  CreateZipFile);

sub ExtractStructureFiles
{
	my ($archiveFile, $jobId, $jobDir, $outputDirPrefix) = @_;

	my ($name, $dir, $ext) = fileparse($archiveFile, ".zip");
	
	if (!(-e $archiveFile)) {
		die "File $name does not exist.";
	}
	
 	if ($ext ne ".zip")	{
 		die "Archive file type must be a zip.";	
	}

	my $outputDir = "$jobDir/";
	
	if (defined $outputDirPrefix) {
		$outputDir = $outputDir.$outputDirPrefix.".";
	}
	
	$outputDir = $outputDir."input.files";
	
	my $allFilesRef = &ExtractAllFilesRecursively($archiveFile, $outputDir);
	
	print "renaming files than contains whitespaces..\n";
	my @allFiles = &ReplaceSpaceWithUnderscoreInFileNames(@$allFilesRef);
	
	print "Files in archive file:\n", join ("\n", @allFiles), "\n\n";
	
	return \@allFiles;
}

sub ExtractAllFilesRecursively {
	my ($archiveFile, $outputDir) = @_;
	
	my @allFiles;
	
	my $archive = Archive::Extract->new(archive => $archiveFile);
	
	print "Extracting file $archiveFile to $outputDir..\n";
	
	my $isSuccess = $archive -> extract(to=> $outputDir);
	
	if (!$isSuccess){
		my $innerError = $archive->error();
		die "Unable to extract file $archiveFile. $innerError";
	}
	else {
		print "File $archiveFile extracted to $outputDir\n\n";
		
		my $archiveFilesPathsRef = &GetExtractedFilePaths($archive, $outputDir);
				
		foreach my $curFile (@$archiveFilesPathsRef) {
			if (-T $curFile) {
				push (@allFiles, $curFile);
			}
			else {
				my ($name, $dir, $ext) = fileparse($curFile, ".zip");
				
			 	if ($ext ne ".zip")	{
			 		die "Provided files must be zip or text files. file $curFile";	
				}
				else {
					my $innerAllfilesRef = &ExtractAllFilesRecursively($curFile, "$dir$name");
					push (@allFiles, @$innerAllfilesRef);
				}
			}
		}
	}
	
	return \@allFiles;	
}

sub GetExtractedFilePaths {
	my ($archive, $filesDir) = @_;
	
	my $outdir  = $archive -> extract_path;
	
	my $filesRef = $archive -> files;
	
	my @archiveFilesNames;
	
	foreach my $file (@$filesRef) {
		if (!-d "$filesDir/$file") {
			push(@archiveFilesNames, "$filesDir/$file");
		}
	}
	
	return \@archiveFilesNames;
}

sub GetFilesInDirectoryForZipOLD
{
	my ($dir) = @_;
	
	# Opening input files directory
	opendir (DIR, $dir) or die "Couldn't open directory $dir, $!";
	
	my @files;
	
	print "Files in dircetory:\n";
	
	while (my $file = readdir DIR)
	{
		# Allowing dirs, png, zip
		if (-d $file){
			print "a-".$dir."/".$file."\n";
			
			if (($file ne '.') && ($file ne '..')) {
		  		push(@files, $dir."/".$file);
		  		print $dir.$file."\n";
			}
		}
		else {
			my ($name, $tempDir, $ext) = fileparse("$dir$file", ".zip", ".png");
			
			if (($ext eq ".zip") || ($ext eq ".png"))	{
				push(@files, $dir."/".$file);
	  			print $dir."/".$file."\n";
			} 
		}
	}
	closedir DIR;
	
	print "\n";
	
	return @files;
}

sub GetFilesInDirectoryForZip {
    my ($file) = @_;

	my @files;
	
    if (-d $file){
    	opendir (my $dh, $file) or die "Couldn't open directory $file, $!";
    	
    	while (my $innerFile = readdir $dh) {
 			# ofer - don't zip the dir input.files 
			if ( ($innerFile ne '.') && ($innerFile ne '..') && ($innerFile !~ "input.files") ){
        		my $innerFilesRef = &GetFilesInDirectoryForZip("$file/$innerFile");
        		push (@files, @$innerFilesRef);
			}
    	}

   	    close $dh;
    }
    else {
    	my ($name, $tempDir, $ext) = fileparse("$file", (keys %{CLUMPAK_CONSTS_and_Functions::EXCLUDED_FILE_EXTENSIONS()}));
    	
    	if (!defined CLUMPAK_CONSTS_and_Functions::EXCLUDED_FILE_EXTENSIONS->{$ext}){
    		push(@files, $file);
   		}
    }
    
    return \@files;
}

sub ReplaceSpaceWithUnderscoreInFileNames {
	my (@files) = @_;
	
	my @renamedFiles;
	
	foreach my $curFile (@files) {		
		my $newName = $curFile;
		$newName =~ s/\s+/_/g;
		
		if ($newName ne $curFile) {
			print "renaming file $curFile\n";
			rename ($curFile, $newName);	
		}
		push (@renamedFiles, $newName);		
	}
	
	return @renamedFiles;
}


sub CreateZipFile{
	my ($jobId, $jobDir) = @_;
	
	# copying dir to cur dir
	my $cpCmd = "cp -r $jobDir $jobId";
	`$cpCmd`;
	
	
	
	# creating zip
	my $zipFileName = "$jobId.zip";
	my $zipFile = "$jobDir/$zipFileName";
	
	print "Creating summary zip $zipFileName\n";
	
	my $zip = Archive::Zip->new();
	
	my $filesInDirRef = &GetFilesInDirectoryForZip($jobId);
	
	foreach my $curFile (@$filesInDirRef) {
		$zip->addFileOrDirectory($curFile);	
	}
	
	$zip->writeToFileNamed($zipFile);
	
	# removing job dir from cur dir
	my $rmCmd = "rm -r $jobId";
	`$rmCmd`;
	
	print "Finished creating zip\n";
	
	return $zipFileName;
}

1;