#!/usr/bin/perl

#############################################################################################################
#
#  Parameter 	
#  $./EffectiveSize.pl -t [threads] -p [parameter file] -o [out directory]
#
#  Input
#	Parameter file
#
#  Output
#	psmc.pdf
#
#  Revised
#	-D option is removed.
#############################################################################################################

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case);
use File::Basename;
use Cwd 'abs_path';
use Sort::Key::Natural 'natsort';
use Switch;
use Parallel::ForkManager;

## Parameters
my $param_f;
my $threads = 1;
my $outdir = ".";
my $help = 0;

GetOptions(
	"param|p=s"   => \$param_f,
	"t|threads=s" => \$threads,
	"outdir|o=s"  => \$outdir,
	"help|h"      => \$help,
);

$outdir = abs_path($outdir);

if ($help == 1 || !$param_f) {
	print STDERR "\n================================================\n\n";
	print STDERR "PSMC pipeline (version: 20180624)\n";
	print STDERR "Usage:\n\$./EffectiveSize.pl -t [threads] -p [parameter file] -o [out directory]\n\n";
	print STDERR "Options:\n";
	print STDERR "\t-t|--threads\t<int> Number of threads\n";
	print STDERR "\t-p|--param\t<Path> parameter file\n";
	print STDERR "\t-o|--outdir\t<Path> Output directory\n";
	print STDERR "\t-h|--help\tPrint usages\n";
	print STDERR "\n================================================\n\n";
	exit;
}

### Configure parameters
my $samtools_cmd = "";
my $samtools_merge_core = 10;
my $bcftools_cmd = "";
my $vcfutils_cmd = "";
my $psmc_dir = "";
my %bam_files = ();
my @sample_order = ();
my $legend_order = "";

my $ref_fa = "";
my $sam_c = 0;
my $vcf_d = 0;
my $vcf_D = 0;
my $q = 0;
my $N = 0;
my $t = 0;
my $r = 0;
my $p = "";

my %tmp = ();
open(PARAM,$param_f);
while(<PARAM>){
	chomp;
	if($_ =~ /^#/ || $_ eq ""){next;}
	my @p = split(/\s*=\s*|\s+/);
	if($_ =~ /^BAM/){
		my @arr = split(/_/,$p[0]);
		$bam_files{$arr[1]}{$arr[2]} = $p[1];
		if(exists $tmp{$arr[1]}){next;}
		push(@sample_order,$arr[1]);
		if($legend_order eq ""){
			$legend_order = $arr[1];
		} else {
			$legend_order .= ",$arr[1]";
		}
		$tmp{$arr[1]} = 0;
		next;
	}

	switch ($p[0]) {
		case("Reference")  { $ref_fa = abs_path($p[1]); }
		case("SAMTOOLS")  { $samtools_cmd = abs_path($p[1]); }
		case("SAMTOOLS_MERGE_CORE")  { $samtools_merge_core = abs_path($p[1]); }
		case("BCFTOOLS")  { $bcftools_cmd = abs_path($p[1]); }
		case("VCFUTILS")  { $vcfutils_cmd = abs_path($p[1]); }
		case("PSMC_DIR")        { $psmc_dir = abs_path($p[1]); }
		case("SAM_C")      { $sam_c = $p[1]; }
		case("VCF_d")         { $vcf_d = $p[1]; }
		case("VCF_D")    { $vcf_D = $p[1]; }
		case("q")            { $q = $p[1]; }
		case("N")            { $N = $p[1]; }
		case("t")            { $t = $p[1]; }
		case("r")            { $r = $p[1]; }
		case("p")            { $p = $p[1]; }
	}
}
close(PARAM);

`mkdir -p $outdir`;
my $output;
### Merge bam files
my %hs_multi = ();
foreach my $sample (natsort keys %bam_files){
	my $bam_list = "";
	`mkdir -p $outdir/$sample`;
	foreach my $bam_num (natsort keys %{$bam_files{$sample}}){
		$bam_list .= " $bam_files{$sample}{$bam_num}";
	}
	$hs_multi{$sample} = $bam_list;
}

print STDERR "## Merging BAM files\n";
my $pm = new Parallel::ForkManager($threads);
foreach my $sample (keys %hs_multi){
	sleep(1);
	my $bam_list = $hs_multi{$sample};
	$pm->start and next;
	print STDERR "$samtools_cmd merge --threads $samtools_merge_core $outdir/$sample/$sample.merged.bam $bam_list\n";
	$output = `$samtools_cmd merge --threads $samtools_merge_core $outdir/$sample/$sample.merged.bam $bam_list`;
	if ($?){
		exit $? >> 8;
	}
	$pm->finish;
}
$pm->wait_all_children;

### PSMC
#### 1
print STDERR "## Making diploid.fq.gz\n";
$pm = new Parallel::ForkManager($threads);
foreach my $sample (keys %hs_multi){
	sleep(1);
	$pm->start and next;
	print STDERR "$samtools_cmd mpileup -C$sam_c -uf $ref_fa $outdir/$sample/$sample.merged.bam | $bcftools_cmd view -c - | $vcfutils_cmd vcf2fq -d $vcf_d | gzip > $outdir/$sample/$sample.diploid.fq.gz\n";
	$output = `$samtools_cmd mpileup -C$sam_c -uf $ref_fa $outdir/$sample/$sample.merged.bam | $bcftools_cmd view -c - | $vcfutils_cmd vcf2fq -d $vcf_d | gzip > $outdir/$sample/$sample.diploid.fq.gz`;
	if ($?){
		exit $? >> 8;
	}
	$pm->finish;
}
$pm->wait_all_children;

#### 2
print STDERR "## Making psmcfa\n";
$pm = new Parallel::ForkManager($threads);
foreach my $sample (keys %hs_multi){
	sleep(1);
	$pm->start and next;
	print STDERR "$psmc_dir/utils/fq2psmcfa -q$q $outdir/$sample/$sample.diploid.fq.gz > $outdir/$sample/$sample.diploid.psmcfa\n";
	$output = `$psmc_dir/utils/fq2psmcfa -q$q $outdir/$sample/$sample.diploid.fq.gz > $outdir/$sample/$sample.diploid.psmcfa`;
	if ($?){
		exit $? >> 8;
	}
	$pm->finish;
}
$pm->wait_all_children;

#### 3
print STDERR "## Making psmc\n";
my %hs_psmc = ();
$pm = new Parallel::ForkManager($threads);
foreach my $sample (keys %hs_multi){
	sleep(1);
	$hs_psmc{$sample} = "$outdir/$sample/$sample.diploid.psmc";
	$pm->start and next;
	print STDERR "$psmc_dir/psmc -N$N -t$t -r$r -p $p -o $outdir/$sample/$sample.diploid.psmc $outdir/$sample/$sample.diploid.psmcfa\n";
	$output = `$psmc_dir/psmc -N$N -t$t -r$r -p $p -o $outdir/$sample/$sample.diploid.psmc $outdir/$sample/$sample.diploid.psmcfa`;
	if ($?){
		exit $? >> 8;
	}
	$pm->finish;
}
$pm->wait_all_children;

#### 4
print STDERR "## Drawing a plot\n";
my $psmc_files = "";
foreach my $sample (@sample_order){
	$psmc_files .= " $hs_psmc{$sample}";
}

print STDERR "$psmc_dir/utils/psmc_plot.pl -p -M $legend_order $outdir/psmc_plot $psmc_files\n";
$output = `$psmc_dir/utils/psmc_plot.pl -p -M $legend_order $outdir/psmc_plot $psmc_files`;
if ($?){
	exit $? >> 8;
}
