#!/usr/bin/env Rscript

args <- commandArgs(TRUE);
title <- args[1]
pca_num <- as.numeric(args[2]);
eig_val <- read.table(args[3],FALSE);
raw_data <- read.table(args[4],FALSE);
pop_info <- read.table(args[5],FALSE);
variance <- as.numeric(args[6]);
outdir <- args[7];
libpath <- args[8];
binpath <- args[9];

.libPaths(libpath);

if (!require("ggplot2"))
{
    print("Trying to install ggplot2");
	install.packages("ggplot2",repos="http://cran.r-project.org");
}
library(ggplot2)
library(RColorBrewer)
load(paste0(binpath,"/col.rda"))


eig_val <- eig_val[1:pca_num,]
ls_cumsum <- (cumsum(eig_val)/sum(eig_val))*100
ls_PVE <- (eig_val/sum(eig_val))*100
ls_name <- vector();

for(i in 1:pca_num){
	if(ls_cumsum[i] > variance){break;}
	PVE_format = format(as.numeric(ls_PVE[i]), digits=4)
	ls_PVE[i] = PVE_format;
	name <- paste("PC",i," (",ls_PVE[i],"%)",sep="");
	ls_name[i] <- name;
}

#mycol=c(brewer.pal(9,"Set1"), brewer.pal(8,"Set2"), brewer.pal(12,"Set3"))
#jjcolor = mycol;
#jjcolor = c("#e6194b","#3cb44b","#ffe119","#0082c8","#f58231","#911eb4","#46f0f0","#f032e6","#d2f53c","#fabebe","#008080","#e6beff","#aa6e28","#800000","#aaffc3","#808000","#ffd8b1","#000080","#808080","#000000")
jjcolor = ColArry;

raw_data$pop_info = pop_info$V1

maxPC <- i;
pdf(file=paste0(outdir,"/all.PCA.pdf"));
for (i in 1:(maxPC-1)){
	for (j in (i+1):maxPC){
		if (i == j){break}
		df <- raw_data[c(pca_num+4,(i+3),(j+3))]
		p <- ggplot(df,aes(x=df[,2],y=df[,3],group=pop_info)) +
			ggtitle(paste0(title," : ",i,"-",j)) +
			#xlab(paste("PC",i,sep="")) +
			#ylab(paste("PC",j,sep="")) +
			xlab(ls_name[i]) +
			ylab(ls_name[j]) +
			scale_color_manual(values=jjcolor, name="Population") +
			theme_classic() +
			theme(plot.title = element_text(hjust = 0.5),legend.title = element_blank()) +
			geom_point(shape=1,aes(color=pop_info))
		print (p);
	}
}
dev.off()

