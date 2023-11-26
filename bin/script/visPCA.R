#!/usr/bin/env Rscript

if (!require("ggplot2"))
{
    print("Trying to install ggplot2");
	install.packages("ggplot2",repos="http://cran.r-project.org");
}

args <- commandArgs(TRUE);
title <- args[1];
pca_num <- args[2];
eig_val <- read.table(args[3],FALSE);
raw_data <- read.table(args[4],TRUE);
variance <- as.numeric(args[5]);
maxPC <- as.numeric(args[6]);
outdir <- args[7];
libpath <- args[8];
binpath <- args[9];

.libPaths(libpath)

library(RColorBrewer)
library(ggplot2)
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

#jjcolor = c("#e6194b","#3cb44b","#ffe119","#0082c8","#f58231","#911eb4","#46f0f0","#f032e6","#d2f53c","#fabebe","#008080","#e6beff","#aa6e28","#800000","#aaffc3","#808000","#ffd8b1","#000080","#808080","#000000")
#mycol=c(brewer.pal(9,"Set1"), brewer.pal(8,"Set2"), brewer.pal(12,"Set3"))
jjcolor = ColArry;
if (maxPC > i){
    maxPC <- i;
}
pdf(file=paste0(outdir,"/all.PCA.pdf"));
for (i in 1:(maxPC-1)){
	for (j in (i+1):maxPC){
		if (i == j){break}
		df <- raw_data[c(1,(i+1),(j+1))]
		p <- ggplot(df,aes(x=df[,2],y=df[,3],group=SPC)) +
			ggtitle(paste0(title," : ",i,"-",j)) +
			#xlab(paste("PC",i,sep="")) +
			#ylab(paste("PC",j,sep="")) +
			xlab(ls_name[i]) +
			ylab(ls_name[j]) +
			scale_color_manual(values=jjcolor, name="Population") +
			theme_classic() +
			theme(plot.title = element_text(hjust = 0.5),legend.title = element_blank()) +
			geom_point(shape=1,aes(color=SPC))
		print (p);
	}
}
dev.off()

