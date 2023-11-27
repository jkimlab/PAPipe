# PAPipe: a comprehensive pipeline for population genetic analysis

![](./figures/fig1.png)

### Main workflow

1. Read trimming (by [Trim Galore](https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/))
2. Read mapping (by [BWA](https://bio-bwa.sourceforge.net/) or [Bowtie 2](https://bowtie-bio.sourceforge.net/bowtie2/))
3. Genetic variant calling (by [GATK3](https://gatk.broadinstitute.org/hc/en-us), [GATK4](https://gatk.broadinstitute.org/hc/en-us) or [BCFtools](https://github.com/samtools/bcftools))
4. Data filtering and format converting (by [PLINK v 1.9](https://www.cog-genomics.org/plink/))
5. Population genetic analyses
    - Principal component analysis (by [PLINK v 1.9](https://www.cog-genomics.org/plink/) or [PLINK v 2.0](https://www.cog-genomics.org/plink/2.0/))
    - Phylogenetic tree analysis (by [SNPhylo](https://github.com/thlee/SNPhylo))
    - Population tree analysis (by [TreeMix](https://bitbucket.org/nygcresearch/treemix/wiki/Home))
    - Population structure analysis (by [ADMIXTURE](https://speciationgenomics.github.io/ADMIXTURE/))
    - Linkage disequilibrium decay analysis (by [PopLDdecay](https://github.com/BGI-shenzhen/PopLDdecay/))
    - Selective sweep analysis (by [SweepFinder2](http://degiorgiogroup.fau.edu/sf2.html))
    - Population admixture analysis (by [AdmixTools](https://github.com/DReichLab/AdmixTools))
    - Pairwise sequentially Markovian coalescent analysis (by [psmc](https://github.com/lh3/psmc))
    - Multiple sequentially Markovian coalescent analysis (by [msmc2](https://github.com/stschiff/msmc2))
    - Fixation index analysis (by [VCFtools](https://vcftools.sourceforge.net/))

---

### Install a Docker Engine (Need root permission)

Skip if your machine already has the engine ([Installation document](https://docs.docker.com/engine/install/)). 

```bash
curl -fsSL https://get.docker.com/ | sudo sh
```

### Add a Docker user to the docker group (Need root permission)

Skip if your account is already added in the docker group

```bash
sudo usermod -aG docker $USER 	
```

### Install the PAPipe Docker image

```bash
wget http://bioinfo.konkuk.ac.kr/PAPipe/PAPipe.tar.gz    # Download the Docker image file
docker load -i ./PAPipe.tar.gz    # Load the Docker image file
docker image ls    # Check if the image loaded well ("REPOSITORY:pap_docker, TAG:latest" must be shown)
```

### Run PAPipe

**Setting local input directories (Caution: do not change the names and the directory structure)** 

```bash
mkdir RUN_DOCKER/
cd RUN_DOCKER/

mkdir data/
cd data/

mkdir ref/
mkdir input/
```

- Place the following two files of a reference species in `RUN_DOCKER/data/ref/`
    - Genome assembly file (gzip-compressed FASTA file with an extension .fa.gz)
    - dbSNP VCF file (gzip-compressed VCF file with an extension .vcf.gz)
      
- Place all other input data (read sequence files, read mapping files, or variant calling files) in `RUN_DOCKER/data/input/`
    - First, create separate directory for each population (one per population) in the "input" directory
    - Then, place files of each population in its directory (example below)
        - Files for Angus in `RUN_DOCKER/data/input/Angus/`
        - Files for Jersey in `RUN_DOCKER/data/input/Jersey/`

**Preparing parameter files** 

PAPipe requires the following three parameter files

- main_sample.txt: setting for populations and samples 
- main_input.txt: setting for input data files
- main_param.txt: controlling parameters for PAPipe including various tools in PAPipe

The above three files must be placed in the above "RUN_DOCKER" directory. 

You can easily generate the parameter files using our [parameter file genetator](http://bioinfo.konkuk.ac.kr/PAPipe/parameter_builder/).

Check out more details about the parameter file generator [here](./Parameters/parameter_generator.md).

**Creating a Docker container that mounts the above "RUN_DOCKER" directory** 

```bash
docker run -v [absolute path of the "RUN_DOCKER" directory]:/RUN_DOCKER/  -it pap_docker:latest
```

**Running PAPipe inside the Docker container** 

```bash
# Run in the docker container
cd /RUN_DOCKER/
python3 /PAPipe/bin/main.py  -P ./main_param.txt  -I ./main_input.txt -A ./main_sample.txt &> ./log
```

Analysis results will be generated in the output directory specified in the "main_param.txt" file. 

Check out more details about the analysis results [here](./Results/README.md).


**Generating HTML pages for browsing analysis results** 

You can check all analysis results in the output directory specified in the "main_param.txt" file. 

However, PAPipe also supports the generation of HTML pages for easily browsing the analysis results.

```bash
# Run in the docker container
perl /PAPipe/bin/webEnvSet.pl ./out &> webenvset.log    # Suppose "out" is the output directory set in the "main_param.txt" file
cd ./out/web/
perl /PAPipe/bin/html/prep_html.pl ./ &> ./webgen.log
```

After successfully running the above commands, follow the two steps below to open the HTML pages. 

- Download the entire directory of "web" into your personal computer. 
- Open the "index.html" file in the "web" directory using any web browser

If your machine supports a graphic user interface, you can directly go into the "web" directory and open the "index.html" file without downloading the "web" directory into your personal computer. 

Check out more details about the generated HTML pages [here](./Results/Result%20browser/README.md). 

### Run PAPipe with test data

You can test PAPipe using a small test data. Check out more details [here](./Tutorial/README.md). 

---

