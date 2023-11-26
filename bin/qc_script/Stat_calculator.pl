#!/usr/bin/perl


use strict;
use warnings;


#1 fastqc
sub fastqc {
    my $fastqc_path = shift;
    my $input = shift;
    my $prefix = shift;
    my $flag = shift;
    
    my @ar_prefix = split(/\s/,$prefix);

    if ($flag == 0){
        my @ar_input = split(/\s/,$input);
        my $cmd1 = "$fastqc_path -f fastq -o ./  $ar_input[0]  \&\> ./$ar_prefix[0].log";
        my $cmd2 = "$fastqc_path -f fastq -o ./  $ar_input[1]  \&\> ./$ar_prefix[1].log";
    
        my $f_cmd1 = $ar_prefix[0].".cmd";
        my $f_cmd2 = $ar_prefix[1].".cmd";
        `echo "$cmd1" > $f_cmd1`;
        `echo "$cmd2" > $f_cmd2`;
        return ("$f_cmd1 $ar_prefix[0]", "$f_cmd2 $ar_prefix[1]");
    }else{
        my $trimmed_input1 = "$input/TrimmedData/$ar_prefix[0]_val_1.fq.gz";
        my $trimmed_input2 = "$input/TrimmedData/$ar_prefix[1]_val_2.fq.gz";
        my $cmd1 = "$fastqc_path -f fastq -o ./  $trimmed_input1  \&\> ./$ar_prefix[0].log";
        my $cmd2 = "$fastqc_path -f fastq -o ./  $trimmed_input2  \&\> ./$ar_prefix[1].log";
        my $f_cmd1 = $ar_prefix[0].".cmd";
        my $f_cmd2 = $ar_prefix[1].".cmd";
        `echo "$cmd1" > $f_cmd1`;
        `echo "$cmd2" > $f_cmd2`;
        return ("$f_cmd1 $ar_prefix[0]", "$f_cmd2 $ar_prefix[1]", $trimmed_input1, $trimmed_input2);
    }
    
}
#/mss1/programs/titan/FastQC/fastqc -f fastq -o . /mss4/PopPipe/data/Angus/SRR1262656_2.fastq.gz &> SRR1262656_2.log

#2 multiqc 
sub multiqc {
    my $multiqc_path = shift;
    my $cmd = "$multiqc_path  ./";
    return $cmd;
}

return 1;
exit;