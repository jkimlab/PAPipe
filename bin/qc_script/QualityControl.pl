#!/usr/bin/perl

use strict;
use warnings; 
use Cwd 'abs_path';
use File::Basename;
use Parallel::ForkManager;
use FindBin qw($Bin);

require "$Bin/Stat_calculator.pl";
require "$Bin/Read_trimmer.pl";

## MAIN 
print STDERR "# Beginning Quality Control Step\n";
my $f_param = shift;
my $f_input = shift;

# Read parameter file 
my %hs_param = ();
my $param_key1 = "INIT";

open(F,"$f_param");
while(<F>){
    chomp;
    if ($_ =~ /^###\s+(\S+)/){
        $param_key1 = $1;
        next;
    }elsif ($_ =~ /^[# \s \n]/ || $_ =~ /^$/){
        next;
    }elsif($_ =~ /^tg;(.+)/){
    	$param_key1 = "Trim_Galore!";
	$_ = $1;
    }
    my @ar_tmp = split(/\s+/,$_);
    if (!exists($ar_tmp[1])){$ar_tmp[1]=" ";}
    $hs_param{$param_key1}{$ar_tmp[0]} = $ar_tmp[1];
}
close(F);



my $outdir = abs_path($hs_param{"INIT"}{"outdir"});
my $thread = $hs_param{"INIT"}{"threads"};
# Read sample file
my %hs_allPopInput = (); #pop #indiv #lib #_1/_2
my %hs_sampleName = (); #pop #indiv #lib #_1/_2
my $pop = "";
my $lib = "";
my $indiv = "";
my $sample_prefix = ""; 
open(F,"$f_input");
while(<F>){
    chomp;
    if ($_ =~ /^#/ || $_ =~ /^\s/ || $_ =~ /^$/){next;}
    if ($_ =~ /<(\S+)_(\S+)>/){
        $pop = $1;
        $indiv = $2;
        next;
    }
    if ($_ =~/\[(\S+)\]/){
        $lib = $1;
        next;
    }
    if ($_ =~ /^[\s \n #]/){next;}

    $sample_prefix = basename($_,(".fastq.gz",".fq.gz"));
	my $cur_file = abs_path($_);
	print $cur_file."\n";
	$hs_allPopInput{$pop}{$lib}{$indiv} .= $cur_file." ";
    $hs_sampleName{$pop}{$lib}{$indiv} .= $sample_prefix." ";

}
close(F);

##calculate raw fastq stat 
#set workdir 
`mkdir -p $outdir/QC_Report_Before_Trimming`;
chdir ("$outdir/QC_Report_Before_Trimming/");
my $pm = new Parallel::ForkManager($thread);
foreach $pop (keys %hs_allPopInput){
    `mkdir -p $outdir/QC_Report_Before_Trimming/$pop`;
    foreach $lib (keys %{$hs_allPopInput{$pop}}) {
        foreach $indiv (keys %{$hs_allPopInput{$pop}{$lib}}){
            my ($cmd1, $cmd2) = fastqc($hs_param{"programs"}{"fastqc_path"},$hs_allPopInput{$pop}{$lib}{$indiv},$hs_sampleName{$pop}{$lib}{$indiv},0);
            foreach my $runcmd ($cmd1, $cmd2){
                $pm -> start and next;
                my ($run, $name) = split(/ /,$runcmd);
                `bash $run; mv $name* ./$pop`;
                $pm -> finish;
            }
        }
    }
}
$pm -> wait_all_children;

foreach $pop (keys %hs_allPopInput){
    my $cmd = multiqc($hs_param{"programs"}{"multiqc_path"});
    `cd $outdir/QC_Report_Before_Trimming/$pop/ ; echo $cmd > multiqc.cmd ; bash multiqc.cmd &> multiqc.log`;
}

## TrimmedData
#set workdir
`mkdir -p $outdir/TrimmedData/`;
chdir ("$outdir/TrimmedData/");
#set additional parameters
my $additional_params = "";
foreach my $param_name (keys %{$hs_param{"Trim_Galore!"}}){
	if ($param_name eq "userAdd"){
		 $additional_params .= " ".$hs_param{"Trim_Galore!"}{$param_name}." ";
	}
    $additional_params .= "--".$param_name." ".$hs_param{"Trim_Galore!"}{$param_name}." ";
}
foreach $pop (keys %hs_allPopInput){
    foreach $lib (keys %{$hs_allPopInput{$pop}}) {
        foreach $indiv (keys %{$hs_allPopInput{$pop}{$lib}}){
            my $cmd = TrimGalore($thread, $hs_param{"programs"}{"Trim_galore_path"},$indiv, $hs_allPopInput{$pop}{$lib}{$indiv},$additional_params);
			print STDERR $cmd."\n";
			`$cmd`;
        }
    }
}
open(F,">$outdir/updated.input.txt");
print F "#### ReadMapping ####\n";
`mkdir -p $outdir/QC_Report_After_Trimming/`;
chdir ("$outdir/QC_Report_After_Trimming/");
$pm = new Parallel::ForkManager($thread);
foreach $pop (sort {$a cmp $b} keys %hs_allPopInput){
    `mkdir -p $outdir/QC_Report_After_Trimming/$pop`;
    print STDERR "  ... Processing [$pop] Trimmed Read Data\n";
    foreach $lib (keys %{$hs_allPopInput{$pop}}) {
        foreach $indiv (sort {$a cmp $b} keys %{$hs_allPopInput{$pop}{$lib}}){
            my ($cmd1, $cmd2, $trimmed_input1, $trimmed_input2) = fastqc($hs_param{"programs"}{"fastqc_path"},$outdir, $hs_sampleName{$pop}{$lib}{$indiv},1);
            print F "<$pop\_$indiv>\n";
            print F "[$lib]\n";
            print F "$trimmed_input1\n";
            print F "$trimmed_input2\n";
            foreach my $runcmd ($cmd1, $cmd2){
                $pm -> start and next;
                my ($run, $name) = split(/ /,$runcmd);
                `bash $run; mv $name* ./$pop`;
                $pm -> finish;
            }
        }
    }
}
$pm -> wait_all_children;
print STDERR "  ... Generating QC Report Per Trimmed Read Data is DONE!\n\n\n";



print STDERR "# Generating Merged QC Report for Trimmed Data ... \n";
foreach $pop (keys %hs_allPopInput){
    print STDERR "  ... Generating Merged QC Report for Trimmed [$pop]\n";
    my $cmd = multiqc($hs_param{"programs"}{"multiqc_path"});
    `cd $outdir/QC_Report_After_Trimming/$pop/ ; echo $cmd > multiqc.cmd ; bash multiqc.cmd &> multiqc.log`;
}
print STDERR "  ... Generating Merged QC Report is DONE!\n\n\n";
print STDERR "# Quality Control Step is DONE!\n\n\n";


