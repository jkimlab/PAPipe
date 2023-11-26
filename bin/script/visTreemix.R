#!/usr/bin/env Rscript


args <- commandArgs(TRUE);
prefix <- args[1]
m <- args[2]
outdir <- args[3]
bindir <- args[4]
libpath <- args[5];
.libPaths(libpath)

library(RColorBrewer)
library(R.utils)

source(paste0(bindir,"/plotting_func.R"))

outpath = paste(outdir,"/Treemix.results.pdf",sep="")

pdf(outpath)
for(edge in 0:m){
  plot_tree(cex=0.8,paste0(prefix,".",edge))
  title(paste(edge,"edges"))
}
dev.off()
