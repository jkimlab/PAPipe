#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use Cwd 'abs_path';

my $vcf_f = shift;
$vcf_f = abs_path($vcf_f);
my $outdir = shift;
my $hapmap_f = "";
if ($vcf_f =~ /\.gz$/) {
	$hapmap_f = basename($vcf_f, ".vcf.gz").".hapmap";
	open(F, "gunzip -c $vcf_f|");
}else {
	$hapmap_f = basename($vcf_f, ".vcf").".hapmap";
	open(F, $vcf_f);
}

print STDERR "Reading in VCF file....\n";
print STDERR "Writting in HAPMAP file....\n";
my $rsnumber = 0;
my $chr_max = 0;
my $samp_num = 0;
my %hs_pop_exists = ();
my $f_name_match = "$outdir/hapmap.namematch.txt";
open(W,">$outdir/$hapmap_f");
#open(F,"gunzip -c $vcf_f|");
while(<F>){
	chomp;
	if(/##/){ next; }
	else {
		my @arr = split(/\s+/);
		if(/#CHROM/){
				open(WM,">$f_name_match");
				print STDERR $f_name_match."\n";
			print W "rs# alleles chrom pos strand assembly# center protLSID assayLSID panelLSID QCcode";
			for(my $i=9;$i<=$#arr;$i++){
				my $samp_name = "";
				my $pop_name = "";
				if ($arr[$i]=~ /^(.+)_(.+)$/){$pop_name = $1; $samp_name = $2;}
				if (!exists($hs_pop_exists{$pop_name})){
					$hs_pop_exists{$pop_name}=1;
				}else{
					$hs_pop_exists{$pop_name}++;
				}
				$samp_num = $hs_pop_exists{$pop_name};
				my $original_name = $arr[$i];
				$arr[$i] = substr($pop_name,0,4).substr($samp_name,0,3).$samp_num;
				print WM "$arr[$i]\t$original_name\n";
				
			}
			
			for(my $i=9;$i<=$#arr;$i++){
				print W " $arr[$i]";
			}
			print W "\n";
				close(WM);
		} else {
			my ($chr,$pos,$id,$ref,$alt,$qual,$filter,$info,$format) = splice(@arr,0,9);
			my @variants = @arr;
			my $width = 8;
			$rsnumber++;
			if($alt =~ /,/){ next; }
			elsif(/GT:AD:DP:GQ:PL/ || /GT:AD:DP:GQ:PGT:PID:PL/|| /GT:PL/){
				foreach (@variants){
					s#\./\..*#$ref$ref#;
					s#^0/0.*#$ref$ref#;
					s#^0/1.*#$ref$alt#;
					s#^1/1.*#$alt$alt#;
				}
				my $genotype = join(" ",@variants);
				$chr =~ s/chr//;
				if($chr =~ /^\d+$/) {
					if(int($chr) > $chr_max) {
						$chr_max = int($chr);
					}
				}else {
					$chr = $chr_max+1;
				}

				print W "rs";
				printf W ("%0*d",$width,$rsnumber);
				print W " $ref/$alt $chr $pos . NA NA NA NA NA NA $genotype\n";
			} else { 
				print  "$_\n";
				next; 
			}
		}
	}
}
close(W);
close(F);
print STDERR "done.";
