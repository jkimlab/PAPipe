#!/usr/bin/perl
######
##  Example)
##  $./AdmixtureProportion.pl -p [parameter file] -o [out directory]
##
##  Input
##   Parameter file
##
##  Output
##   out files for each analysis in each directory
##
######

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case);
use Parallel::ForkManager;
use File::Basename;
use Cwd 'cwd';
use Cwd 'abs_path';
use Sort::Key::Natural 'natsort';
use Switch;
use  List::MoreUtils 'uniq';

## Parameters
my $param_f;
my $sparam_f;
my $outdir = "./";
my $help = 0;
my %hs_dir_cmds = ();

GetOptions(
	"param|p=s"   => \$param_f,
	"sample|s=s"   => \$sparam_f,
	"outdir|o=s"  => \$outdir,
	"help|h"      => \$help,
);

if ($help == 1 || !$param_f) {
	print STDERR "usage:\n\$./AdmixtureProportion.pl -p PARAM -s SAMPLE_PARAM  -o OUT_DIR \n\n";
	print STDERR "optional arguments:\n";
	print STDERR "\t-h, --help\tshow this help message and exit\n";
	print STDERR "\t-p, --param\tPARAM\n\t\t\t\t<Path> parameter file\n";
	print STDERR "\t-s, --sample\tSAMPLE_PARAM\n\t\t\t\t<Path> sample parameter file\n";
	print STDERR "\t-o, --outdir\tOUT_DIR\n\t\t\t\t<Path> Output directory\n";
	print STDERR "\n================================================\n\n";
	exit;
}


#Configure parameters
my $admixtools_bin = "";
my $plink_prefix = "";
my $result_prefix = "Admixtools_result";

open(PARAM,$param_f);
while(<PARAM>){
	chomp;
	if($_ =~ /^#/ || $_ eq ""){next;}
	my @p = split(/\s*=\s*/);
	switch ($p[0]){
		case("ADMIXTOOLS") {$admixtools_bin = abs_path($p[1]);}
		case("PLINK") {$plink_prefix = abs_path($p[1]);}
	}
}
close(PARAM);

$sparam_f = abs_path($sparam_f);
$outdir = abs_path($outdir);
print STDERR "outdir $outdir\n";

my %hs_fam_name = ();
my @ar_fam_name = ();
open(FS,"$sparam_f");
while(<FS>){
	chomp;
	$_ =~ s/^\s*(.*?)\s*$/$1/;
	my @p = split(/\s+/,$_);
	if (exists($hs_fam_name{$p[2]})){
		next;
	}else{
		$hs_fam_name{$p[2]} = 1;
		push(@ar_fam_name, $p[2]);
	}
}
close(FS);
if (@ar_fam_name < 3){
	print STDERR "ADMIXTOOLS\n";
	print STDERR "There are not enough populations for analysis, at least 3 populations for f3 statistics\n";
	exit 1;
}

`mkdir -p $outdir`;
chdir(abs_path($outdir));
############################################################convertf
my $convertf = $admixtools_bin."/convertf";
my $convertfdir = abs_path("$outdir/admixtools_convert");
`mkdir -p $convertfdir`;
chdir($convertfdir);
my $convertf_par = $convertfdir."/par_convert";
open(FW,">$convertf_par");
print FW "genotypename: $plink_prefix.ped\n";
print FW "snpname: $plink_prefix.map\n";
print FW "indivname: $plink_prefix.fam\n";
print FW "outputformat: EIGENSTRAT\n";
print FW "genotypeoutname: $convertfdir\/$result_prefix.eigenstratgeno\n";
print FW "snpoutname: $convertfdir\/$result_prefix.snp\n";
print FW "indivoutname: $convertfdir\/$result_prefix.ind\n";
print FW "familynames: NO\n";
print FW "badpedignore:    YES\n";
close(FW);
`echo "$convertf  -p $convertf_par 1> $convertfdir/convert.status 2> $convertfdir/convert.log" > $convertfdir/convertf.CMD`;
chdir($convertfdir);
my $output = `bash convertf.CMD`;
if ($?){
	exit $? >> 8;
}


############################################################3pop
chdir(abs_path($outdir));
my $pop3 = $admixtools_bin."/qp3Pop";
my $pop3dir = abs_path($outdir."/admixtools_3pop");
`mkdir -p $pop3dir`;
chdir($pop3dir);
#parameter generation
my $pop3_par = $pop3dir."/par_3pop";
open(FW,">$pop3_par");
print FW "DIR: $convertfdir\n";
print FW "SSS: $result_prefix\n";
print FW "indivname: $sparam_f\n";
print FW "snpname: DIR/SSS.snp\n";
print FW "genotypename: DIR/SSS.eigenstratgeno\n";
print FW "popfilename: list_3pop\n";
close(FW);
#input list generation
my $pop3_list = $pop3dir."/list_3pop";
open(FW,">$pop3_list");
for (my $i = 0 ; $i <= $#ar_fam_name ; $i ++){
	for (my $j = 0 ; $j <= $#ar_fam_name; $j ++){
		if ($j == $i){next;}
		for (my $k = $j+1 ; $k <= $#ar_fam_name; $k ++){
			if ($k == $i){next;}
			print FW "$ar_fam_name[$j] $ar_fam_name[$k] $ar_fam_name[$i]\n";	
		}
	}
}
close(FW);
#running command generation
`echo "cd  $pop3dir" > $pop3dir/pop3.CMD`;
`echo "$pop3 -p $pop3dir/par_3pop 1>$pop3dir/3pop.out 2> $pop3dir/3pop.log" >> $pop3dir/pop3.CMD`;
$hs_dir_cmds{1} = "bash $pop3dir/pop3.CMD";

############################################################4diff
chdir(abs_path($outdir)) or die;
if (@ar_fam_name >= 5){
    my $stat4 = $admixtools_bin."/qp4diff";
    my $stat4dir = abs_path($outdir."/admixtools_4diff"); 
    `mkdir -p $stat4dir`;
    chdir ($stat4dir);
    #parameter generation
    my $stat4_par = $stat4dir."/par_4diff";
    open(FW,">$stat4_par");
    print FW "DIR: $convertfdir\n";
    print FW "SSS: $result_prefix\n";
    print FW "indivname: $sparam_f\n";
    print FW "snpname: DIR/SSS.snp\n";
    print FW "genotypename: DIR/SSS.eigenstratgeno\n";
    print FW "popfilename: list_4diff\n";
    close(FW);
    #input list generation
    my $stat4_list = $stat4dir."/list_4diff";
    open(FW,">$stat4_list");
    for (my $i = 0 ; $i <= $#ar_fam_name ; $i ++){
        for (my $j = 0 ; $j <= $#ar_fam_name; $j ++){
            if ($i == $j){next;}
            for (my $k = 0 ; $k <= $#ar_fam_name; $k ++){
                if ($i==$k){next;}
                if ($j==$k){next;}
                for (my $l = 0 ; $l <= $#ar_fam_name; $l ++){
                    if ($i==$l){next;}
                    if ($j==$l){next;}
                    if ($k==$l){next;}
                    for (my $m = 0 ; $m <= $#ar_fam_name; $m ++){
                        if ($i==$m){next;}
                        if ($j==$m){next;}
                        if ($k==$m){next;}
                        if ($l==$m){next;}
                        print FW "$ar_fam_name[$i] $ar_fam_name[$m] : $ar_fam_name[$l] $ar_fam_name[$k] :: $ar_fam_name[$i] $ar_fam_name[$m] : $ar_fam_name[$j] $ar_fam_name[$k]\n";
                    }
                }
            }
        }
    }
    close(FW);
	`echo "cd $stat4dir" > $stat4dir/diff4.CMD`;
    `echo "$stat4 -p $stat4_par 1>$stat4dir/4diff.out 2> $stat4dir/4diff.log" >> $stat4dir/diff4.CMD`;
    $hs_dir_cmds{2} = "bash $stat4dir/diff4.CMD";
}
############################################################Dstat 

if (@ar_fam_name >= 4){
    my $Dstat = $admixtools_bin."/qpDstat";
    my $Dstatdir = abs_path("$outdir/admixtools_Dstat");
    `mkdir -p $Dstatdir`;
    chdir ($Dstatdir);
    #parameter generation
    my $Dstat_par = $Dstatdir."/par_Dstat";
    open(FW,">$Dstat_par");
    print FW "DIR: $convertfdir\n";
    print FW "SSS: $result_prefix\n";
    print FW "indivname: $sparam_f\n";
    print FW "snpname: DIR/SSS.snp\n";
    print FW "genotypename: DIR/SSS.eigenstratgeno\n";
    print FW "popfilename: list_Dstat\n";
    close(FW);
    #input list generation
    open(FW,">list_Dstat");
    for (my $i = 0 ; $i <= $#ar_fam_name ; $i ++){
        for (my $j = 0 ; $j <= $#ar_fam_name ; $j ++){
            if ($i == $j){next;}
            print FW "$ar_fam_name[$j] ";
        }
        print FW "\n";
    }
    close(FW);
	`echo "cd  $Dstatdir" > $Dstatdir/Dstat.CMD`;
    `echo "$Dstat -p $Dstat_par 1>$Dstatdir/Dstat.out 2> $Dstatdir/Dstat.log" >> $Dstatdir/Dstat.CMD`;
    $hs_dir_cmds{3} = "bash $Dstatdir/Dstat.CMD";
}

############################################################Dstat 

if (@ar_fam_name >= 4){
my $Dstat = $admixtools_bin."/qpDstat";
my $Dstatdir = abs_path("$outdir/admixtools_f4stat");
`mkdir -p $Dstatdir`;
chdir ($Dstatdir);
#parameter generation
my $Dstat_par = $Dstatdir."/par_f4stat";
open(FW,">$Dstat_par");
print FW "DIR: $convertfdir\n";
print FW "SSS: $result_prefix\n";
print FW "indivname: $sparam_f\n";
print FW "snpname: DIR/SSS.snp\n";
print FW "genotypename: DIR/SSS.eigenstratgeno\n";
print FW "popfilename: list_f4stat\n";
print FW "f4mode:   YES\n";
close(FW);
#input list generation
open(FW,">list_f4stat");
for (my $i = 0 ; $i <= $#ar_fam_name ; $i ++){
	for (my $j = 0 ; $j <= $#ar_fam_name ; $j ++){
		if ($i == $j){next;}
		print FW "$ar_fam_name[$j] ";
	 }
	print FW "\n";
}
close(FW);
`echo "cd $Dstatdir" > $Dstatdir/f4stat.CMD`;
`echo "$Dstat -p $Dstat_par 1>$Dstatdir/f4stat.out 2> $Dstatdir/f4stat.log" >> $Dstatdir/f4stat.CMD`;
$hs_dir_cmds{4} = " bash  $Dstatdir/f4stat.CMD";
}

my $pm = new Parallel::ForkManager(4);
foreach my $idx (1,2,3,4){
	$pm->start and next;

    `$hs_dir_cmds{$idx}`;
    if ($?){
	    exit $? >> 8;
    }
    $pm->finish;
}
$pm->wait_all_children;
