# Prepare the paramater files to run PAPipe

### Parameter files to prepare

---

PAPipe requires three parameter files below to execute

- `I` main.input.txt
    
    Containing main input files to analyze
    
- `S` main.sample.txt
    
    Containing sample-population information
    
- `P` main.param.txt
    
    Containing parameters and environment paths to run the PAPipe and incorporated population analyses
    

---

- By default, PAPipe is ready to receive raw paired-end reads from all individuals for population analysis.
- As PAPipe supports various analysis subsets, users can perform population analysis from their available data, including trimmed reads, read alignments, and variant calls, in addition to raw reads.
- You can configure `main.input.txt` according to user input, and similarly, `main.param.txt` should be set by the user to match the subset range they intend to analyze.
- PAPipe provides a step-by-step parameter form where you can simply fill in the content as a default.
- However, for user convenience, we have also implemented an additional parameter-builder web interface, allowing you to generate parameters more easily through this website.

---

💡 Check out our [Parameter generator webpage](http://bioinfo.konkuk.ac.kr/PAPipe/parameter_builder/) and [Documentation](./parameter_generator.md)!

---

**From raw reads or trimmed reads**

```
#### ReadMapping ####
### DNA-seq data path(input file of ReadMapping) ###
# Paired-end read pairs
# <Hanwoo_Hanwoo1> => RGSM name, format:(BreedName)_(BreedName)(Number)
# [lib1]
# Path of forward read
# path of reverse read
<Abreed_Abreed1>
[lib1]
[path to sequencing read]/[sequencing read]-1.fq.gz
[path to sequencing read]/[sequencing read]-2.fq.gz

```

**From read alignments**

```
#### VariantCalling ####
### Bam file path(input file of ReadMapping or Varaint Calling) ###
# <Hanwoo_Hanwoo1> => RGSM name (Before read grouping in ReadMapping step, format:(BreedName)_(BreedName)(Number), example : Hanwoo_Hanwoo1)
# Path of bam file
<Abreed_Abreed1>
[path to bam file]/[Abreed_Abreed1].bam
<Abreed_Abreed2>
[path to bam file]/[Abreed_Abreed2].bam

```

**From variant call data**

```
#### Postprocessing ####

### Vcf file path(input file of Postprocessing) ###
# Path of vcf file
[path to variant call VCF]/[variant call].vcf.gz

#### Population ####
# If you take the Effective size step in Population analysis, write the BAM files path ####
### Bam files path ###
# <Hanwoo_Hanwoo1> => RGSM name (Before read grouping in ReadMapping step, format:(BreedName)_(BreedName)(Number), example : Hanwoo_Hanwoo1)
# Path of BAM file
<Abreed_Abreed1>
[path to bam file]/[Abreed_Abreed1].recal.addRG.marked.sort.bam
<Abreed_Abreed2>
[path to bam file]/[Abreed_Abreed2].recal.addRG.marked.sort.ba

```

---

### main.sample.txt

[example.main.sample.txt](https://github.com/nayoung9/PAPipe/blob/main/Tutorial/main.sample.txt)

List of sample-sex-population information per single line

```
#sample sex[F, M, U, FemaleMale/U for none] population
ABreed1 U        Abreed
ABreed2 U        Abreed
BBreed1 U        Bbreed
BBreed2 U        Bbreed

```

---

### main.param.txt

Lift of required parameters for running each
[example.main.param.txt](https://github.com/nayoung9/PAPipe/blob/main/Tutorial/main.param.txt)

**Global options running PAPipe**

The parameter file should include this section for every execution.

```
#### Global ####
outdir = ./out
threads = 20
verbose = 1
memory = 10
step = 0-4
reference = /RUN_DOCKER/data/ref/cow.chr1.fa.gz
```

- step information
    - 0: Read QC
    - 1: Read alignment
    - 2: Variant calling
    - 3: Postprocessing
    - 4: Population analyses

**Running ReadQC step in PAPipe**

```
#### ReadQC ####
### Program path ###
fastqc_path  = /mss1/programs/titan/FastQC/fastqc
multiqc_path  = ~/.local/bin/multiqc
Trim_galore_path = /mss3/RDA_Phase2/programs/TrimGalore-0.6.0/trim_galore
path_to_cutadapt =  ~/.local/bin/cutadapt

tg;quality = 20
tg;length = 20
```

**Running ReadMapping step in PAPipe**

```
#### ReadMapping ####
### Program path ###
OPTION = 1
BWA = [path_to_bwa]/bwa
BOWTIE2 = [path_to_bowtie2]/bowtie2
SAMTOOLS = [path_to_samtools]/samtools
PICARD = [path_to_picard]/picard.jar
JAVA = [path_to_java]/java

### Data path ###
Reference = [path_to_reference_genome]/[...].fa

```

- **ReadMapping** option information
    - 1: Bwa
    - 2: Bowtie2

**Running VariantCalling step in PAPipe**

```
#### VariantCalling ####
### Program path ###
OPTION = 2
PICARD = [path_to_picard]/picard.jar
SAMTOOLS = [path_to_samtools]/samtools
BCFTOOLS = [path_to_bcftools]/bcftools
VCFTOOLS = [path_to_vcftools]/vcftools
GATK3.8 = [path_to_gatk3]/gatk-package-distribution-3.8-1.jar
GATK4.0 = [path_to_gatk4]/gatk
JAVA = [path_to_java]/java

### Data path ###
Reference = [path_to_reference_genome]/[...].fa
DBSNP = [path_to_dbsnp_variants]/[...].vcf.gz

### Default ###
VCF_prefix = Cows

```

- **VariantCalling** option information
    - 1: GATK3
    - 2: GATK4
    - 3: BCFtools

**Running Postprocessing step in PAPipe**

```
####               Postprocessing               ####
### Program path ###
Plink= [path_to_plink]/plink
VCFTOOLS = [path_to_vcftools]/vcftools

###             Default             ###
chr-set = [total chromosome number]
geno = 0.01
maf = 0.05
hwe = 0.000001

```

**Running PopulationAnalysis step in PAPipe**

```
#### PopulationAnalysis ####

```

- The parameters for population analysis part starts along with the header.
- User can set whether to perform the analysis or not using an ON/OFF parameter.
    1. **principal component analysis (Plink 1.9)**
        
        ```
        #### PCA ####
        ON/OFF = ON
        
        GCTA = [path_to_gcta]/gcta64
        Rlib_path = [path_to_RLib]/R_LIB/
        
        autosome-num = 30        #number of autosome used in analysis
        PCA = 20                 #number of PCs for PCA analysis
        maxPC = 5                #maximum number of PC for drawing PCA plots
        Variance = 80            #objective variance for drawing PCA plots
        PCA_title = [title]      #Title for PCA plot
        
        ```
        
    2. **PCA projection analysis (Plink 2)**
        
        ```
        #### Plink2 ####
        ON/OFF = ON
        
        vcftools = [path_to_vcftools]/vcftools
        plink2 = [path_to_plink2]/plink2
        
        autosome_cnt = 30              #number of autosome used in analysis
        non_autosome_list  = X,Y,MT    #list of not-using chromosomes deliminated by comma
        PCA = 20                       #number of PCs for PCA analysis
        maxPC = 5                      #maximum number of PC for drawing PCA plots
        Variance = 80                  #objective variance for drawing PCA plots
        PCA_title = [title]            #Title for PCA plot
        
        ```
        
    3. **Phylogenetic analysis (Snphylo)**
        
        ```
        #### Phylogenetic Tree ####
        ON/OFF = ON
        
        Snphylo = [path_to_snphylo]/snphylo.sh
        
        sampleNum = 25
        m=0
        l=0.7
        M=0.02
        
        ```
        
    4. **Treemix analysis (Treemix2)**
        
        ```
        #### Treemix####
        ON/OFF = ON
        
        vcftools_path = [path_to_vcftools]/vcftools
        bcftools_path = [path_to_bcftools]/bcftools
        treemix_path = [path_to_treemix]/src/treemix
        treemix_util_path = [path_to_treemix]/scripts/
        plink= [path_to_plink]/plink
        python2=[path_to_python2]/python
        lib_path = [path_to_RLib]/R_LIB/
        
        ldPruning_threshold = 0.1
        m = 4
        k = 2
        
        ```
        
    5. **Population structure analysis (Structure)**
        
        ```
        #### Population Structure ####
        ON/OFF = ON
        
        admixture = [path_to_admixture]/admixture
        CLUMPAK = [path_to_CLUMPAK]/CLUMPAK.pl
        
        k = 5     #number of maximum ancestor species
        
        ```
        
    6. **Linkage disequilibrium decay analysis (PopLDdecay)**
        
        ```
        #### Ld Decay ####
        ON/OFF = ON
        
        PopLDdecay_BIN = [path_to_PopLDdecay]/bin/
        
        MaxDist = 500, 1000, 5000, 10000      #The maximum distance parameter allows for one or more values, which should be delimited by commas.
        
        ```
        
    7. **Selective sweep finding analysis (SweepFinder2)**
        
        ```
        #### SweepFinder2 ####
        ON/OFF = ON
        
        plink_path = [path_to_plink]/plink
        vcftools_path = [path_to_vcftools]/vcftools
        bgzip_path = [path_to_bgzip]/bgzip
        tabix_path = [path_to_tabix]/tabix
        python_path = [path_to_python3]/python3
        sweepfinder_path = [path_to_SweepFinder2]/SweepFinder2
        
        ref_fa = [path_to_reference_genome]/[...].fa     #reference fasta
        autosome_num = 30                                #autosome number
        non_autosome_list  = X,Y,MT                      #non-autosome-list delimited by commas
        grid_size = 1000                                 #grid size
        threads = 20
        
        ```
        
    8. **Population admixture analysis (Admixtools)**
        
        ```
        #### Admixture Proportion ####
        ON/OFF = ON
        
        ADMIXTOOLS = [path_to_ADMIXTOOLS]/bin/
        
        Prefix = admixt_result
        
        ```
        
    9. **Pairwise sequentially Markovian coalescent analysis (PSMC)**
        
        ```
        #### Effective Size ####
        ON/OFF = ON
        
        VCFUTILS = [path_to_vcfutils]/vcfutils.pl
        SAMTOOLS = [path_to_samtools]/samtools
        BCFTOOLS = [path_to_bcftools]/bcftools
        PSMC_DIR = [path_to_psmc]/psmc/
        
        ### Data path ###
        Reference = [path_to_reference_genome]/[...].fa
        
        #=====================================#
        ###             Default             ###
        #=====================================#
        ## SAMTOOLS
        SAM_C = 50  # parameter for adjusting mapQ; 0 to disable [0]
        VCF_d = 10  # max per-BAM depth to avoid excessive memory usage [250]
        VCF_D = 100 # output per-sample DP in BCF
        
        ## PSMC
        # fq2psmcfa
        q = 20 # rounds of iterations
        
        # psmc
        N = 25  # maximum number of iterations [30]
        t = 15  # maximum 2N0 coalescent time [15]
        r = 5   # initial theta/rho ratio [4]
        p = "4+25*2+4+6"  # pattern of parameters [4+5*3+4]
        
        ```
        
    10. **Multiple sequentially Markovian coalescent analysis (MSMC)**
        
        ```
        #### MSMC ####
        ON/OFF = ON
        
        seqbility_bin = [path_to_MSMC_mappability]/seqbility-20091110/
        msmctools_bin = [path_to_MSMC-tools]/msmc-tools
        msmc_path = [path_to_MSMC2]/msmc2
        samtools_path = [path_to_samtools]/samtools
        bwa_path = [path_to_bwa]/bwa
        python_path = [path_to_python3]/python3
        faSize = [path_to_faSize]/faSize
        bcftools_path = [path_to_bcftools]/bcftools
        
        ref_fa = [path_to_reference_genome]/[...].fa
        threads = 20
        
        ```
        
    11. **Fixation index analysis (Fst)**
        
        ```
        #### Fst ####
        ON/OFF = ON
        
        VCFTOOLS = [path_to_vcftools]/vcftools
        
        reference_chromosome_cnt = 1
        Rlib_path = [path_to_RLib]/R_LIB/
        
        window-size = 100000            #window size
        window-step = 0                 #step of window, 0 for adjacent window is fixed
        plot-width = 10                 #width of plot
        plot-high = 6                   #height of plot
        genomewideline = 3
        
        # Optional #
        TargetComb = Angus;Hanwoo;<->Holstein;Jersey;
        
        ```