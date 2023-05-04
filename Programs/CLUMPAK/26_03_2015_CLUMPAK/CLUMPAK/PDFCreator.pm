package PDFCreator;

use strict;
use warnings;
use PDF::API2;
use PDF::Table;
use File::Basename;

use vars qw(@ISA @EXPORT);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(CreateCLUMPAKPDF CreateDistructForManyKsPDF CreateCompareDifferentProgramsPDF);

sub CreateCLUMPAKPDF
{
	my ($jobId, $jobDir, $largeClustersDataArrRef, $minorClustersDataByKeyHashRef) = @_;
	
	print "Getting data hashes\n";
	
	my ($majorHashRef, $minorHashOfHashesRef, $divisionByKHashRef, $imagesCounter, $numOfKs) = GetCLUMPAKDataHashes($largeClustersDataArrRef, $minorClustersDataByKeyHashRef);
	my %majorHash = %$majorHashRef;
	my %minorHashOfHashes = %$minorHashOfHashesRef;
	my %divisionByKHash = %$divisionByKHashRef;
	
	#creating new pdf file
	my $pdfName = "job_".$jobId."_pipeline_summary.pdf";
	my $pdfFile = "$jobDir/$pdfName";
	my $pdf = PDF::API2->new(-file => $pdfFile);
	
	print "creating pdf $pdfName..\n";
	
	# creating first page
	my $firstPage = $pdf->page();
	
	#setting page size 595x842
	my ($pageWidth, $pageHeight) = CalculatePageSize($imagesCounter, $numOfKs);
	$firstPage->mediabox ($pageWidth, $pageHeight);
	
	# setting bgcolor
#	my $background = $firstPage->gfx;
#	$background->fillcolor('#E3CFAC');
#	$background->rect( 0,0, $pageWidth, $pageHeight );
#	$background->fill;
	
	# Add a built-in font to the PDF
	my $helveticaBold = $pdf->corefont('Helvetica-Bold');
	my $helvetica = $pdf->corefont('Helvetica');
	
	# Add title to the page
	
	print "Adding title..\n";
	my $titleHeight = $pageHeight-50;
	
	my $jobName = $firstPage->text();
	$jobName->font($helvetica, 20);
	$jobName->fillcolor('black');
	$jobName->translate(40, $titleHeight);
	$jobName->text("CLUMPAK main pipeline - Job $jobId summary");
	
	
	# major clusters part
	my $majorTitleHeight = $titleHeight - 30;
	
	print "Adding major images..\n";
	
	my $majorTitle = $firstPage->text();
	$majorTitle->font($helvetica, 16);
	$majorTitle->translate(40, $majorTitleHeight);
	$majorTitle->text("Major modes for the uploaded data:");
	
	my $lastImageHeight = $majorTitleHeight - 10;
	
	foreach my $curK (sort { $a <=> $b } keys %majorHash) {
		# adding image title
		my $curImageTitleHeight = $lastImageHeight - 14;
	
		print "cur major image location: ".$majorHash{$curK}."\n";
	
		my $curImageTitle = $firstPage->text();
		$curImageTitle->font($helvetica, 12);
		$curImageTitle->translate(50, $curImageTitleHeight);
		$curImageTitle->text("K=$curK");
		
		# adding image
		my $curImageHeight = $curImageTitleHeight - 122;
		my $gfx = $firstPage->gfx;
		my $image = $pdf->image_png($majorHash{$curK});
	
		# add the image to the graphic object - x, y, width, height  
		$gfx->image($image, 50, $curImageHeight, 495, 120);
	
		$lastImageHeight = $curImageHeight;
	}
	
	# minor clusters part
	print "Adding minor images..\n";
	
	my $minorTitleHeight = $lastImageHeight - 30;
	
	my $minorTitle = $firstPage->text();
	$minorTitle->font($helvetica, 16);
	$minorTitle->translate(40, $minorTitleHeight);
	$minorTitle->text("Minor modes for the uploaded data:");
	
	$lastImageHeight = $minorTitleHeight - 10;
	foreach my $curK (sort { $a <=> $b }  keys %minorHashOfHashes) {
		my $minorArrRef = $minorHashOfHashes{$curK};
		my @minorArr = @$minorArrRef; 
		
		foreach my $curMinorHashRef (@minorArr) {
			my %minorHash = %$curMinorHashRef ; 
			my $minorKey = (keys %minorHash)[0];

			# adding image title
			my $curImageTitleHeight = $lastImageHeight - 14;
		
			my $curImageTitle = $firstPage->text();
			$curImageTitle->font($helvetica, 12);
			$curImageTitle->translate(50, $curImageTitleHeight);
			$curImageTitle->text("K=$curK    $minorKey");
			
			print "cur minor image location: ".$minorHash{$minorKey}."\n";
			
			# adding image
			my $curImageHeight = $curImageTitleHeight - 122;
			my $gfx = $firstPage->gfx;
			my $image = $pdf->image_png($minorHash{$minorKey});
		
			# add the image to the graphic object - x, y, width, height  
			$gfx->image($image, 50, $curImageHeight, 495, 120);
		
			$lastImageHeight = $curImageHeight;
		}
	}
	
	# division of runs
	print "Adding division by K data..\n";
	
	my $divisionTitleHeight = $lastImageHeight - 30;
	
	my $divisionTitle = $firstPage->text();
	$divisionTitle->font($helvetica, 16);
	$divisionTitle->translate(40, $divisionTitleHeight);
	$divisionTitle->text("Division of runs by mode:");
	
	my $lastKHeight = $divisionTitleHeight - 10;
	foreach my $curK (sort { $a <=> $b } keys %divisionByKHash) {
		my $curKDivisionHeight = $lastKHeight - 14;
	
		print "cur division by K data: ".$divisionByKHash{$curK}."\n";
	
		my $curKDivisionTitle = $firstPage->text();
		$curKDivisionTitle->font($helvetica, 12);
		$curKDivisionTitle->translate(50, $curKDivisionHeight);
		$curKDivisionTitle->text("K=$curK");
		
		my $curKDivision = $firstPage->text();
		$curKDivision->font($helvetica, 12);
		$curKDivision->translate(90, $curKDivisionHeight);
		$curKDivision->text($divisionByKHash{$curK});
		
		$lastKHeight = $curKDivisionHeight;
	}
	
	# Save the PDF
	$pdf->save();
	
	return $pdfName;
}

sub CreateDistructForManyKsPDF
{
	my ($jobId, $jobDir, $dataForDistructForeachKArrRef) = @_;
	
	print "Getting data hashes\n";
	
#	my ($imageByKHashRef) = &GetDistructForManyKsDataHashes($dataForDistructForeachKArrRef);
#	my %imageByK = %$imageByKHashRef;
	
	#creating new pdf file
	my $pdfName = "job_".$jobId."_distruct_summary.pdf";
	my $pdfFile = "$jobDir/$pdfName";
	my $pdf = PDF::API2->new(-file => $pdfFile);
	
	print "creating pdf $pdfName..\n";
	
	# creating first page
	my $firstPage = $pdf->page();
	
	#setting page size 595x842
	my $imagesCounter = 0+(@$dataForDistructForeachKArrRef);
	my ($pageWidth, $pageHeight) = CalculatePageSize($imagesCounter, 0);
	$firstPage->mediabox ($pageWidth, $pageHeight);
	
	# Add a built-in font to the PDF
	my $helveticaBold = $pdf->corefont('Helvetica-Bold');
	my $helvetica = $pdf->corefont('Helvetica');
	
	# Add title to the page
	
	print "Adding title..\n";
	my $titleHeight = $pageHeight-50;
	
	my $jobName = $firstPage->text();
	$jobName->font($helvetica, 20);
	$jobName->fillcolor('black');
	$jobName->translate(40, $titleHeight);
	$jobName->text("CLUMPAK Distruct for many K's - Job $jobId summary");
	
	# Adding images
	my $imagesTitleHeight = $titleHeight - 30;
	
	print "Adding images..\n";
	
	my $imagesTitle = $firstPage->text();
	$imagesTitle->font($helvetica, 16);
	$imagesTitle->translate(40, $imagesTitleHeight);
	$imagesTitle->text("Distruct output images:");
	
	my $lastImageHeight = $imagesTitleHeight - 10;
	
	foreach my $dataForDistructRef (@$dataForDistructForeachKArrRef) {
		my %dataForDistruct = %$dataForDistructRef;
		my $curK = $dataForDistruct{'kSize'};
		my $imagePath = $dataForDistruct{'distructImage'};
		my $imageName = $dataForDistruct{'imageName'};
	
		my $curImageTitleHeight = $lastImageHeight - 14;
		print "Adding image for k=$curK\n";
		print "cur major image location: $imagePath\n";
	
		my $curImageTitle = $firstPage->text();
		$curImageTitle->font($helvetica, 12);
		$curImageTitle->translate(50, $curImageTitleHeight);
		$curImageTitle->text("K=$curK");
		
		my $curImageName = $firstPage->text();
		$curImageName->font($helvetica, 12);
		$curImageName->translate(100, $curImageTitleHeight);
		
		# replacing underscore with hyphen
		$imageName =~ s/\_/-/g;		
		$curImageName->text($imageName);
		print "Cur Image: $imageName\n";
		
		# adding image
		my $curImageHeight = $curImageTitleHeight - 122;
		my $gfx = $firstPage->gfx;
		my $image = $pdf->image_png($imagePath);
	
		# add the image to the graphic object - x, y, width, height  
		$gfx->image($image, 50, $curImageHeight, 495, 120);
	
		$lastImageHeight = $curImageHeight;
	}
	
	# Save the PDF
	$pdf->save();
	
	return $pdfName;
}

sub CalculatePageSize {
	my ($numberOfImages, $numberOfKs) = @_;
	
	print "Calculating page size.\nNumber of images: $numberOfImages\nNumber Of K's: $numberOfKs\n";
	
	my $width = 595;
	my $height = 200 + $numberOfImages * 136 + $numberOfKs * 15; 
	
	print "Calculated height: $height\n";
	
	return ($width, $height);
}


sub GetCLUMPAKDataHashes {
	my ($largeClustersDataArrRef, $minorClustersDataByKeyHashRef) = @_;
	my @largeClustersData = @$largeClustersDataArrRef;
	my %minorClustersDataByKey = %$minorClustersDataByKeyHashRef;
	
	my %majorHash;
	my %minorHashOfHashes;
	my %divisionByKHash;
	
	my $imagesCounter = 0;
	
	foreach my $largeClusterHashRef (@largeClustersData) {
		my %largeClusterHash = %$largeClusterHashRef;
		
		# major cluster data
		my $curK             = $largeClusterHash{'kSize'};
		my $key              = $largeClusterHash{'key'};
		my $majorImage      = $largeClusterHash{'distructImage'};
		my $majorClusterText = $largeClusterHash{'clusterText'};
		
		$majorHash{$curK} = $majorImage;
		$imagesCounter++;
		$divisionByKHash{$curK} = $majorClusterText;
		
		#minor clusters
		if ( exists $minorClustersDataByKey{$key} ) {
			my $minorClustersDataRef = $minorClustersDataByKey{$key};
			my @minorClustersData    = @$minorClustersDataRef;
			
			my @curKMinorArr;
			
			foreach my $minorClusterDataRef (@minorClustersData) {
				my %minorClusterData = %$minorClusterDataRef;

				my $minorClusterId  = $minorClusterData{'minorClusterId'};
				my $minorImage      = $minorClusterData{'distructImage'};
				my $minorClusterText = $minorClusterData{'clusterText'};
				
				my %curKMinorHash;
				$curKMinorHash{$minorClusterId} = $minorImage;
				$imagesCounter++;
				
				push (@curKMinorArr, \%curKMinorHash);
				
				my $curDivisionByKText = $divisionByKHash{$curK};
				$curDivisionByKText = $curDivisionByKText.", $minorClusterText";
				$divisionByKHash{$curK} = $curDivisionByKText;
			}
			
			$minorHashOfHashes{$curK} = \@curKMinorArr;
		}
	}
	
	my $numOfKs = 0+(keys %majorHash);
	
	
	return (\%majorHash, \%minorHashOfHashes, \%divisionByKHash, $imagesCounter, $numOfKs);
}

sub GetDistructForManyKsDataHashes {
	my ($dataForDistructForeachKArrRef) = @_;
	my @dataForDistructForeachK = @$dataForDistructForeachKArrRef;
	
	my %imageByK;
	foreach my $curKHashRef (@dataForDistructForeachK) {
		my %curKHash = %$curKHashRef;
		
		my $curK = $curKHash{"kSize"};
		my $curKImage = $curKHash{"distructImage"};
		
		$imageByK{$curK} = $curKImage;
	} 
		
}

sub CreateCompareDifferentProgramsPDF
{
	my ($jobId, $jobDir, $firstProgramLargeClusterDataRef, $firstProgramMinorClustersDataRef, 
			$secondProgramLargeClusterDataRef, $secondProgramMinorClustersDataRef, $pairMatrixLines) = @_;
	
	my %firstProgramLargeClusterHash    = %$firstProgramLargeClusterDataRef;
	my @firstProgramMinorClustersData = @$firstProgramMinorClustersDataRef;
	my %secondProgramLargeClusterHash    = %$secondProgramLargeClusterDataRef;
	my @secondProgramMinorClustersData = @$secondProgramMinorClustersDataRef;
	
	my $imagesCounter = 3 + (0+@firstProgramMinorClustersData) + (0+@secondProgramMinorClustersData);
	
	#creating new pdf file
	my $pdfName = "job_".$jobId."_compare_summary.pdf";
	my $pdfFile = "$jobDir/$pdfName";
	my $pdf = PDF::API2->new(-file => $pdfFile);
	
	print "creating pdf $pdfName..\n";
	
	# creating first page
	my $firstPage = $pdf->page();
	
	#setting page size 595x842
	my ($pageWidth, $pageHeight) = CalculatePageSize($imagesCounter, 2 * $imagesCounter);
	$firstPage->mediabox ($pageWidth, $pageHeight);
	
	# Add a built-in font to the PDF
	my $helveticaBold = $pdf->corefont('Helvetica-Bold');
	my $helvetica = $pdf->corefont('Helvetica');
	
	# Add title to the page
	
	print "Adding title..\n";
	my $titleHeight = $pageHeight-50;
	
	my $jobName = $firstPage->text();
	$jobName->font($helvetica, 20);
	$jobName->fillcolor('black');
	$jobName->translate(40, $titleHeight);
	$jobName->text("CLUMPAK Compare Different Programs");
	
	$titleHeight = $titleHeight  - 25;
	
	$jobName = $firstPage->text();
	$jobName->font($helvetica, 20);
	$jobName->fillcolor('black');
	$jobName->translate(40, $titleHeight);
	$jobName->text("Job $jobId summary");
	
	# major clusters part
	my $majorTitleHeight = $titleHeight - 30;
	
	print "Adding major images..\n";
	
	my $majorTitle = $firstPage->text();
	$majorTitle->font($helvetica, 16);
	$majorTitle->translate(40, $majorTitleHeight);
	$majorTitle->text("Major modes for the uploaded data:");
	
	my $lastImageHeight = $majorTitleHeight - 10;
	
	# adding first file major cluster
	# adding image title
	my $curImageTitleHeight = $lastImageHeight - 14;

	print "first file major image location: ".$firstProgramLargeClusterHash{'distructImage'}."\n";

	my $curImageTitle = $firstPage->text();
	$curImageTitle->font($helvetica, 12);
	$curImageTitle->translate(50, $curImageTitleHeight);
	$curImageTitle->text($firstProgramLargeClusterHash{'clusterName'});
	
	# adding image
	my $curImageHeight = $curImageTitleHeight - 122;
	my $gfx = $firstPage->gfx;
	my $image = $pdf->image_png($firstProgramLargeClusterHash{'distructImage'});

	# add the image to the graphic object - x, y, width, height  
	$gfx->image($image, 50, $curImageHeight, 495, 120);

	$lastImageHeight = $curImageHeight;
	
	# adding second file major cluster
	# adding image title
	$curImageTitleHeight = $lastImageHeight - 14;

	print "second file major image location: ".$secondProgramLargeClusterHash{'distructImage'}."\n";

	$curImageTitle = $firstPage->text();
	$curImageTitle->font($helvetica, 12);
	$curImageTitle->translate(50, $curImageTitleHeight);
	$curImageTitle->text($secondProgramLargeClusterHash{'clusterName'});
	
	# adding image
	$curImageHeight = $curImageTitleHeight - 122;
	$gfx = $firstPage->gfx;
	$image = $pdf->image_png($secondProgramLargeClusterHash{'distructImage'});

	# add the image to the graphic object - x, y, width, height  
	$gfx->image($image, 50, $curImageHeight, 495, 120);

	$lastImageHeight = $curImageHeight;
	
	
	# minor clusters part
	print "Adding minor images..\n";
	
	my $minorTitleHeight = $lastImageHeight - 30;
	
	my $minorTitle = $firstPage->text();
	$minorTitle->font($helvetica, 16);
	$minorTitle->translate(40, $minorTitleHeight);
	$minorTitle->text("Minor modes for the uploaded data:");
	
	$lastImageHeight = $minorTitleHeight - 10;
	
	# first file minor part
	foreach my $minorClusterHashRef (@firstProgramMinorClustersData) {
		my %minorHash = %$minorClusterHashRef ; 
		my $minorKey = (keys %minorHash)[0];

		# adding image title
		my $curImageTitleHeight = $lastImageHeight - 14;
	
		my $curImageTitle = $firstPage->text();
		$curImageTitle->font($helvetica, 12);
		$curImageTitle->translate(50, $curImageTitleHeight);
		$curImageTitle->text($minorHash{'clusterName'});
		
		print "cur minor image location: ".$minorHash{'distructImage'}."\n";
		
		# adding image
		my $curImageHeight = $curImageTitleHeight - 122;
		my $gfx = $firstPage->gfx;
		my $image = $pdf->image_png($minorHash{'distructImage'});
	
		# add the image to the graphic object - x, y, width, height  
		$gfx->image($image, 50, $curImageHeight, 495, 120);
	
		$lastImageHeight = $curImageHeight;
	}
	
	# second file minor part
	foreach my $minorClusterHashRef (@secondProgramMinorClustersData) {
		my %minorHash = %$minorClusterHashRef ; 
		my $minorKey = (keys %minorHash)[0];

		# adding image title
		my $curImageTitleHeight = $lastImageHeight - 14;
	
		my $curImageTitle = $firstPage->text();
		$curImageTitle->font($helvetica, 12);
		$curImageTitle->translate(50, $curImageTitleHeight);
		$curImageTitle->text($minorHash{'clusterName'});
		
		print "cur minor image location: ".$minorHash{'distructImage'}."\n";
		
		# adding image
		my $curImageHeight = $curImageTitleHeight - 122;
		my $gfx = $firstPage->gfx;
		my $image = $pdf->image_png($minorHash{'distructImage'});
	
		# add the image to the graphic object - x, y, width, height  
		$gfx->image($image, 50, $curImageHeight, 495, 120);
	
		$lastImageHeight = $curImageHeight;
	}
	
	# mereged modes pair Matrix
	print "Adding merged modes pair matrix..\n";
	
	my $pairMatrixTitleHeight = $lastImageHeight - 30;
	
	my $pairMatrixTitle = $firstPage->text();
	$pairMatrixTitle->font($helvetica, 16);
	$pairMatrixTitle->translate(40, $pairMatrixTitleHeight);
	$pairMatrixTitle->text(" Merged modes pair matrix:");
	
	my $lastLineHeight = $pairMatrixTitleHeight;
	foreach my $curLine (split("\n", $pairMatrixLines)) {
		my $curLineHeight = $lastLineHeight - 14;
	
		print "cur line: $curLine\n";
	
		my $curLineTitle = $firstPage->text();
		$curLineTitle->font($helvetica, 12);
		$curLineTitle->translate(50, $curLineHeight);
		$curLineTitle->text($curLine);
		
		$lastLineHeight = $curLineHeight;
	}
	
	# Save the PDF
	$pdf->save();
	
	return $pdfName;
}

1;