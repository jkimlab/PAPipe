#!/usr/bin/env Rscript

args <- commandArgs(TRUE);
mu <- as.numeric(args[1])
gen <- as.numeric(args[2])
pop_cnt <- as.numeric(args[3])
outdir <- args[4]
binpath <- args[5];

data <- read.table(args[6],TRUE)
options("scipen" = -100)

load(paste0(binpath,"/col.rda"))
mycol =ColArry

pop.size <- (1/data$lambda)/(2*mu)
pop.size <- pop.size + 0.01
time <- (data$left_time_boundary/mu*gen)
time <- time + 0.001 


outfile <- paste(outdir,"/MSMC.pdf",sep="")
pdf(outfile, width = 12, height = 9)

legend_name = c();
legend_cols = c();
plot(time, pop.size, type="s", xlim =c(0.001,100000000),xlab="log Years before present",  ylab="Effective Population Size", log="x")
for (i in (6:(5+pop_cnt))){
    data <- read.table(args[i],TRUE)
    ar <- strsplit(args[i], "/")
    input_file_name <- ar[[1]][length(ar[[1]])]
    getPOPname<- strsplit(input_file_name,".", fixed=TRUE)
    thisPOP <- getPOPname[[1]][1]
	thisColIndex = i-5;

    legend_name = c(legend_name,thisPOP)
    legend_cols = c(legend_cols, mycol[thisColIndex])
    time <- (data$left_time_boundary/mu*gen)
    time <- time + 0.001 
    pop.size <- (1/data$lambda)/(2*mu)
    pop.size <- pop.size + 0.001

    
    lines(time, pop.size, type="s", col=mycol[thisColIndex])
}

legend("topright", legend=legend_name, col = legend_cols, lty=1, cex=0.8)
dev.off()

