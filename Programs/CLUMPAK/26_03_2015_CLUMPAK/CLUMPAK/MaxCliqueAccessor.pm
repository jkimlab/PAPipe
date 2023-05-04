package MaxCliqueAccessor;

use strict;
use warnings;
#use Data::PowerSet;
use Getopt::Std;
use Array::Utils qw(:all);
use File::Slurp;

use vars qw(@ISA @EXPORT);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(MaxClique);



my @matrix;

sub MaxClique
{
	my ($curJobDirectory, $inputFile, $matrixSize, $threshold) = @_;

	print "\nCalling Max Clique algorithm..\n";
	
	#Reading matrix
	open(INPUT_FILE, "<$inputFile") || die "Cannot open file $inputFile, $!";
	
	my @matrixLines;
	
	while (my $curLine = <INPUT_FILE>)
	{
		chomp($curLine);
		push(@matrixLines, $curLine);
	}
	
	close(INPUT_FILE);
	
	$matrixSize = 0 + @matrixLines;
	
	my $mat = MakeMatrix (@matrixLines);
	@matrix = @$mat;
		
	my @indices;
	for (my $i = 0; $i < $matrixSize; $i++)
	{
		push(@indices, $i);
	}
	
	my $minSize = int($matrixSize / 3);
	my $combinations = Data::PowerSet->new({min=>$minSize}, @indices);	
	
	my %allCliques;
	
	while (my $curCombination = $combinations->next)
	{
		if (IsCombinationClique($threshold, @$curCombination))
		{
			my $numOfCliques = keys %allCliques;
			
			my $shouldAddToAllCliques = 1;
			my @keysToRemove;
				
			foreach my $key ( keys %allCliques )
			{
	    		my @curClique = @{$allCliques{$key}};
	        		
	        	my @minus = array_minus( @$curCombination, @curClique);
				my $minusSize = 0 + @minus;
					
				if ($minusSize == 0)
				{
					$shouldAddToAllCliques = 0;
				}
					
				@minus = array_minus(@curClique, @$curCombination);
				$minusSize = 0 + @minus;
				
				if ($minusSize == 0)
				{
					push (@keysToRemove, $key);
				}
			}
				
			if ($shouldAddToAllCliques)
			{
				$allCliques{$curCombination} = $curCombination;
			} 
			
			foreach my $keyToRemove (@keysToRemove)
			{
				delete $allCliques{$keyToRemove};
			}	
		}
	}
	
	if (scalar (keys %allCliques) > 0)
	{
		my $largeCluster;
		my $largeClusterSize = 0;
		my $largeClusterAvgDist = 0;
		
		print "Clusters found by Max Clique:\n";
		my @clusters;
		foreach my $curClique (values %allCliques)
		{
			my @sorted = sort {$a <=> $b} (@$curClique);
			print join("    ", @sorted);
			my $avgDist = CalculateAvgDistance (\@sorted, \@matrix);
			
			if (($largeClusterSize < 0+@sorted) || (($largeClusterSize == 0+@sorted) && ($largeClusterAvgDist < $avgDist)))
			{
				$largeCluster = \@sorted;
				$largeClusterAvgDist = $avgDist;
				$largeClusterSize = 0+@sorted;		
			}
			
			my $clusterLine = join("    ", @sorted);
			$clusterLine = $clusterLine."\t\t$avgDist\n";
			push (@clusters, $clusterLine);
		}
		
		write_file("$curJobDirectory/MaxCliqueClusters", @clusters);
			
		print "Large Cluster is:\n";
		print join ("\t", @$largeCluster);
		print "\n";
		return $largeCluster;	
	}
	else
	{
		print "No clusters was found by Max Clique.\n";
		write_file("$curJobDirectory/MaxCliqueClusters", "No clusters was found by Max Clique.\n");
		return -1;
	}
}

sub IsCombinationClique
{
	my ($threshold, @combination ) = @_;
	my $size = 0 + @combination;

	for (my $i = 0; $i < $size; $i++)
	{
		for (my $j = $i + 1; $j < $size; $j++)
		{
			my $nodeVal = $matrix[($combination[$i])][($combination[$j])];
			
			if ($nodeVal <= $threshold)
			{
				return 0;
			}	
		}
	}
	
	return 1;
}

sub MakeMatrix
{
    my @inputs = @_;
    my @matrix;
    for my $input (@inputs) {
        if ($input eq "") {
            print "it's blank\n";
        }
        else{
            push @matrix, [ split /\s+/, $input ];
        }
    }
    
    return \@matrix;
}

sub CalculateAvgDistance
{
	my ($no, $mat) = @_;
	
	my @nodes = @$no;
	my @matrix = @$mat;
	
	my $size = 0 + @nodes; 
	my $count = 0;
	my $total = 0;
	
	for (my $i = 0; $i < $size; $i++)
	{
		for (my $j = $i + 1; $j < $size; $j++)
		{
			$total += $matrix[$nodes[$i]][$nodes[$j]];
			$count++;
		}
	}
	
	my $avg = $total / $count;
	
	print "\t\tAverage distance: $avg \n";
	
	return $avg;
}

1;