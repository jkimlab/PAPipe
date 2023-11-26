#!/usr/bin/perl
#
#
use warnings;
use strict;


use Cwd 'abs_path';
use Parallel::ForkManager;

my $dir = shift;
my $thread = 10;

#my @ar_analysis_list = split(/:/, $analysis_list);
$thread = $#ARGV;

my $pm = new Parallel::ForkManager($thread);
foreach my $this (@ARGV){	
	if ($this eq ""){next;}
    $pm -> start and next;
	my $run = $dir."\/".$this."/cmd";
    my $cmd = "bash $run";
	`$cmd`;
    $pm -> finish;
}

$pm -> wait_all_children;

