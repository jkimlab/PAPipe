#!/usr/bin/env Rscript

args <- commandArgs(TRUE);

inF <- args[1];
outF <- args[2];
visF <- args[3];
plotW <- as.integer(args[4]);
plotH <- as.integer(args[5]);
redline <- as.integer(args[6]);
color <- args[7];
libpath <- args[8];
color_arr <- strsplit(color, ",")[[1]];

inM <- read.table(inF,header=TRUE);
.libPaths(libpath)

if (!require("qqman"))
{
	print("Trying to install qqman");
	install.packages("qqman",repos="http://cran.r-project.org");
}

library("qqman");

POS <- as.integer((inM$BIN_START + inM$BIN_END)/2);
fstMean <- mean(inM$MEAN_FST);
fstSD <- sd(inM$MEAN_FST);
ZFst <- ((inM$MEAN_FST-fstMean)/fstSD);
write.table(ZFst,file=paste(outF,".ZFst",sep=""));
CHR <- inM$CHROM;
SNP <- c(1:nrow(inM));
inDF <- data.frame(SNP,CHR,POS,ZFst);
sigRegion <- inDF[(inDF$ZFst > redline),];

if (visF == "pdf") {
	pdf(paste(outF,".",visF,sep=""),width=plotW,height=plotH);
} else if (visF == "png") {
	png(paste(outF,".",visF,sep=""),width=plotW,height=plotH,units="in",res=600);
} else if (visF == "jpeg") {
	jpeg(paste(outF,".",visF,sep=""),width=plotW,height=plotH,units="in",res=600);
} else if (visF == "tiff") {
	tiff(paste(outF,".",visF,sep=""),width=plotW,height=plotH,units="in",res=600);
}

maxZfst =  as.integer(max(inDF$ZFst)) + 2;

manhattan(inDF,chr="CHR",bp="POS",p="ZFst",snp="SNP",xlab="Chr",ylab="Z(Fst)",col=color_arr, ylim=c(0,maxZfst),logp=FALSE, suggestiveline=FALSE, genomewideline=redline,cex=0.7);
par(new=T);
abline(h=0);

write.table(sigRegion,file=paste(outF,".sig.region.txt",sep=""),quote=FALSE,col.names=FALSE,row.names=FALSE,sep="\t");

dev.off();
