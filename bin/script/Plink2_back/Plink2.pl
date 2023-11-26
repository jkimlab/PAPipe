#!/usr/bin/perl


use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case);
use FindBin qw($Bin);
use Cwd 'abs_path';
use File::Basename;
use Parallel::ForkManager;


## Parameters
my $param_f;
my $sparam_f;
my $outdir = "";
my $help = 0;

GetOptions(
    "param|p=s"   => \$param_f,
    "sample|s=s"   => \$sparam_f,
    "outdir|o=s"  => \$outdir,
    "help|h"      => \$help,
);

#perl /mss_dc/project/ny/pap/Pipeline_update/Original_update/frozen01/script/Plink2.pl -p /mss_dc/project/ny/pap/test/RUN/POP/per_single_chrom/chr26/out/param/06-09-2023_01:05:57/SweepFinder2.txt -s main_sample.txt -o /mss_dc/project/ny/pap/test/RUN/POP/per_single_chrom/chr26/out/04_Population/06-09-2023_01:05:57/Plink2 &> /mss_dc/project/ny/pap/test/RUN/POP/per_single_chrom/chr26/out/04_Population/06-09-2023_01:05:57/logs/Plink2.log


$param_f = abs_path($param_f);
my %hs_param = ();
#parse param
 open(F,"$param_f");
 while(<F>){
   chomp;
   if ($_ =~/^#/){next;}
   if ($_ =~/^$/){next;}
   $_ =~ s/^\s+|\s+$//g;
   my @ar_tmp = split(/\s*=\s*/,$_);
   $hs_param{$ar_tmp[0]} = $ar_tmp[1];
 }
 close(F);

$outdir = abs_path($outdir);
$hs_param{"vcfInput"} = abs_path($hs_param{"vcfInput"});
#$hs_param{"ref_fa"} = abs_path($hs_param{"ref_fa"});


chdir($outdir);
# remove sex chromosome 
`$hs_param{"vcftools"} --gzvcf $hs_param{"vcfInput"} --not-chr $hs_param{"non_autosome_list"} --recode --stdout | gzip -c > $outdir/noSex.$hs_param{"popName"}.vcf.gz`;
print STDERR "$hs_param{'vcftools'} --gzvcf $hs_param{'vcfInput'} --not-chr $hs_param{'non_autosome_list'} --recode --stdout | gzip -c > $outdir/noSex.$hs_param{'popName'}.vcf.gz";

my $missingvarID = '@:#';
#1. make pgen
my $cmd_makepgen = "$hs_param{'plink2'}  --make-pgen --chr-set $hs_param{'autosome_cnt'} --not-chr $hs_param{'non_autosome_list'} --freq --set-missing-var-ids $missingvarID --geno 0.01 --maf 0.05  --vcf $outdir/noSex.$hs_param{'popName'}.vcf.gz &> $outdir/plink2_makepgen.log";
`$cmd_makepgen`;
print STDERR $cmd_makepgen."\n";
#2. export PCs
`$hs_param{"plink2"}  -pfile ./plink2 --read-freq $outdir/plink2.afreq --pca allele-wts --out $outdir/ref_pcs &> $outdir/exportPC.log`;
print STDERR "$hs_param{'plink2'}  -pfile $outdir/plink2 --read-freq $outdir//plink2.afreq --pca allele-wts --out $outdir/ref_pcs &> $outdir/exportPC.log\n";

#3. project onto those PCs with 
`$hs_param{"plink2"}  -pfile $outdir/plink2 --out new_projection --read-freq $outdir/plink2.afreq --score $outdir/ref_pcs.eigenvec.allele 2 5 header-read no-mean-imputation variance-standardize  --score-col-nums 6-15 `;
print STDERR "$hs_param{'plink2'}  -pfile $outdir/plink2 --out new_projection --read-freq $outdir/plink2.afreq --score $outdir/ref_pcs.eigenvec.allele 2 5 header-read no-mean-imputation variance-standardize  --score-col-nums 6-15\n";;


#4 visualization
#group setting 
`cut -f1 $outdir/new_projection.sscore  | cut -f1 -d"_"  > $outdir/group`;
`Rscript $Bin/visPCA_projection.R $hs_param{'title'}  $hs_param{'pca_num'} $outdir/ref_pcs.eigenval  $outdir/new_projection.sscore  $outdir/group $hs_param{'variance'} $outdir $hs_param{'Rlib_path'} $Bin`;
print STDERR "Rscript $Bin/visPCA_projection.R '$hs_param{'title'}'  $hs_param{'pca_num'} $outdir/ref_pcs.eigenval  $outdir/new_projection.sscore  $outdir/group $hs_param{'variance'} $outdir $hs_param{'Rlib_path'} $Bin\n";

#-----------------------------------
#score test
#freq test 

#[p3159@europa00 test]$ cat cmd_freq_test 
#../plink2 --vcf ./Cows.variant.combined.GT.SNP.flt.vcf.gz --freq --out test.freq --threads 20 &> log.freq

#[p3159@europa00 test]$ cat cmd_score_test 
#../plink2 --score --vcf ./Cows.variant.combined.GT.SNP.flt.vcf.gz --out test.score --threads 20 &> log.score


#../../plink2  --make-pgen --cow --chr 1 --freq --geno 0.01 --maf 0.05  --vcf ./Cows.variant.combined.GT.SNP.flt.vcf.gz &> all.log

#../../../plink2  -pfile ../plink2 --read-freq ../plink2.IDexists.afreq  --pca allele-wts --out ref_pcs &> 01.log

#Rscript /mss_dc/project/ny/pap/Pipeline_update/Original_update/script/visPCA.R 'Cow PCA' 20 /mss_dc/project/ny/pap/test/RUN/POP/per_single_chrom/chr24/out/04_Population/04-09-2023_15:34:34/PCA/PCA/Cows.eigenval  /mss_dc/project/ny/pap/test/RUN/POP/per_single_chrom/chr24/out/04_Population/04-09-2023_15:34:34/PCA/PCs.info 80  /mss_dc/project/ny/pap/test/RUN/POP/per_single_chrom/chr24/out/04_Population/04-09-2023_15:34:34/PCA
