#!/usr/bin/perl
#
#
use strict;
use warnings;

my $f_in_hapmap = shift;

open(F,"$f_in_hapmap");
while(<F>){
	chomp;
	if ($_ =~ /^rs#/){
		print $_."\n";
		next;
	}
	my @ar_tmp = split (/ /,$_);
	if ($ar_tmp[2] =~ /chr(.+)$/){
		$ar_tmp[2] = $1;
	}
	if ($ar_tmp[2] =~ /\D+/){
		$ar_tmp[2] = 22;
	}
	print join(" ",@ar_tmp)."\n";
}
close(F);
