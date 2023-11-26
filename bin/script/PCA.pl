#!/usr/bin/perl
#####
#  Example)
#  $./PCA.pl -p [parameter file] -o [out directory]
#
#  Input
#	Parameter file
#
#  Output
#	Visualized PCA scatter plot
#
#  Information
#	Made by Jongin
#	2018. 05. 23
#	Update by NY
#  	2021. 01.
#
#####

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case);
use File::Basename;
use FindBin qw($Bin);
use Cwd 'abs_path';
use Sort::Key::Natural 'natsort';

use Switch;
use  List::MoreUtils 'uniq';

## Parameters
my $param_f;
my $sparam_f;
my $outdir = "./";
my $help = 0;

GetOptions(
	"param|p=s"   => \$param_f,
	"sample|s=s"   => \$sparam_f,
	"outdir|o=s"  => \$outdir,
	"help|h"      => \$help,
);

$outdir = abs_path($outdir);

if ($help == 1 || !$param_f) {
	print STDERR "usage:\n\$./PCA.pl -p PARAM -s SAMPLE_PARAM  -o OUT_DIR \n\n";
	print STDERR "optional arguments:\n";
	print STDERR "\t-h, --help\tshow this help message and exit\n";
	print STDERR "\t-p, --param\tPARAM\n\t\t\t\t<Path> parameter file\n";
	print STDERR "\t-s, --sample\tSAMPLE_PARAM\n\t\t\t\t<Path> sample parameter file\n";
	print STDERR "\t-o, --outdir\tOUT_DIR\n\t\t\t\t<Path> Output directory\n";
	print STDERR "\n================================================\n\n";
	exit;
}

### Configure parameters
my $gcta_cmd = "";
my $visPCA_R = $Bin."/visPCA.R";
my $plink_prefix = "";
my $chr_num = 0;
my $pca_num = 4;
my $pca_title = "";
my $maxPC = 8;
my $obj_variance = 0;
my $Rlib_path = "";


my %spc_name = ();
open(PARAM,$param_f);
while(<PARAM>){
	chomp;
	if($_ =~ /^#/ || $_ eq ""){next;}
	my @p = split(/\s*=\s*/);

	switch ($p[0]) {
		case("GCTA")      { $gcta_cmd = $p[1]; }
		case("visPCA")    { $visPCA_R = abs_path($p[1]); }
		case("PLINK")     { $plink_prefix = abs_path($p[1]); }
		case("autosome-num")   { $chr_num = $p[1]; }
		case("PCA")            { $pca_num = $p[1]; }
		case("PCA_title")      { $pca_title = $p[1]; }
		case("Variance")      { $obj_variance = $p[1]; }
		case("maxPC")      { $maxPC = $p[1]; }
		case("Rlib_path")      { $Rlib_path = $p[1]; }
	}
}
close(PARAM);
my $line = 0;
open(SPARAM, $sparam_f);
while(<SPARAM>){
	chomp;
	if($_ =~ /^#/ || $_ eq ""){next;}
	$_ =~ s/^\s*(.*?)\s*$/$1/;
	$line ++;
	my @p = split(/\s+/,$_);
	$spc_name{"SPC$line"} = $p[2];
}
close(SPARAM);

`mkdir -p $outdir`;
chdir($outdir);
my $output;
my $prefix = basename($plink_prefix);
### Making GRM
`mkdir -p $outdir/GRM`;
print "$gcta_cmd --bfile $plink_prefix --autosome-num $chr_num --autosome --make-grm --out $outdir/GRM/$prefix\n";
$output = `$gcta_cmd --bfile $plink_prefix --autosome-num $chr_num --autosome --make-grm --out $outdir/GRM/$prefix`;
if ($?){
	exit $? >> 8;
}

### PCA
`mkdir -p $outdir/PCA`;
print "$gcta_cmd --grm $outdir/GRM/$prefix --pca $pca_num --out $outdir/PCA/$prefix\n";
$output = `$gcta_cmd --grm $outdir/GRM/$prefix --pca $pca_num --out $outdir/PCA/$prefix`;
if ($?){
	exit $? >> 8;
}
### PCA to R input
open(W,">$outdir/PCs.info");
my $line_num = 0;
my $results_PCnum = 0;
open(F,"$outdir/PCA/$prefix.eigenvec");
while(<F>){
	chomp;
	$line_num++;
	my @arr = split(/\s+/);
	if ($line_num == 1){
		$results_PCnum = @arr-2;
		if ($pca_num <$results_PCnum){
			$results_PCnum = $pca_num;
		}
		print W "SPC";
		for(my $i = 1;$i <= $results_PCnum;$i++){
			print W "\tPC$i";
		}
		print W "\n";
	
	}
	print W $spc_name{"SPC$line_num"};
	for(my $i = 0;$i < $results_PCnum;$i++){
		print W "\t$arr[2+$i]";
	}
	print W "\n";
}
close(F);
close(W);

### Visualizing PCA

print "Rscript $visPCA_R '$pca_title' $results_PCnum $outdir/PCA/$prefix.eigenval  $outdir/PCs.info $obj_variance  $maxPC $outdir $Rlib_path $Bin \n";
$output = `Rscript $visPCA_R "$pca_title" $results_PCnum $outdir/PCA/$prefix.eigenval  $outdir/PCs.info $obj_variance   $maxPC $outdir $Rlib_path $Bin`;
if ($?){
	exit $? >> 8;
}
