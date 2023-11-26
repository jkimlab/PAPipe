#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case);
use FindBin qw($Bin);
use Cwd 'abs_path';
use File::Basename;
use Parallel::ForkManager;
use File::Spec;



#perl /mss_dc/project/ny/pap/Pipeline_update/Original_update/frozen01/script/MSMC.pl -p /mss_dc/project/ny/pap/test/RUN/POP/per_single_chrom/chr26/out/param/06-09-2023_01:05:57/MSMC.txt -s main_sample.txt -o /mss_dc/project/ny/pap/test/RUN/POP/per_single_chrom/chr26/out/04_Population/06-09-2023_01:05:57/MSMC &> /mss_dc/project/ny/pap/test/RUN/POP/per_single_chrom/chr26/out/04_Population/06-09-2023_01:05:57/logs/MSMC.log
#my $generate_GenomeMask = $Bin."/generate_GenomeMask.pl";
#my $input_generation = $Bin."/input_generation.pl";

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

my $idx = 1;

$param_f = abs_path($param_f);
my %hs_param = ();
my %hs_bam_path = ();
#parse param
 open(F,"$param_f");
 while(<F>){
   chomp;
   if ($_ =~/^#/){next;}
   if ($_ =~/^$/){next;}
   $_ =~ s/^\s+|\s+$//g;
   my @ar_tmp = split(/\s*=\s*/,$_);
    if ($ar_tmp[0] =~ /^BAM_(.+)/){
        #absolute_path_change
        my $name = $1;
        my $bam_path = $ar_tmp[1];
        $hs_bam_path{$name} = File::Spec->rel2abs($bam_path);

    }else{
        $hs_param{$ar_tmp[0]} = $ar_tmp[1];
        
    }
 }
 close(F);

my $line = 0;
my %pop_name = ();
 open(F,"$sparam_f");
 while(<F>){
    chomp;
    if($_ =~ /^#/ || $_ eq ""){next;}
    $_ =~ s/^\s*(.*?)\s*$/$1/;
    $line ++;
    my @p = split(/\s+/,$_);
    $pop_name{$p[2]} .= $p[0]."\n";
 }
 close(F);
 #generate 01 param -> generate GenomeMask
 #generate 02 param -> input_generation
 #generate 03 param -> (-)

$outdir = abs_path($outdir);
my $MSMC_maskdir = dirname($outdir);
$MSMC_maskdir = dirname($MSMC_maskdir)."/MSMC_mask/";

$hs_param{"ref_fa"} = abs_path($hs_param{"ref_fa"});
$hs_param{"seqbility_bin"} = abs_path($hs_param{"seqbility_bin"});
$hs_param{"msmctools_bin"} = abs_path($hs_param{"msmctools_bin"});

#environment setting 
`mkdir -p $outdir`;
if (!(-e $MSMC_maskdir."/complete")){
    `mkdir -p $MSMC_maskdir`;
    #mask setting code
    print STDERR "Set the MSMC input setting \n";

    #01 bwa indexing 
    `$hs_param{"bwa_path"} index $hs_param{"ref_fa"}  &> $outdir/bwa.index.log`;
    print STDERR "$hs_param{'bwa_path'} index $hs_param{'ref_fa'}  &> $outdir/bwa.index.log\n";

    #02 read generation
    `mkdir -p $MSMC_maskdir/splittmp`;
    chdir("$MSMC_maskdir/splittmp");
    `$hs_param{'seqbility_bin'}/splitfa  $hs_param{'ref_fa'}  35 | split -l 20000000 `;
    print STDERR "$hs_param{'seqbility_bin'}/splitfa  $hs_param{'ref_fa'}  35 | split -l 20000000 \n";
    `cat x* >> ../split.35.reads`;
    print STDERR "cat x* >> ../split.35.reads\n";
    chdir("$MSMC_maskdir");

    #03 bwa alignment 
    print STDERR "$hs_param{'bwa_path'} aln -t $hs_param{'threads'}  $hs_param{'ref_fa'}   $MSMC_maskdir/split.35.reads 1> $MSMC_maskdir/split.sai 2> $MSMC_maskdir/bwa.aln.log\n";
    `$hs_param{'bwa_path'} aln -t $hs_param{'threads'}  $hs_param{'ref_fa'}   $MSMC_maskdir/split.35.reads 1> $MSMC_maskdir/split.sai 2> $MSMC_maskdir/bwa.aln.log`;
    #print STDERR "$hs_param{'bwa_path'} samse -f $MSMC_maskdir/split.sam $hs_param{'ref_fa'}  $MSMC_maskdir/split.sai  $MSMC_maskdir/split.35.reads\n";
    #`$hs_param{'bwa_path'} samse -f $MSMC_maskdir/split.sam $hs_param{'ref_fa'}  $MSMC_maskdir/split.sai  $MSMC_maskdir/split.35.reads `;
    `$hs_param{'bwa_path'} samse $hs_param{'ref_fa'}   -f $MSMC_maskdir/split.sam $MSMC_maskdir/split.sai $MSMC_maskdir/split.35.reads > $MSMC_maskdir/split.sam`;
    print STDERR "$hs_param{'bwa_path'} samse $hs_param{'ref_fa'}   $MSMC_maskdir/split.sam $MSMC_maskdir/split.sai $MSMC_maskdir/split.35.reads > $MSMC_maskdir/split.sam\n";
    
    print STDERR "$hs_param{'seqbility_bin'}/gen_raw_mask.pl $MSMC_maskdir/split.sam > $MSMC_maskdir/rawMask.fa\n";
    `$hs_param{'seqbility_bin'}/gen_raw_mask.pl $MSMC_maskdir/split.sam > $MSMC_maskdir/rawMask.fa`;
    print STDERR "$hs_param{'seqbility_bin'}/gen_mask -l 35 -r 0.5 $MSMC_maskdir/rawMask.fa > $MSMC_maskdir/mask.fa\n";
    `$hs_param{'seqbility_bin'}/gen_mask -l 35 -r 0.5 $MSMC_maskdir/rawMask.fa > $MSMC_maskdir/mask.fa`;

    print STDERR "python3 $hs_param{'msmctools_bin'}/makeMappabilityMask.python3.py  $MSMC_maskdir/mask.fa &> $MSMC_maskdir/mask.log\n";
    `python3 $hs_param{'msmctools_bin'}/makeMappabilityMask.python3.py  $MSMC_maskdir/mask.fa &> $MSMC_maskdir/mask.log`;
    `rm -rf $MSMC_maskdir/splittmp`;
    `touch complete`;
    print STDERR "MSMC reference masking done \n";
}


chdir($outdir);
## input generation
`mkdir -p $outdir/`;
`mkdir -p $outdir/01_inputGeneration/`;


#01 estimate fasta Size 
print STDERR " ...estimate fasta size\n";
my %hs_chr_size = ();
if (!(-f "$hs_param{'ref_fa'}.size") ){
print STDERR "$hs_param{'faSize'} -detailed $hs_param{'ref_fa'}  > $hs_param{'ref_fa'}.size\n";
`$hs_param{'faSize'} -detailed $hs_param{'ref_fa'}  > $hs_param{'ref_fa'}.size`;
}
open(F,"$hs_param{'ref_fa'}.size");
while(<F>){
    chomp;
    my ($chr, $size) = split(/\t/,$_);
    $hs_chr_size{$chr} = $size;
}
close(F);


print STDERR " ...bam indexing\n";
foreach my $this_indiv (keys %hs_bam_path){
    my $bampath = $hs_bam_path{$this_indiv};
    if (! (-f $bampath.".bai")){
        `$hs_param{"samtools_path"} index -@ $hs_param{'threads'} $bampath`;
        print STDERR "$hs_param{'samtools_path'} index $bampath\n";
    }
    
}

print STDERR " ...bam To VCF processing\n";
if (! (-f "$outdir/01_inputGeneration/complete_vcf")){
my $pm = new Parallel::ForkManager($hs_param{'threads'});
foreach my $this (keys %hs_bam_path){
    my ($pop, $indiv) = split(/_/,$this);
    my $bampath = $hs_bam_path{$this};
    `mkdir -p $outdir/01_inputGeneration/$pop/$indiv`;
    foreach my $chr (keys %hs_chr_size){
        sleep(1);
        `echo '#! /bin/bash' > $outdir/01_inputGeneration/$pop/$indiv/$chr.sh`;
        my $cov_calc_cmd = "cov=\\`$hs_param{'samtools_path'} depth -r $chr $bampath | awk '{sum += \\\$3} END {print sum / NR}'\\`";
        `echo "$cov_calc_cmd" >> $outdir/01_inputGeneration/$pop/$indiv/$chr.sh`;
        my $pileup_cmd = "\\`$hs_param{'samtools_path'} mpileup -q 20 -Q 20 -C 50 -u -r $chr -f $hs_param{'ref_fa'} $bampath | $hs_param{'bcftools_path'} call -c -V indels | $hs_param{'msmctools_bin'}/bamCaller.py \\\$cov $outdir/01_inputGeneration/$pop/$indiv/$chr.$this.mask.bed.gz | gzip -c > $outdir/01_inputGeneration/$pop/$indiv/$chr.$this.vcf.gz\\`";
        `echo "$pileup_cmd" >> $outdir/01_inputGeneration/$pop/$indiv/$chr.sh`;
         
        $pm -> start and next;
        my $output = `bash $outdir/01_inputGeneration/$pop/$indiv/$chr.sh &> $outdir/01_inputGeneration/$pop/$indiv/$chr.log`;
        if ($?){
            exit $? >> 8;
        }
        $pm->finish;
    }
}
$pm -> wait_all_children;
`touch $outdir/01_inputGeneration/complete_vcf`;
}

print STDERR " ...Generate input for msmc2 \n";
my $pop_cnt = 0;
foreach my $pop (keys %pop_name){
    $pop_cnt ++;
    my @ar_indiv = split("\n",$pop_name{$pop});
    foreach my $chr (keys %hs_chr_size){
        my $mask_params = "";
        my $vcf_params = "";
        my $chr_mask = $MSMC_maskdir."/$chr.mask.bed.gz";
        foreach my $indiv (@ar_indiv){
            if ($indiv =~ /^$/){next;}
            my $thisbam = "$pop\_$indiv";
            $mask_params .= "--mask $outdir/01_inputGeneration/$pop/$indiv/$chr.$thisbam.mask.bed.gz ";
            $vcf_params .= "  $outdir/01_inputGeneration/$pop/$indiv/$chr.$thisbam.vcf.gz";
        }    
        #$mask_params .= "--mask $chr_mask ";
        my $cmd = $hs_param{'python_path'} ." ".$hs_param{'msmctools_bin'}."/generate_multihetsep.py  $mask_params $vcf_params 1> $outdir/01_inputGeneration/$pop/$chr.$pop.msmcInput 2>  $outdir/01_inputGeneration/$pop/$chr.$pop.log";
        `$cmd`;
        print STDERR $cmd."\n";
    }
}


## run MSMC
`mkdir -p $outdir/02_runMSMC/`;
print STDERR " ...run msmc2 \n";
my $result_list = "";
my $add_par = "";
foreach my $par ("i", "r", "p"){
	if( exists($hs_param{$par})){
		$add_par .= "-".$par." ".$hs_param{$par}." ";	
	}
}
foreach my $pop (keys %pop_name){
    my $input_list = " ";
    `mkdir -pv $outdir/02_runMSMC/$pop`;
    chdir("$outdir/01_inputGeneration/$pop/");
    foreach my $chr (keys %hs_chr_size){
        $input_list  = " $outdir/01_inputGeneration/$pop/$chr.$pop.msmcInput ";
    }
    my $msmc_cmd = "$hs_param{'msmc_path'}  $add_par  $input_list -o ../../02_runMSMC/$pop ";
    `$msmc_cmd`;
    print STDERR "$msmc_cmd\n";
    $result_list .= " $outdir/02_runMSMC/$pop.final.txt";
}

## visualization
print STDERR " ...draw msmc2 plot \n";
`Rscript $Bin/visMSMC.R 0.00000125  30 $pop_cnt $outdir $Bin/ $result_list `;
print STDERR "Rscript $Bin/visMSMC.R 0.00000125  30 $pop_cnt $outdir $Bin/ $result_list \n";
print STDERR "Done MSMC2\n";
