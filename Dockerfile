FROM ubuntu:18.04
MAINTAINER NYPARK

RUN apt-get update && apt-get install -y \
	curl \
	tar \ 
    perl \
    python3.6 \
    git \
    gcc \
    g++ \
    cpanminus \
    build-essential \
    pkg-config \
    libgd-dev \
    libncurses-dev \
    libghc-bzlib-dev \
    libboost-all-dev \
    build-essential \
    libz-dev \
    libtbb2 \
    openjdk-8-jdk \
    openjdk-8-jre \
    make \
    zip \
    wget \
    vim


RUN apt-get update -y && \
apt-get upgrade -y && \
apt-get dist-upgrade -y && \
apt-get install build-essential software-properties-common -y && \
apt-get install libcurl4-openssl-dev -y && \
apt-get install libssl-dev -y && \
apt-get install libbz2-dev -y && \
apt-get update -y && \
apt-get install libswitch-perl -y && \
apt-get install libsort-key-perl -y && \
apt-get install liblist-moreutils-perl -y && \
apt-get install ghostscript -y && \
apt-get install texlive-font-utils -y &&\
apt-get update -y

ENV TZ=Europe/Moscow
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get install r-base r-base-core r-recommended -y

ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH
RUN wget --quiet --no-check-certificate https://repo.anaconda.com/archive/Anaconda3-2019.03-Linux-x86_64.sh && \
		echo "45c851b7497cc14d5ca060064394569f724b67d9b5f98a926ed49b834a6bb73a *Anaconda3-2019.03-Linux-x86_64.sh" | sha256sum -c - && \
		/bin/bash /Anaconda3-2019.03-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
		rm Anaconda3-2019.03-Linux-x86_64.sh && \
		echo export PATH=$CONDA_DIR/bin:'$PATH' > /etc/profile.d/conda.sh

RUN cpanm File::Basename
RUN cpanm Parallel::ForkManager
RUN cpanm Getopt::Long
RUN cpanm FindBin
RUN cpanm List::Util
RUN cpanm POSIX
RUN cpanm Switch
RUN cpanm BioPerl
RUN cpanm IO::String
RUN cpanm Role::Tiny
RUN cpanm Sub::Quote
RUN cpanm File::Slurp

RUN cpanm List::MoreUtils
RUN cpanm PDF::API2
RUN cpanm PDF::Table
RUN cpanm PDF
RUN cpanm List::Permutor
RUN cpanm GD
RUN cpanm GD::Image
RUN cpanm GD::Graph::lines
RUN cpanm GD::Graph::Data
RUN cpanm Getopt::Std
RUN cpanm Statistics::Distributions
RUN cpanm Archive::Extract
RUN cpanm Archive::Zip
RUN cpanm Data::PowerSet
run cpanm Array::Utils

RUN conda install -c bioconda plink=1.90
RUN conda install -c bioconda gatk4=4.1.7.0
RUN conda install -c bioconda gnuplot
RUN conda install -c biobuilds gcta
RUN conda install -c bioconda admixtools
RUN conda install -c bioconda samtools=1.9
RUN conda install -c bioconda bcftools=1.9
RUN conda install -c bioconda admixture
RUN conda install -c bioconda bwa=0.7.17
RUN conda install -c bioconda bowtie2=2.3.5.1

RUN conda install -c compbiocore perl-switch
RUN conda install -c bioconda perl-sort-key
RUN conda install -c conda-forge r-ggplot2
RUN conda install -c bioconda r-qqman
RUN conda install -c bioconda bioconductor-gdsfmt
RUN conda install -c bioconda bioconductor-snprelate
RUN conda install -c conda-forge r-getopt
RUN conda install -c conda-forge r-phangorn
RUN conda install -c bioconda perl-list-moreutils

 

## mirror source and install R packages 
RUN mkdir -p /PAPipe/
COPY bin /PAPipe/bin/
RUN chmod -R 770 /PAPipe/*

## mirror programs
RUN mkdir -p /PAPipe/Programs/
COPY Programs /PAPipe/Programs/
WORKDIR /PAPipe/Programs/

#install picard 2.17.11
WORKDIR /PAPipe/Programs/
RUN wget https://anaconda.org/bioconda/picard/2.17.11/download/linux-64/picard-2.17.11-py36_0.tar.bz2
RUN tar -xvf picard-2.17.11-py36_0.tar.bz2
WORKDIR /PAPipe/Programs/share/picard-2.17.11-0/


## install psmc
WORKDIR /PAPipe/Programs/
RUN git clone https://github.com/lh3/psmc
WORKDIR /PAPipe/Programs/psmc/utils/
RUN make
WORKDIR /PAPipe/Programs/psmc/
RUN make
WORKDIR /PAPipe/Programs/psmc/
RUN wget https://sourceforge.net/projects/samtools/files/samtools/0.1.19/samtools-0.1.19.tar.bz2
RUN tar -xvf samtools-0.1.19.tar.bz2
WORKDIR /PAPipe/Programs/psmc/samtools-0.1.19/
RUN make


##install vcftools
WORKDIR /PAPipe/Programs/
RUN git clone https://github.com/vcftools/vcftools.git
WORKDIR /PAPipe/Programs/vcftools/
RUN ./autogen.sh
RUN ./configure
RUN make
RUN make install

##install popLDdecay
WORKDIR /PAPipe/Programs/
RUN git clone https://github.com/BGI-shenzhen/PopLDdecay.git 
WORKDIR /PAPipe/Programs/PopLDdecay/
RUN chmod 755 configure
RUN ./configure
RUN make
RUN mv PopLDdecay bin/
WORKDIR /PAPipe/Programs/

##install snphylo
RUN conda install -c bioconda muscle
RUN apt-get install phylip -y 

##install gatk3
WORKDIR /PAPipe/Programs/
RUN mkdir gatk3.8/
WORKDIR /PAPipe/Programs/gatk3.8
RUN wget  https://anaconda.org/bioconda/gatk/3.8/download/noarch/gatk-3.8-hdfd78af_11.tar.bz2
RUN tar -xvf gatk-3.8-hdfd78af_11.tar.bz2
WORKDIR /PAPipe/Programs/


## Set CLUMPAK
WORKDIR /PAPipe/Programs/CLUMPAK/26_03_2015_CLUMPAK/CLUMPAK/
RUN chmod 755 CLUMPAK.pl

WORKDIR /

#updated 1102
RUN conda install -c bioconda perl-parallel-forkmanager
RUN cp /PAPipe/Programs/admixtools/convertf  /opt/conda/bin/

#ENV set 
RUN mkdir -p /anaconda/envs/_build/share/gnuplot/
RUN ln -s /opt/conda/share/gnuplot/5.0/ /anaconda/envs/_build/share/gnuplot/

