#!/usr/bin/perl

#####
#
#  Parameter 	
#  $./Fst.pl -p [parameter file] -o [out directory] -n [outfile_name]
#
#  Input
#	Parameter file
#
#  Output
#	fst out file
#
#  Information
#	Made by	Youngbeen and Jongin
#	2018.05.25
#   Update by NY
#   2021. 01.
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
	print STDERR "usage:\n\$./FST.pl -p PARAM -n NAME -o OUT_DIR \n\n";
	print STDERR "optional arguments:\n";
	print STDERR "\t-h, --help\tshow this help message and exit\n";
	print STDERR "\t-p, --param\tPARAM\n\t\t\t\t<Path> parameter file\n";
	print STDERR "\t-s, --sample\tSAMPLE_PARAM\n\t\t\t<Path> sample parameter file\n";
	print STDERR "\t-o, --outdir\tOUT_DIR\n\t\t\t\t<Path> Output directory\n";
	print STDERR "\n================================================\n\n";
	exit;
}

### Configure parameters
my $filename = "Fst_result";
$sparam_f = abs_path($sparam_f);
my $qqmanS = $Bin."/visMP.R";
my $vcftools = "vcftools";
my $inVCF = "";
my $windowS = 100000;
my $stepS = 0;
my $visType = "pdf";
my $plotW = "30";
my $plotH = "10";
my $reference_chromosome_cnt = 0;
my @ar_targetGroups = ();
my $userTargetgroups = "";

my @color_arr = ();
my $color = "";
my $pop_check = 0;
my $genomewideline = 5;
my $Rlib_path = "";
my $innate_colors = "\\\#996600,\\\#666600,\\\#99991e,\\\#cc0000,\\\#ff0000,\\\#ff00cc,\\\#ffcccc,\\\#ff9900,\\\#ffcc00,\\\#ffff00,\\\#ccff00,\\\#00ff00,\\\#358000,\\\#0000cc,\\\#6699ff,\\\#99ccff,\\\#00ffff,\\\#ccffff,\\\#9900cc,\\\#cc33ff,\\\#cc99ff,\\\#666666,\\\#999999,\\\#cccccc";

$outdir = abs_path($outdir);
if ( $outdir ne "./" ) {
	`mkdir -p $outdir`;
}
open(PARAM,$param_f);
while(<PARAM>){
	chomp;
	if($_ =~ /^#/ || $_ eq ""){next;}
	my @p = split(/\s*=\s*/);
	if($p[0] =~ /color\d+/ ) {
		push(@color_arr, $p[1]);
		next;
	}
	switch ($p[0]) {
		#case("qqmanS")		{ $qqmanS = abs_path($p[1]); }
		case("VCFTOOLS")		{ $vcftools = $p[1]; }
		case("vcf")		{ $inVCF = abs_path($p[1]); }
		case("reference_chromosome_cnt")		{ $reference_chromosome_cnt = $p[1]; }
		case("window-size")	{ $windowS = $p[1]; }
		case("window-step")	{ $stepS = $p[1]; }
		case("plot-width")	{ $plotW = $p[1]; }
		case("plot-high")	{ $plotH = $p[1]; }
		case("genomewideline")	{ $genomewideline = $p[1]; } 
		case("TargetGroup")	{ push(@ar_targetGroups,$p[1]); } 
		case("TargetComb")	{ $userTargetgroups = $p[1]; } 
		case("Rlib_path")	{ $Rlib_path = $p[1]; } 
	}
}
close(PARAM);

# color
if ( scalar @color_arr == 0 ) {
	$color = "\\\#996600,\\\#666600,\\\#99991e,\\\#cc0000,\\\#ff0000,\\\#ff00cc,\\\#ffcccc,\\\#ff9900,\\\#ffcc00,\\\#ffff00,\\\#ccff00,\\\#00ff00,\\\#358000,\\\#0000cc,\\\#6699ff,\\\#99ccff,\\\#00ffff,\\\#ccffff,\\\#9900cc,\\\#cc33ff,\\\#cc99ff,\\\#666666,\\\#999999,\\\#cccccc";
	if ($reference_chromosome_cnt > 24){
		$color .= ",$innate_colors,$innate_colors";
	}
} else{
	for ( my $i = 0; $i <= $#color_arr ; $i++ ) {
		if ( $i == $#color_arr ) { 
			$color .= "$color_arr[$i]";
		} else {
			$color .= "$color_arr[$i],";
		}
	}
	if( !(scalar @color_arr >= $reference_chromosome_cnt) ){
		$color .= "\\\#996600,\\\#666600,\\\#99991e,\\\#cc0000,\\\#ff0000,\\\#ff00cc,\\\#ffcccc,\\\#ff9900,\\\#ffcc00,\\\#ffff00,\\\#ccff00,\\\#00ff00,\\\#358000,\\\#0000cc,\\\#6699ff,\\\#99ccff,\\\#00ffff,\\\#ccffff,\\\#9900cc,\\\#cc33ff,\\\#cc99ff,\\\#666666,\\\#999999,\\\#cccccc";
	}
}

### Running vcftools  
if (!@ar_targetGroups){
#every populations are become a target once 
	print "no specific targets\n";
	open(SPARAM,"$sparam_f");
	my %hs_used = ();
	while(<SPARAM>){
		$_ =~ s/^\s+|\s+$//g;
		if($_ =~ /^#/ || $_ eq ""){next;}
		my @p = split(/\s+/,$_);
		if (!exists ($hs_used{$p[2]})){
			$hs_used{$p[2]} = $p[2];
			push(@ar_targetGroups,$p[2]);
		}
	}
	close(SPARAM);
}
## single target 
for (my $round = 0 ; $round <= $#ar_targetGroups ; $round ++){
	my $cur_target = $ar_targetGroups[$round];
    my $newoutdir = abs_path("$outdir/$cur_target\_VS_rest_all_populations");
	`mkdir -p $newoutdir`;
	chdir ("$newoutdir" or die "cannot change: $!\n");
	my @arr_ind = ();
	#print STDERR "mkdir $newoutdir\n";
	print "this round : $round, $ar_targetGroups[$round]\n";
	my %hs_target = ();
	my @ar_targets = split(/\s+,\s+/,$ar_targetGroups[$round]);
	foreach my $tarspc (@ar_targets){
		$hs_target{$tarspc} = 1;
	}
	open(SPARAM,"$sparam_f")or die "File '$sparam_f' can't be opened";
	while(<SPARAM>){
		$_ =~ s/^\s+|\s+$//g;
		if($_ =~ /^#/ || $_ eq ""){next;}
		my @p = split(/\s+/,$_);
		if (exists($hs_target{$p[2]})){
			open(W,">>$newoutdir/$filename.pop1");
			print W $p[2]."_".$p[0]."\n";
			close(W);
		}else{
			open(W,">>$newoutdir/$filename.pop2");
			print W $p[2]."_".$p[0]."\n";
			close(W);
		}
	}
	close(SPARAM);
	
	push(@arr_ind, "$newoutdir/$filename.pop1");
	push(@arr_ind, "$newoutdir/$filename.pop2");

	### fst 
	my $cmd = "$vcftools ";
	$cmd .= "--gzvcf $inVCF ";
	$cmd .= "--fst-window-size $windowS ";
	$cmd .= "--fst-window-step $stepS ";
	foreach my $ind (@arr_ind) {
		$cmd .= "--weir-fst-pop $ind ";
	}
	$cmd .= "--out $newoutdir/$filename";
	print STDERR "$cmd\n";
	my $output = `$cmd`;
	if ($?){
		exit $? >> 8;
	}
	### manhattan plot
	open(O, "$newoutdir/$filename.windowed.weir.fst");
	my %hash_temp = ();
	while(<O>) {
		chomp;
		next if /^CHROM/;
		my ($chr) = split(/\t/,$_);
		if ($chr =~ /chr(\d+)/) {
			if(!exists($hash_temp{$1})) {
				$hash_temp{$1} = 0;
			}
		}
	}
	close(O);
	my @arr_chr = sort {$a <=> $b} keys %hash_temp;
	my $maxChr = scalar(@arr_chr);
	my $chrX = $maxChr + 1;
	my $chrY = $maxChr + 2;
	my $chrMT = $maxChr + 3;
	my $modF = "$filename.mod.windowed.weir.fst";

	open(O, "$newoutdir/$filename.windowed.weir.fst");
	open(W, ">$newoutdir/$modF");
	my $header = <O>; chomp($header);
	print W "$header\n";
	while(<O>) {
		chomp;
		print W "$_\n" if /^#/;
		my @arr_t = split(/\t/,$_);
		if ($arr_t[0] =~ /X/i) {
			$arr_t[0] = $chrX;
			print W join("\t", @arr_t)."\n";
		} elsif ( $arr_t[0] =~ /Y/i) {
			$arr_t[0] = $chrY;
			print W join("\t",@arr_t)."\n";
		} elsif ( $arr_t[0] =~ /MT/i) {
			$arr_t[0] = $chrMT;
			print W join("\t",@arr_t)."\n";
		} elsif ( $arr_t[0] =~ /chr/i) {
			my $cutchr = substr($_,3);
			print W "$cutchr\n";
		}else{
			print W "$_\n";
		}
	}
	close(W);
	close(O);
	my $inF = "$newoutdir/$modF";
	my $cmd_mp = "Rscript $qqmanS ";
	$cmd_mp .= "$inF ";
	$cmd_mp .= "$newoutdir/$filename ";
	$cmd_mp .= "$visType ";
	$cmd_mp .= "$plotW ";
	$cmd_mp .= "$plotH ";
	$cmd_mp .= "$genomewideline ";
	$cmd_mp .= "$color";
	print STDERR "$cmd_mp &> $newoutdir/$filename.VisMP.log\n";
	$output = `$cmd_mp $Rlib_path &> $newoutdir/$filename.VisMP.log`;
	if ($?){
		exit $? >> 8;
	}
	print STDERR "$cmd_mp &> $newoutdir/$filename.VisMP.log\n";
}

## 1 vs 1  
for (my $round = 0 ; $round <= $#ar_targetGroups ; $round ++){
	for (my $roundv2 = $round+1 ; $roundv2 <= $#ar_targetGroups ; $roundv2 ++){
		my $pairname = $ar_targetGroups[$round]."_VS_".$ar_targetGroups[$roundv2];
		my $newoutdir = abs_path("$outdir/$pairname");
		`mkdir -p $newoutdir`;
		chdir ("$newoutdir" or die "cannot change: $!\n");
		my @arr_ind = ();
		print "this round : $pairname\n";
		my %hs_tar = ();
		$hs_tar{$ar_targetGroups[$roundv2]} = 1;
		my %hs_ref = ();
		$hs_ref{$ar_targetGroups[$round]} = 1;
		open(SPARAM,"$sparam_f")or die "File '$sparam_f' can't be opened";
		while(<SPARAM>){
			$_ =~ s/^\s+|\s+$//g;
			if($_ =~ /^#/ || $_ eq ""){next;}
			my @p = split(/\s+/,$_);
			print "@p\n";
			if (exists($hs_ref{$p[2]})){
				open(W,">>$newoutdir/$ar_targetGroups[$round].pop1");
				print W $p[2]."_".$p[0]."\n";
				close(W);
			}elsif (exists($hs_tar{$p[2]})){
				open(W,">>$newoutdir/$ar_targetGroups[$roundv2].pop2");
				print W $p[2]."_".$p[0]."\n";
				close(W);
			}
		}
		close(SPARAM);
		push(@arr_ind, "$newoutdir/$ar_targetGroups[$round].pop1");
		push(@arr_ind, "$newoutdir/$ar_targetGroups[$roundv2].pop2");

		### fst 
		my $cmd = "$vcftools ";
		$cmd .= "--gzvcf $inVCF ";
		$cmd .= "--fst-window-size $windowS ";
		$cmd .= "--fst-window-step $stepS ";
		foreach my $ind (@arr_ind) {
			$cmd .= "--weir-fst-pop $ind ";
		}
		$cmd .= "--out $newoutdir/$pairname";
		print STDERR "$cmd\n";
		my $output = `$cmd`;
		if ($?){
			exit $? >> 8;
		}
		my $filename = $pairname;
		### manhattan plot
		open(O, "$newoutdir/$filename.windowed.weir.fst");
		my %hash_temp = ();
		while(<O>) {
			chomp;
			next if /^CHROM/;
			my ($chr) = split(/\t/,$_);
			if ($chr =~ /chr(\d+)/) {
				if(!exists($hash_temp{$1})) {
					$hash_temp{$1} = 0;
				}
			}
		}
		close(O);
		my @arr_chr = sort {$a <=> $b} keys %hash_temp;
		my $maxChr = scalar(@arr_chr);
		my $chrX = $maxChr + 1;
		my $chrY = $maxChr + 2;
		my $chrMT = $maxChr + 3;
		my $modF = "$filename.mod.windowed.weir.fst";

		open(O, "$newoutdir/$filename.windowed.weir.fst");
		open(W, ">$newoutdir/$modF");
		my $header = <O>; chomp($header);
		print W "$header\n";
		while(<O>) {
			chomp;
			print W "$_\n" if /^#/;
			my @arr_t = split(/\t/,$_);
			if ($arr_t[0] =~ /X/i) {
				$arr_t[0] = $chrX;
				print W join("\t", @arr_t)."\n";
			} elsif ( $arr_t[0] =~ /Y/i) {
				$arr_t[0] = $chrY;
				print W join("\t",@arr_t)."\n";
			} elsif ( $arr_t[0] =~ /MT/i) {
				$arr_t[0] = $chrMT;
				print W join("\t",@arr_t)."\n";
			} elsif ( $arr_t[0] =~ /chr/i) {
				my $cutchr = substr($_,3);
				print W "$cutchr\n";
			}else{
				print W "$_\n";
			}
		}
		close(W);
		close(O);
		my $inF = "$newoutdir/$modF";
		my $cmd_mp = "Rscript $qqmanS ";
		$cmd_mp .= "$inF ";
		$cmd_mp .= "$newoutdir/$filename ";
		$cmd_mp .= "$visType ";
		$cmd_mp .= "$plotW ";
		$cmd_mp .= "$plotH ";
		$cmd_mp .= "$genomewideline ";
		$cmd_mp .= "$color";
		$output = `$cmd_mp $Rlib_path &> $newoutdir/$filename.VisMP.log`;
		if ($?){
			exit $? >> 8;
		}
		print STDERR "$cmd_mp &> $newoutdir/$filename.VisMP.log\n";
	}
}
## user target 
if ($userTargetgroups){
	my ($g1,$g2) = split(/\<\-\>/,$userTargetgroups);
	my @ar_g1 = split(/;/,$g1);
	my @ar_g2 = split(/;/,$g2);
	$g1 = join("_",@ar_g1);
    $g2 = join("_",@ar_g2);
	my $newoutdir = abs_path("$outdir/$g1\_VS_$g2");
	`mkdir -p $newoutdir`;
	chdir ("$newoutdir" or die "cannot change: $!\n");
	my @arr_ind = ();
	print "this round : user_comb, $outdir/$g1\_VS_$g2\n";
	my %hs_target1 = ();
	my %hs_target2 = ();
	foreach my $tarspc (@ar_g1){
		$hs_target1{$tarspc} = 1;
	}
	foreach my $tarspc (@ar_g2){
		$hs_target2{$tarspc} = 1;
	}
	open(SPARAM,"$sparam_f")or die "File '$sparam_f' can't be opened";
	while(<SPARAM>){
		$_ =~ s/^\s+|\s+$//g;
		if($_ =~ /^#/ || $_ eq ""){next;}
		my @p = split(/\s+/,$_);
		if (exists($hs_target1{$p[2]})){
			open(W,">>$newoutdir/$filename.pop1");
			print W $p[2]."_".$p[0]."\n";
			close(W);
		
		}elsif (exists($hs_target2{$p[2]})){
			open(W,">>$newoutdir/$filename.pop2");
			print W $p[2]."_".$p[0]."\n";
			close(W);
		}
	}
	close(SPARAM);
	
	push(@arr_ind, "$newoutdir/$filename.pop1");
	push(@arr_ind, "$newoutdir/$filename.pop2");

	### fst 
	my $cmd = "$vcftools ";
	$cmd .= "--gzvcf $inVCF ";
	$cmd .= "--fst-window-size $windowS ";
	$cmd .= "--fst-window-step $stepS ";
	foreach my $ind (@arr_ind) {
		$cmd .= "--weir-fst-pop $ind ";
	}
	$cmd .= "--out $newoutdir/$filename";
	print STDERR "$cmd\n";
	my $output = `$cmd`;
	if ($?){
		exit $? >> 8;
	}
	### manhattan plot
	open(O, "$newoutdir/$filename.windowed.weir.fst");
	my %hash_temp = ();
	while(<O>) {
		chomp;
		next if /^CHROM/;
		my ($chr) = split(/\t/,$_);
		if ($chr =~ /chr(\d+)/) {
			if(!exists($hash_temp{$1})) {
				$hash_temp{$1} = 0;
			}
		}
	}
	close(O);
	my @arr_chr = sort {$a <=> $b} keys %hash_temp;
	my $maxChr = scalar(@arr_chr);
	my $chrX = $maxChr + 1;
	my $chrY = $maxChr + 2;
	my $chrMT = $maxChr + 3;
	my $modF = "$filename.mod.windowed.weir.fst";

	open(O, "$newoutdir/$filename.windowed.weir.fst");
	open(W, ">$newoutdir/$modF");
	my $header = <O>; chomp($header);
	print W "$header\n";
	while(<O>) {
		chomp;
		print W "$_\n" if /^#/;
		my @arr_t = split(/\t/,$_);
		if ($arr_t[0] =~ /X/i) {
			$arr_t[0] = $chrX;
			print W join("\t", @arr_t)."\n";
		} elsif ( $arr_t[0] =~ /Y/i) {
			$arr_t[0] = $chrY;
			print W join("\t",@arr_t)."\n";
		} elsif ( $arr_t[0] =~ /MT/i) {
			$arr_t[0] = $chrMT;
			print W join("\t",@arr_t)."\n";
		} elsif ( $arr_t[0] =~ /chr/i) {
			my $cutchr = substr($_,3);
			print W "$cutchr\n";
		}else{
			print W "$_\n";
		}
	}
	close(W);
	close(O);
	my $inF = "$newoutdir/$modF";
	my $cmd_mp = "Rscript $qqmanS ";
	$cmd_mp .= "$inF ";
	$cmd_mp .= "$newoutdir/$filename ";
	$cmd_mp .= "$visType ";
	$cmd_mp .= "$plotW ";
	$cmd_mp .= "$plotH ";
	$cmd_mp .= "$genomewideline ";
	$cmd_mp .= "$color";
	print STDERR "$cmd_mp &> $newoutdir/$filename.VisMP.log\n";
	$output = `$cmd_mp $Rlib_path &> $newoutdir/$filename.VisMP.log`;
	if ($?){
		exit $? >> 8;
	}
	print STDERR "$cmd_mp &> $newoutdir/$filename.VisMP.log\n";
}
