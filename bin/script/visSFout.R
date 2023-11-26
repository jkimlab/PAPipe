#!/usr/bin/env Rscript
library(ggplot2)
options(scipen = 999)
library(scales)

args <- commandArgs(TRUE);

pop_name <- args[1];
input_dir <- args[2];
f_size <- args[3];

chr_size <- read.table(f_size);
chr_cnt <- nrow(chr_size)
outfileName=paste0(input_dir,"/SweepFinderOut.pdf")
pdf(outfileName, width=6, height=4)
for (i in 1:chr_cnt){
    cur_chr=chr_size[i,1]
	if (substr(cur_chr,1,3) == "chr"){
		cur_chr = substr(cur_chr,4,nchar(chr))
	}
    cur_size = chr_size[i,2]
	real_sizeVec = seq(1,cur_size,length.out=8)
	formatted_sizeVec = as.integer(real_sizeVec/1000000)

    infileName=paste0(input_dir,"/",pop_name,".",cur_chr, ".SF2out");
    if (!file.exists(infileName)){next}
    cur_data <- read.table(infileName, header=TRUE)
    maintitle <- paste0(pop_name,", Chromosome ",cur_chr)
    ytitle <- "CLR"
    #xtitle <- paste0("Location(bp)\nTotal length of ",cur_chr,":",cur_size)
    xtitle <- paste0("Location (Mbp)")
    #plot(x =cur_data$location, y=cur_data$LR, main=maintitle, ylab=ytitle, xlab=xtitle)
    
    p<- ggplot(cur_data, aes(x=location, y=LR))+
        geom_point(size=0.5)+ scale_x_continuous(breaks = real_sizeVec, label = formatted_sizeVec)
    p <- p + labs(title=maintitle, y=ytitle, x=xtitle)	
    print(p)
}
dev.off()
