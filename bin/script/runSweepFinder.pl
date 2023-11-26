#!/usr/bin/perl
#
#
# referenced
# https://gist.github.com/yassineS/fe2712ad52d76460b927e3f391ea51f6


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
my $outdir = "./";
my $help = 0;
my $vcf2SF = "$Bin/vcf2SF.py";
my $polaizeVcf = "$Bin/polarizeVCFbyOutgroup.py";

GetOptions(
    "param|p=s"   => \$param_f,
    "sample|s=s"   => \$sparam_f,
    "outdir|o=s"  => \$outdir,
    "help|h"      => \$help,
);

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

my $line = 0;
my %pop_name = ();
 open(F,"$sparam_f");
 while(<F>){
    chomp;
    if($_ =~ /^#/ || $_ eq ""){next;}
    $_ =~ s/^\s*(.*?)\s*$/$1/;
    $line ++;
    my @p = split(/\s+/,$_);
    $pop_name{$p[2]} = $p[1]."\n";
 }
 close(F);

$outdir = abs_path($outdir);
$hs_param{"ref_fa"} = abs_path($hs_param{"ref_fa"});
my $f_ref_size = "$hs_param{'ref_fa'}.size";

#chromosome set 
my %hs_nouse_chrs = ();
foreach my $this (split(/,/,$hs_param{'non_autosome_list'})){
  $hs_nouse_chrs{$this} = 1;
}
my @ar_chrs = ();
open(F,"$f_ref_size");
while(<F>){
  chomp;
  my @ar_tmp = split(/\t/,$_);
  if (!exists($hs_nouse_chrs{$ar_tmp[0]})){
    push(@ar_chrs,$ar_tmp[0]);
  }
}
close(F);
my $target_chrs = join(",",@ar_chrs);


# 1. VCF filtering + VCF polarizing 
# per population
=p
foreach my $pop (keys %pop_name){
  print STDERR "get $pop polaized vcf\n";
  `$polaizeVcf -vcf  $hs_param{'vcf'}  -out $outdir/pol.vcf -ind 1 -add `;
  print STDERR "$polaizeVcf -vcf  $hs_param{'vcf'}  -out $outdir/pol.vcf -ind 1 -add \n";
  `$hs_param{'bgzip_path'} $outdir/pol.vcf`;
  `$hs_param{'tabix_path'} $outdir/pol.vcf.gz`;
  `echo "position\tx\tn\tfolded" > $outdir/SF2.input`;
  `$hs_param{'vcftools_path'} --counts2 --derived --gzvcf  $outdir/pol.vcf.gz -stdout | awk 'NR<=1 {next} {print \$2"\t"\$6"\t"\$4"\t0"}' >> SF2.input`;
}
=cut
foreach my $pop (keys %pop_name){
  print STDERR "get $pop vcf\n";
  `mkdir -p $outdir/$pop`;
  `echo '$pop' > $outdir/$pop/pop.txt`;
  `$hs_param{'plink_path'} --not-chr $hs_param{"non_autosome_list"} --chr-set $hs_param{'autosome_num'} --bfile $hs_param{'plink'} --keep-fam $outdir/$pop/pop.txt --recode vcf-iid bgz  --keep-allele-order --out $outdir/$pop/$pop &> $outdir/$pop/$pop.plink.log`;
  print STDERR "$hs_param{'plink_path'} --bfile $hs_param{'plink'} --keep-fam $outdir/$pop/pop.txt --recode vcf-iid bgz  --keep-allele-order --out $outdir/$pop/$pop\n";
  `$hs_param{'tabix_path'} -p vcf $outdir/$pop/$pop.vcf.gz`;
  #`$hs_param{'bcftools_path'} norm -t $target_chrs -O z -o $outdir/$pop/$pop\_fixedRefAllele.vcf.gz -c s -f $hs_param{'ref_fa'} $outdir/$pop/$pop.vcf.gz  &> $outdir/$pop/$pop.bcftools.log`;
  #print STDERR "$hs_param{'bcftools_path'} norm -t $target_chrs  -O z -o $outdir/$pop/$pop\_fixedRefAllele.vcf.gz -c s -f $hs_param{'ref_fa'} $outdir/$pop/$pop.vcf.gz\n";
  #`$hs_param{'tabix_path'} -p vcf $outdir/$pop/$pop\_fixedRefAllele.vcf.gz `;
  `$hs_param{'python_path'} $polaizeVcf -vcf  $outdir/$pop/$pop.vcf.gz  -out $outdir/$pop/$pop.pol.vcf -ind 1 -add `;
  `$hs_param{'bgzip_path'} $outdir/$pop/$pop.pol.vcf`;
  `$hs_param{'tabix_path'} $outdir/$pop/$pop.pol.vcf.gz`;
}

# 2. vcf2SF

foreach my $pop (keys %pop_name){
  foreach my $thischr (@ar_chrs){
    print STDERR "processing $pop - $thischr...\n";
    `echo "position\tx\tn\tfolded" > $outdir/$pop/$pop.$thischr.SF2.input`;
    `$hs_param{'vcftools_path'} --counts2 --chr $thischr --derived --gzvcf  $outdir/$pop/$pop.pol.vcf.gz --stdout | awk 'NR<=1 {next} {print \$2"\t"\$6"\t"\$4"\t0"}' >> $outdir/$pop/$pop.$thischr.SF2.input`;
    `grep -v "\t\t" $outdir/$pop/$pop.$thischr.SF2.input > $outdir/$pop/$pop.$thischr.SF2.tmp ; mv $outdir/$pop/$pop.$thischr.SF2.tmp   $outdir/$pop/$pop.$thischr.SF2.input`
    #`$hs_param{'python_path'} $vcf2SF -g -v $outdir/$pop/$pop.pol.vcf.gz -c $thischr -o $outdir/$pop/$pop.$thischr.sfs &> $outdir/$pop/$pop.$thischr.vcf2sf.logs`;
    #print STDERR "$vcf2SF -g -v $outdir/$pop/$pop.pol.vcf.gz -c $thischr -o $outdir/$pop/$pop.$thischr.sfs\n";
  }
}
=p

=cut
# 3. run SweepFinder
#./SweepFinder2 -sg 1000 FreqFile OutFile
#./SweepFinder2 –lg 1000 FreqFile SpectFile OutFile
# g parameter => default = 1000

my $pm = new Parallel::ForkManager($hs_param{'threads'});
foreach my $pop (keys %pop_name){
  foreach my $thischr (@ar_chrs){
    sleep(1);
    
    `mkdir -pv $outdir/$pop/$pop\_sf2_wd/$thischr`;
    $pm -> start and next;
    my $output = `cd $outdir/$pop/$pop\_sf2_wd/$thischr; $hs_param{'sweepfinder_path'}  -sg $hs_param{'grid_size'} $outdir/$pop/$pop.$thischr.SF2.input $outdir/$pop.$thischr.SF2out`;
    print STDERR "$hs_param{'sweepfinder_path'}  -sg $hs_param{'grid_size'} $outdir/$pop/$pop.$thischr.SF2.input $outdir/$pop/$pop.$thischr.SF2out\n";
    if ($?){
      exit $? >> 8;
    }
    $pm -> finish;
  }
}
$pm -> wait_all_children;





=p

polarize 전에 filtering 되어있어야 함 
  -vcf VCF    specify vcf input file
              vcf file should only contain bi-allelic sites and only GT field
              bcftools commands to retain only bi-allelic sites and GT field:
              (bcftools view -h VCFFILE;
               bcftools query -f
               "%CHROM\t%POS\t%ID\t%REF\t%ALT\t%QUAL\t%FILTER\t%INFO\tGT\t[%GT\t]\n" VCFFILE)
              | cat | bcftools view -m2 -M2 -v snps
=cut


#/mss3/RDA_Phase2/programs/plink1.9/plink --bfile ./plink/Cows --keep-fam pop.txt --recode vcf-iid bgz --keep-allele-order --out cow_popsplit/angus

#python3 ../bio-scripts/vcf/polarizeVCFbyOutgroup.py  -vcf ../Cows.variant.combined.GT.SNP.flt.vcf.gz  -out vcf.pol.vcf -ind 1 -add
#/mss_dc/project/ny/pap/newProg/Sweepfinder2/SweepFinder2 -sg 1000 ./SF2.input  sf2.out  &> sf2.log

#/mss_dc/project/ny/pap/newProg/Sweepfinder2/SweepFinder2 -sg 1000 ./SF2.input.filt sf2.out &> sf2.log

#python /mss_dc/project/ny/pap/Pipeline_update/newProg/vcf2SF.py -g -v ./angus.fixedRefAllele.vcf.gz -c 1 -o ./out.sfs

#vcftools --counts2 --derived --gzvcf  ./angus.polarized.vcf.gz --stdout | awk 'NR<=1 {next} {print $2"\t"$6"\t"$4"\t0"}' > SF2.input
 
 
 #python /mss_dc/project/ny/pap/Pipeline_update/newProg/vcf2SF.py -g -v ./angus.fixedRefAllele.vcf.gz -c 1 -o ./out.sfs
 #bcftools norm -O z -o angus.fixedRefAllele.vcf.gz -c s -f /mss_dc/project/ny/pap/test/RUN/chr1/REF/Cow.chr1.fa angus.cow.vcf.gz