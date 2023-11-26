#!/usr/bin/perl

use strict;
use warnings;

sub TrimGalore{
    my $core = shift;
    my $TrimGalore_path = shift;
    my $indiv = shift;
    my $input = shift;
    my $additional_params = shift;
    my $cmd = "$TrimGalore_path $additional_params --gzip  --paired --cores 8 $input &> $indiv.log";
    return $cmd;

}

sub IlluQC{
    my $IlluQC_path = shift;
    my $indiv = shift;
    my $input = shift;
    my $p_adapterLib = shift;
    my $p_fqVariant = shift;
    `$IlluQC_path -pe $input $p_adapterLib $p_fqVariant  -z g -p 3 -o ./$indiv`;
}
 
return 1;
exit;

=p
#/mss3/RDA_Phase2/programs/TrimGalore-0.6.0/trim_galore 
--path_to_cutadapt /home/sunny/.local/bin/cutadapt 
--gzip 
--paired 
-o . ㄹ
--cores 10 
/bps_data/minipig/other_breeds/normal/WB/WB_Greece/ERR977358_1.fastq.gz 
/bps_data/minipig/other_breeds/normal/WB/WB_Greece/ERR977358_2.fastq.gz 
&> log.ERR977358

#/mss3/RDA_Phase2/programs/NGSQCToolkit_v2.3.3/QC/IlluQC.pl 
-pe 
/mss3/RDA_Phase2/data/data_20190130/1901AHX-0009_hdd1/F10-263/F10-263_R1.fastq.gz 
/mss3/RDA_Phase2/data/data_20190130/1901AHX-0009_hdd1/F10-263/F10-263_R2.fastq.gz 
N 
A 
-o /mss3/RDA_Phase2/data/data_20190130/trimmed_data/F10-263 
-p 2 
-z g
cut
