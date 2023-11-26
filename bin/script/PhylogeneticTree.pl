#!/usr/bin/perl

#####
#	Command
#	#./PhylogeneticTree.pl -p [parameter file] -o [out directory]
#
#	Input
#	Merged hapmap file
#
#	Output
#	Newick tree
#
#	Information
#	Made by Jongin
#	2018.08.27
#   Update by NY
#   2021. 01.
#####

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case);
use File::Basename;
use FindBin qw($Bin);
use Cwd 'abs_path';
use Switch;


## Parameters
my $param_f;
my $outdir = "./",
my $help = 0;

`export LD_LiBRARY_PATH=\$LD_LIBRARY_PATH:/mss_dc/project/ny/pap/test/programs/pytnon2/Python-2.7.2/`;
GetOptions (
	"param|p=s"	=>	\$param_f,
	"outdir|o=s"	=>	\$outdir,
	"help|h"		=> 	\$help,
);

$outdir = abs_path($outdir);
`mkdir -p $outdir`;

if ($help == 1 || !$param_f) {
	print STDERR "usage:\n\$./PhylogeneticTree.pl -H HAPMAP_FILE -s SAMPLE_NUMBER -o OUR_DIR\n\n";
	print STDERR "optional arguments:\n";
	print STDERR "\t-h, --help\tshow this help message and exit\n";
	print STDERR "\t-p, --param\tPARAM\n\t\t\t\t<Path> parameter file\n";
	print STDERR "\t-o, --outdir\tOUT_DIR\n\t\t\t\t<Path> Output directory\n";
	print STDERR "\n================================================\n\n";
	exit;
}

### Configure parameters
my $snphylo_cmd = "";
my $dendogram = $Bin."/visTREE.R";
my $hapmapfilt = $Bin."/HAPMAP_FILT.pl";
my $hapmap_f = "";
my $sampleNum = 0;
my $l = 0.7;
my $m = 0.0;
my $M = 0.02;

open(PARAM, $param_f);
while(<PARAM>){
	chomp;
	if($_ =~ /^#/ || $_ eq ""){next;}
	my @p = split(/\s*=\s*/,$_);
	switch ($p[0]) {
		case("Snphylo"){$snphylo_cmd = abs_path($p[1]);}
		case("hapmap"){if ($p[1] =~ /.+\.hapmap$/){$hapmap_f = abs_path($p[1]);}}
		case("sampleNum"){$sampleNum = $p[1];}
		case("l"){$l = $p[1];}
		case("m"){$m = $p[1];}
		case("M"){$M = $p[1];}
	}
}
close(PARAM);


$hapmap_f = abs_path($hapmap_f);
chdir($outdir);
print STDERR "$hapmapfilt $hapmap_f > $outdir/filtered.hapmap\n";
print STDERR "$snphylo_cmd -H $hapmap_f -P snphylo -A -b -l $l -m $m -M $M  >& $outdir/snphylo.log\n";
print STDERR "Rscript $dendogram $outdir/snphylo.ml.tree $sampleNum ./\n";

my $output = `$hapmapfilt $hapmap_f > $outdir/filtered.hapmap`;
if($?) {
    exit $? >> 8;
}

my $orig_hapmap_f = $hapmap_f;
$hapmap_f = abs_path("$outdir/filtered.hapmap");

$output = `$snphylo_cmd -t 20 -H $hapmap_f -P snphylo -A -b -l $l -m $m -M $M `;
if($?) {
	exit $? >> 8;
}
## exchange tree node to original name 
#name match file exist -> input hapmap path 
#name match file not exists -> input hapmap path 
my ($name, $path, $suffix) = fileparse($orig_hapmap_f);
my $f_namematch = $path."/hapmap.namematch.txt";
if(-e $f_namematch){
	my $input_file = "$outdir/snphylo.ml.tree";
	my $tree_str = "";
	open(F,"$input_file");
	while(<F>){
	    chomp;
		$tree_str .= $_;
	}
	close(F);
	my %hs_namematch =  ();
	open(F,"$f_namematch");
	while(<F>){
		chomp;
		my ($v1, $v2) = split(/\t/,$_);
		$hs_namematch{$v1} = $v2;
	}
	close(F);

	foreach my $this (keys %hs_namematch){
		my $change = $hs_namematch{$this};
		$tree_str =~ s/$this/$change/;
	}
	`mv $outdir/snphylo.ml.tree $outdir/snphylo.ml.adjustedID.tree`;
	open(FW,">$outdir/snphylo.ml.tree");
	print FW $tree_str;
	close(FW);
}

#$output = `Rscript $dendogram $outdir/snphylo.ml.tree  $sampleNum  $outdir`;

#if($?) {
#	exit $? >> 8;
#}
