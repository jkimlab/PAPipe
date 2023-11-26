#!/usr/bin/env Rscript

args <- commandArgs(TRUE);
f_tree <- args[1];
width <- as.numeric(args[2]); #sample count -> make width with * 0.1
outDir <- args[3];
libpath <- args[4];
.libPaths(libpath)

if (!require("phylogram"))
{
    print("Trying to install phylogram");
    install.packages("phylogram",repos="http://cran.r-project.org");
}
library("phylogram");
if (!require("qqman"))
{
    print("Trying to install qqman");
    install.packages("qqman",repos="http://cran.r-project.org");
}
library("qqman");


height = 10;
if(width < 80){
	width = 12;
}else{
	width = width * 0.2;
}
dendogram <- read.dendrogram(f_tree)
tree.pdf.file <- paste(outDir,"/snphylo_tree.pdf", sep="");
pdf(tree.pdf.file, width=width, height = height)
plot(dendogram, yaxt = "s")
garbage <- dev.off();
