#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw($Bin);


my $dir_out = shift;
my $webEnv = "$dir_out/web/04_Population/";
my $webParamEnv = "$dir_out/web/param/";
my $dir_pop = "$dir_out/04_Population/";
my $dir_param = "$dir_out/param/";

opendir my $dirHdl, $dir_pop or die "Cannot open directory: $!";
my @ar_resSet = readdir $dirHdl;
closedir $dirHdl;

foreach my $this (@ar_resSet){
    chomp($this);
    if ($this =~ /\.+/ || $this eq "MSMC_mask"){next;}
    #print $this."\n";
    my $dir_res = $dir_pop."/$this/";
    opendir my $dirHdlsmall, $dir_res or die "Cannot open directory: $!";
    my @ar_ress = readdir $dirHdlsmall;
    closedir $dirHdlsmall;
    `mkdir -pv $webParamEnv/$this/`;

    foreach my $analysis (@ar_ress){
        chomp($analysis);
        my $dir_analysis = $dir_res."/$analysis/";
        #print $dir_res."/$analysis/\n";
        #`mkdir -pv $webEnv/$this/$analysis/`;
        if ($analysis eq "AdmixtureProportion"){
            opendir my $insideAnalysis, $dir_analysis or die "Cannot open directory: $!";
            my @ar_resIn = readdir $insideAnalysis;
            closedir $insideAnalysis;
            foreach my $smallRes (@ar_resIn){
                chomp($smallRes);
                if ($smallRes eq "admixtools_convert" || $smallRes eq "cmd" || $smallRes =~ /\.+/){next;}
                my $orig = $dir_res."/$analysis/$smallRes";
                `mkdir -pv $webEnv/$this/$analysis/$smallRes/`;
                `cp $orig/*.out $webEnv/$this/$analysis/$smallRes/ `;
            }
            `cp $dir_param/$this/AdmixtureProportion.txt $dir_out/web/param/$this/`;
        }

        if ($analysis eq "Fst"){
            opendir my $insideAnalysis, $dir_analysis or die "Cannot open directory: $!";
            my @ar_resIn = readdir $insideAnalysis;
            closedir $insideAnalysis;
            foreach my $smallRes (@ar_resIn){
                chomp($smallRes);
                if ($smallRes eq "cmd" || $smallRes =~ /\.+/){next;}
                my $orig = $dir_res."/$analysis/$smallRes";
                `mkdir -pv $webEnv/$this/$analysis/$smallRes/`;
                `cp $orig/*.pdf $webEnv/$this/$analysis/$smallRes/Fst_result.pdf `;
                my $pop1 = `cut -f1 -d'_' $orig/*.pop1 | sort -u  | tr '\n' ';' `;
                my $pop2 = `cut -f1 -d'_' $orig/*.pop2 | sort -u  | tr '\n' ';' `;
                chomp($pop1);
                chomp($pop2);
                `echo "$pop1 vs $pop2" > $webEnv/$this/$analysis/$smallRes/pair_info.txt` 
            }
            `cp $dir_param/$this/Fst.txt $dir_out/web/param/$this/`;
        }

        if ($analysis eq "PhylogeneticTree"){
            my $orig = $dir_res."/$analysis/";
            `mkdir -pv $webEnv/$this/$analysis/`;
            `cp $orig/snphylo.ml.png $webEnv/$this/$analysis/`;
            `cp $orig/Rplots.pdf $webEnv/$this/$analysis/`;
            `cp $orig/snphylo.ml.tree $webEnv/$this/$analysis/`;
            `cp $dir_param/$this/PhylogeneticTree.txt $dir_out/web/param/$this/`;
        }
        if ($analysis eq "EffectiveSize"){
            my $orig = $dir_res."/$analysis/";
            `mkdir -pv $webEnv/$this/$analysis/`;
            `cp $orig/psmc_plot.pdf $webEnv/$this/$analysis/`;
            `cp $dir_param/$this/EffectiveSize.txt $dir_out/web/param/$this/`;
        }

        if ($analysis eq "LdDecay"){
            opendir my $insideAnalysis, $dir_analysis or die "Cannot open directory: $!";
            my @ar_resIn = readdir $insideAnalysis;
            closedir $insideAnalysis;
            foreach my $smallRes (@ar_resIn){
                chomp($smallRes);
                if ($smallRes eq "cmd" || $smallRes =~ /\.+/){next;}
                my $orig = $dir_res."/$analysis/$smallRes/Plot/";
                `mkdir -pv $webEnv/$this/$analysis/$smallRes/Plot/`;
                `cp $orig/out.pdf  $webEnv/$this/$analysis/$smallRes/Plot/ `;
            }
            `cp $dir_param/$this/LdDecay.txt $dir_out/web/param/$this/`;
        }

        if ($analysis eq "PCA"){
            my $orig = $dir_res."/$analysis/";
            `mkdir -pv $webEnv/$this/$analysis/`;
            `cp $orig/all.PCA.pdf $webEnv/$this/$analysis/`;
            `cp $dir_param/$this/PCA.txt  $dir_out/web/param/$this/`;
        }
        if ($analysis eq "MSMC"){
            my $orig = $dir_res."/$analysis/";
            `mkdir -pv $webEnv/$this/$analysis/`;
            `cp $orig/MSMC.pdf $webEnv/$this/$analysis/`;
            `cp $dir_param/$this/MSMC.txt  $dir_out/web/param/$this/`;
        }
        if ($analysis eq "Plink2"){
            my $orig = $dir_res."/$analysis/";
            `mkdir -pv $webEnv/$this/$analysis/`;
            `cp $orig/all.PCA.pdf $webEnv/$this/$analysis/PCA_projection.pdf`;
            `cp $dir_param/$this/Plink2.txt  $dir_out/web/param/$this/`;
        }
        if ($analysis eq "Structure"){
            my $orig = $dir_res."/$analysis/";
            `mkdir -pv $webEnv/$this/$analysis/CLUMPAK/`;
            `cp $orig/CLUMPAK/*pdf $webEnv/$this/$analysis/CLUMPAK/`;
            `cp $dir_param/$this/Structure.txt   $dir_out/web/param/$this/`;
        }
        ########################################################보류
        if($analysis eq "SweepFinder2"){
			opendir my $insideAnalysis, $dir_analysis or die "Cannot open directory: $!";
            my @ar_resIn = readdir $insideAnalysis;
            closedir $insideAnalysis;
			foreach my $smallRes (@ar_resIn){
                chomp($smallRes);
                if ($smallRes eq "cmd" || $smallRes =~ /\.+/){next;}
                my $orig = $dir_res."/$analysis/$smallRes/SweepFinderOut.pdf";
                `mkdir -pv $webEnv/$this/$analysis/$smallRes/`;
                `cp $orig  $webEnv/$this/$analysis/$smallRes/SweepFinderOut.pdf `;
            }

			#my $orig = $dir_res."/$analysis/";
			#`mkdir -pv $webEnv/$this/$analysis/`;
			#`cp $orig/ $webEnv/$this/$analysis/`;
            `cp $dir_param/$this/SweepFinder2.txt  $dir_out/web/param/$this/`;
        }
        if ($analysis eq "Treemix"){
            my $orig = $dir_res."/$analysis/";
            `mkdir -pv $webEnv/$this/$analysis/`;
            `cp $orig/Treemix.results.pdf $webEnv/$this/$analysis/`;
            `cp $dir_param/$this/Treemix.txt   $dir_out/web/param/$this/`;
        }
    }
}
`cp $Bin/html/index.html $dir_out/web/`;
