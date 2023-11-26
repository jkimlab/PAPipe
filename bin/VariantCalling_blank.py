import os
import re
import sys
import argparse
from collections import defaultdict

import subprocess as sub
from time import sleep
from multiprocessing import Pool

import Param

###########################
### Variable Definition ###
###########################
## Program Variable
STATE = 0
PICARD = ""
BCFTOOLS = ""
VCFTOOLS = ""
SAMTOOLS = ""
VariantTool = ""
## Data Variable
REFERENCE = ""
DBSNP = ""
## Sample Variable
VCF_prefix = ""
## Option Variable
localrealn_option_line = ""
indelrealn_targetcreator_option_line = ""
indelrealn_option_line = ""
baserecal_option_line = ""
baserecal_printreads_option_line = ""
baserecal_applybqsr_option_line = ""
variantcalling_option_line = ""
variantfilt_option_line = ""
filterExpression = ""

def tree() : 
    return defaultdict(tree)

SAMPLE_DATA = tree()

def multi_run_wrapper(args) :
    return f(*args)

def f(x, log) :
    with open(log, 'w') as outfile :
        value = sub.call(x, shell=True, stdout = outfile, stderr = outfile)
    return value

def config() :
    parser = argparse.ArgumentParser(description = "Variant Calling")
    parser.add_argument('-P', '--param', help='<Path> Parameter file', required = True)
    parser.add_argument('-O', '--out_dir', default = ".", help='<Path> Output directory', required = False)
    parser.add_argument('-@', '--threads', default = 10, help='<Int> Number ot threads (default 10)', required = False)
    parser.add_argument('-M', '--memory', default = 10, help='<Int> Memory (default 10)', required = False)
    parser.add_argument('-J', '--job', default = 1, help='<Int> Number of parallel jobs (default 1)', required = False)
    parser.add_argument('-V', '--verbose', default=0, help='<Int> If you want to see the command line, set 1 (default 0', required = False)
    args = parser.parse_args()

    return args

def param_file(param) :
    global STATE
    global PICARD
    global BCFTOOLS
    global VCFTOOLS
    global SAMTOOLS
    global VariantTool

    global REFERENCE
    global DBSNP
    global VCF_prefix
    global SAMPLE_DATA

    global localrealn_option_line
    global indelrealn_targetcreator_option_line
    global indelrealn_option_line
    global baserecal_option_line
    global baserecal_printreads_option_line
    global baserecal_applybqsr_option_line
    global variantcalling_option_line
    global variantfilt_option_line
    global filterExpression

    SAMPLE_NAME = ""
    sample_cnt = 0
    option = 0

    for line in open(param, 'r') :
        line = line.strip()
        if re.match(r'^\s*$', line) :
            continue
        if line.startswith("#") :
            continue
        elif line.startswith("<") :
            sample_cnt += 1
            SAMPLE_NAME = line[1:len(line)-1].strip()
        else :
            if sample_cnt >= 1 :
                SAMPLE_DATA[SAMPLE_NAME] = os.path.abspath(line)
            
            else :
                match = ((line.split('='))[0]).strip()
                path = ((line.split('='))[1]).strip()
                if match == "VCF_prefix" :
                    VCF_prefix = path
                elif match == "OPTION" :
                    STATE = path
                    STATE = int(STATE)
                elif match == "PICARD" :
                    PICARD = path
                elif match == "SAMTOOLS" :
                    SAMTOOLS = path
                elif match == "BCFTOOLS" :
                    BCFTOOLS = path
                elif match == "VCFTOOLS" :
                    VCFTOOLS = path
                elif match == "GATK3.8" or match == "GATK4.0" :
                    if STATE == 1 and match == "GATK3.8":
                        VariantTool = path
                    elif STATE == 2 and match == "GATK4.0" :
                        VariantTool = path
                elif match == "Reference" :
                    REFERENCE = path
                elif match == "DBSNP" :
                    DBSNP = path
                elif match == "localrealn_option_line" :
                    localrealn_option_line = path + " "
                elif match == "indelrealn_targetcreator_option_line" :
                    indelrealn_targetcreator_option_line = path + " "
                elif match == "indelrealn_option_line" :
                    indelrealn_option_line = path + " "
                elif match == "baserecal_option_line" :
                    baserecal_option_line = path + " "
                elif match == "baserecal_printreads_option_line" :
                    baserecal_printreads_option_line = path + " "
                elif match == "baserecal_applybqsr_option_line" :
                    baserecal_applybqsr_option_line = path + " "
                elif match == "variantcalling_option_line" :
                    variantcalling_option_line = path + " "
                elif match == "variantfilt_option_line" :
                    variantfilt_option_line = path + " "
                elif match == "filterExpression" :
                    if path == "default" :
                        filterExpression = "\"QD<2.0||MQ<40.0||FS>60.0||MQRankSum<-12.5||ReadPosRankSum<-8.0\""
                    else :
                        filterExpression = "\"" + path + "\""


def ParseInput(input_, out) :

    sample, flag = "", 0
    for line in open(input_, 'r') :
        line = line.strip()
        if re.match(r'\s*$', line) :
            continue
        elif line.startswith('####') :
            step = (line.replace('####', '')).strip()
            if not step == "VariantCalling" :
                sys.stderr.write("Require the VariantCalling input file\n")
                sys.stderr.flush()
                sys.exit()
        elif line.startswith('<') :
            sample = (line.replace('<', '').replace('>', '')).strip()
            flag += 1
        elif not line.startswith('#') :
            if flag >= 1 :
                sub.call(f'mkdir -p {out}/01_ReadMapping/04.ReadRegrouping', shell=True)
                sub.call(f'ln -s {line} {out}/01_ReadMapping/04.ReadRegrouping/{sample}.bam', shell=True)

                        
def Indexing(out, th, verbose) :
    global PICARD
    global SAMTOOLS
    global VariantTool

    global REFERENCE
    global DBSNP

    global STATE
    CMD = []
    
    sys.stderr.write("\n\nIndexing\n")
    sys.stderr.flush()
    #if os.path.isdir(out + "/02_VariantCalling/REF") :
    #    sub.call(f'rm -rf {out}/02_VariantCalling/REF', shell=True)
    #sub.call(f'mkdir -p {out}/02_VariantCalling/REF', shell=True)
    #sub.call(f'mkdir -p {out}/02_VariantCalling/logs/REF', shell=True)

    ref_basename = os.path.basename(REFERENCE)
    sub.call(f'ln -s {REFERENCE} {out}/02_VariantCalling/REF/', shell=True)
    REFERENCE = out + "/02_VariantCalling/REF/" + ref_basename

    line = SAMTOOLS + " faidx " + out + "/02_VariantCalling/REF/" + ref_basename
    log = out + "/02_VariantCalling/logs/REF/ref.index.log"
    CMD.append([line, log])   
    if verbose == "1" :
        sys.stderr.write(line + " &> " + log + "\n")
        sys.stderr.flush()
    '''

    value = sub.call(f'{line} &> {log}', shell=True)
    if not value == 0 :
        sys.stderr.write("[ERROR] Check the log file : " + out + "/02_VariantCalling/logs/REF/ref.index.log\n")
        sys.stderr.flush()
        sys.exit()
    '''

    line = "java -jar " + PICARD + " CreateSequenceDictionary R=" + out + "/02_VariantCalling/REF/" + ref_basename + " O=" + out + "/02_VariantCalling/REF/" + ref_basename.replace(".fa", ".dict")
    log = out + "/02_VariantCalling/logs/REF/ref.dict.log"
    CMD.append([line, log])   
    if verbose == "1" : 
        sys.stderr.write(line + " &> " + log + "\n")
        sys.stderr.flush()
    '''

    value = sub.call(f'{line} &> {log}', shell=True)
    if not value == 0 :
        sys.stderr.write("[ERROR] Check the log file : " + out + "/02_VariantCalling/logs/REF/ref.dict.log\n")
        sys.stderr.flush()
        sys.exit()
    '''
    if not DBSNP == "" :
        dbsnp_basename = os.path.basename(DBSNP)
        sub.call(f'ln -s {DBSNP} {out}/02_VariantCalling/REF/', shell=True)
        DBSNP = out + "/02_VariantCalling/REF/" + dbsnp_basename

        if STATE == 1 :
            line = "tabix -p vcf " + out + "/02_VariantCalling/REF/" + dbsnp_basename
            log = out + "/02_VariantCalling/logs/REF/dbsnp.index.log"
            CMD.append([line, log])   
            if verbose == "1" :
                sys.stderr.write(line + " &> " + log + "\n")
                sys.stderr.flush()
            #next
        elif STATE == 2 :
            line = VariantTool + " IndexFeatureFile -I " + out + "/02_VariantCalling/REF/" + dbsnp_basename
            log = out + "/02_VariantCalling/logs/REF/dbsnp.index.log"
            CMD.append([line, log])   
            if verbose == "1" :
                sys.stderr.write(line + " &> " + log + "\n")
                sys.stderr.flush()
            
            '''
            value = sub.call(f'{line} &> {log}', shell=True)
            if not value == 0 :
                sys.stderr.write("[ERROR] Check the log file : " + out + "/02_VariantCalling/logs/REF/dbsnp.index.log\n")
                sys.stderr.flush()
                sys.exit()
            '''
        else :
            sys.stderr.write("If you have a dbsnp file, it is recommended to use the gatk tool.\n")
            sys.stderr.flush()
    
    
    '''
    with Pool(int(th)) as p :
        value = p.map(multi_run_wrapper, CMD)
        check = 0
        for i in range(len(value)) :
            if not value[i] == 0 :
                check += 1
                sys.stderr.write("[ERROR] Check the log file : " + (CMD[i])[1] + "\n")
                sys.stderr.flush()
        if not check == 0 :
            sys.exit()
    ''' 

   

def LocalRealignment(out, th, memory, job, verbose) :
    global PICARD
    global SAMTOOLS

    global REFERENCE
    global SAMPLE_DATA
    global localrealn_option_line

    sample_name = list(SAMPLE_DATA.keys())
    CMD = []
    index_cmd = [] 

    sys.stderr.write("\n\n#01.LocalRealignment\n")
    sys.stderr.flush()
    if not os.path.isdir(out + "/02_VariantCalling/01.LocalRealignment") :
        sub.call(f'mkdir {out}/02_VariantCalling/01.LocalRealignment', shell=True)
    if not os.path.isdir(out + "/02_VariantCalling/logs/01.LocalRealignment") :
        sub.call(f'mkdir {out}/02_VariantCalling/logs/01.LocalRealignment', shell=True)

    log = ""
    for i,j in SAMPLE_DATA.items() :
        line = "java -Xmx" + str(memory) + "g -jar " + PICARD + " ReorderSam " + localrealn_option_line + "INPUT=" + j + " OUTPUT=" + out + "/02_VariantCalling/01.LocalRealignment/" + i + ".reorder.addRG.marked.sort.bam REFERENCE=" + REFERENCE
        log = out + "/02_VariantCalling/logs/01.LocalRealignment/" + i + ".reorder.log"
        CMD.append([line, log])   
        if verbose == "1" :
            sys.stderr.write(line + " &> " + log + "\n")
            sys.stderr.flush()

    with Pool(int(job)) as p :
        value = p.map(multi_run_wrapper, CMD)
        check = 0
        for i in range(len(value)) :
            if not value[i] == 0 :
                check += 1
                sys.stderr.write("[ERROR] Check the log file : " + (CMD[i])[1] + "\n")
                sys.stderr.flush()
        if not check == 0 :
            sys.exit()

    log = ""
    index_cmd = list()
    for i in SAMPLE_DATA.keys() :
        line = SAMTOOLS + " index -@ "+th+" "+ out + "/02_VariantCalling/01.LocalRealignment/" + i + ".reorder.addRG.marked.sort.bam " + out + "/02_VariantCalling/01.LocalRealignment/" + i + ".reorder.addRG.marked.sort.bam.bai"
        log = out + "/02_VariantCalling/logs/01.LocalRealignment/" + i + ".index.log"
        index_cmd.append([line, log])
        if verbose == "1" :
            sys.stderr.write(line + " &> " + log + "\n")
            sys.stderr.flush()

    with Pool(1) as p :
        value = p.map(multi_run_wrapper, index_cmd)
        check = 0
        for i in range(len(value)) :
            if not value[i] == 0 :
                check += 1
                sys.stderr.write("[ERROR] Check the log file : " + (index_cmd[i])[1] + "\n")
                sys.stderr.flush()
        if not check == 0 :
            sys.exit()


def IndelRealignment(out, th, memory, job, verbose) :
    global VariantTool

    global REFERENCE
    global DBSNP
    global SAMPLE_DATA

    global indelrealn_targetcreator_option_line
    global indelrealn_option_line
    sample_name = list(SAMPLE_DATA.keys())
    CMD = list()

    sys.stderr.write("\n\n#02.IndelRealignment\n")
    sys.stderr.flush()
    if not os.path.isdir(out + "/02_VariantCalling/02.IndelRealignment") :
        sub.call(f'mkdir {out}/02_VariantCalling/02.IndelRealignment', shell=True)
    if not os.path.isdir(out + "/02_VariantCalling/logs/02.IndelRealignment") :
        sub.call(f'mkdir {out}/02_VariantCalling/logs/02.IndelRealignment', shell=True)

    sys.stderr.write("##Creating re-alignment targets\n")
    sys.stderr.flush()
    for i,j in SAMPLE_DATA.items() :
        line = ""
        log = ""
        line = "java -Xmx" + str(memory) + "g -jar " + VariantTool + " -T RealignerTargetCreator " + indelrealn_targetcreator_option_line + "-nt " + str(th) + " -R " + REFERENCE + " -I " + out + "/02_VariantCalling/01.LocalRealignment/" + i + ".reorder.addRG.marked.sort.bam -o " + out + "/02_VariantCalling/02.IndelRealignment/" + i + ".intervals -known " + DBSNP
        log = out + "/02_VariantCalling/logs/02.IndelRealignment/" + i + ".targetcreator.log"
        CMD.append([line, log])
        if verbose == "1" :
            sys.stderr.write(line + " &> " + log + "\n")
            sys.stderr.flush()
    
    error_log = list()
    error_sample = list()
    
    with Pool(1) as p :
        value = p.map(multi_run_wrapper, CMD)
        check = 0
        for i in range(len(value)) :
            if not value[i] == 0 :
                check += 1
                grep = "grep \"appears to be using the wrong encoding for quality scores\" " + (CMD[i])[1]
                if len(os.popen(grep).read()) > 0 :
                    error_sample.append(sample_name[i])
                else :
                    sys.stderr.write("[ERROR] Check the log file : " + (CMD[i])[1] + "\n")
                    sys.stderr.flush()

    if len(error_sample) > 0 :
        sys.stderr.write("\nErrors about misencoded quality scores\n\n")
        sys.stderr.flush()
    new_cmd = list()
    for i in error_sample :
        tmp_line = "java -Xmx" + str(memory) +"g -jar " + VariantTool + " -T RealignerTargetCreator " + indelrealn_targetcreator_option_line + "--fix_misencoded_quality_scores -nt " + str(th) + " -R " + REFERENCE + " -I " + out + "/02_VariantCalling/01.LocalRealignment/" + i + ".reorder.addRG.marked.sort.bam -o " + out + "/02_VariantCalling/02.IndelRealignment/" + i + ".intervals -known " + DBSNP
        tmp_log = out + "/02_VariantCalling/logs/02.IndelRealignment/" + i + ".targetcreator2.log"
        new_cmd.append([tmp_line, tmp_log])
        if verbose == "1" :
            sys.stderr.write(tmp_line + " &> " + log + "\n")
            sys.stderr.flush()
    with Pool(1) as p :
        value = p.map(multi_run_wrapper, new_cmd)
        check = 0 
        for i in range(len(value)) :
            if not value[i] == 0 :
                check += 1
                sys.stderr.write("[ERROR] Check the log file : " + (new_cmd[i])[1] + "\n")
                sys.stderr.flush()


    CMD.clear()
    sys.stderr.write("##Re-aligning targets\n")
    sys.stderr.flush()
    for i,j in SAMPLE_DATA.items() :
        line = ""
        log = ""
        if i in error_sample :
            line = "java -Xmx" + str(memory) + "g -jar " + VariantTool + " -T IndelRealigner " + indelrealn_option_line + "  --fix_misencoded_quality_scores -R " + REFERENCE + " -targetIntervals " + out + "/02_VariantCalling/02.IndelRealignment/" + i + ".intervals -I " + out + "/02_VariantCalling/01.LocalRealignment/" + i + ".reorder.addRG.marked.sort.bam -o " + out + "/02_VariantCalling/02.IndelRealignment/" + i + ".realn.reorder.addRG.marked.sort.bam"
            log = out + "/02_VariantCalling/logs/02.IndelRealignment/" + i + ".realn.log"
        else :
            line = "java -Xmx" + str(memory) + "g -jar " + VariantTool + " -T IndelRealigner " + indelrealn_option_line + "  -R " + REFERENCE + " -targetIntervals " + out + "/02_VariantCalling/02.IndelRealignment/" + i + ".intervals -I " + out + "/02_VariantCalling/01.LocalRealignment/" + i + ".reorder.addRG.marked.sort.bam -o " + out + "/02_VariantCalling/02.IndelRealignment/" + i + ".realn.reorder.addRG.marked.sort.bam"
            log = out + "/02_VariantCalling/logs/02.IndelRealignment/" + i + ".realn.log"
        CMD.append([line, log])
        if verbose == "1" :
            sys.stderr.write(line + " &> " + log + "\n")
            sys.stderr.flush()
    with Pool(int(th)) as p :
        value = p.map(multi_run_wrapper, CMD)
        check = 0
        for i in range(len(value)) :
            if not value[i] == 0 :
                check += 1
                sys.stderr.write("[ERROR] Check the log file : " + (CMD[i])[1] + "\n")
                sys.stderr.flush()
        if not check == 0 :
            sys.exit()


def BaseRecalibration(out, th, memory, job, verbose) :
    global STATE
    global VariantTool

    global REFERENCE
    global DBSNP
    global VCF_prefix
    global SAMPLE_DATA

    global baserecal_option_line
    global baserecal_printreads_option_line
    global baserecal_applybqsr_option_line
    sample_name = list(SAMPLE_DATA.keys())
    CMD = list()
    
    if STATE == 1 :
        sys.stderr.write("\n\n#03.BaseRecalibration\n")
        sys.stderr.flush()
        if not os.path.isdir(out + "/02_VariantCalling/03.Recalibration") :
            sub.call(f'mkdir {out}/02_VariantCalling/03.Recalibration', shell=True)
        if not os.path.isdir(out + "/02_VariantCalling/logs/03.Recalibration") :
            sub.call(f'mkdir {out}/02_VariantCalling/logs/03.Recalibration', shell=True)

        for i, j in SAMPLE_DATA.items() :
            line = ""
            log = ""
            line = "java -Xmx4g -jar " + VariantTool + " -T BaseRecalibrator " + baserecal_option_line + "-nct " + str(th) + " -R " + REFERENCE + " -I " + out + "/02_VariantCalling/02.IndelRealignment/" + i + ".realn.reorder.addRG.marked.sort.bam -knownSites " + DBSNP + " -o " + out + "/02_VariantCalling/03.Recalibration/" + i + ".table"
            log = out + "/02_VariantCalling/logs/03.Recalibration/" + i + ".table.log"
            CMD.append([line, log])
            if verbose == "1" :
                sys.stderr.write(line + " &> " + log + "\n")
                sys.stderr.flush()
        
        with Pool(1) as p :
            value = p.map(multi_run_wrapper, CMD)
            check = 0
            for i in range(len(value)) :
                if not value[i] == 0 :
                    check += 1
                    sys.stderr.write("[ERROR] Check the log file : " + (CMD[i])[1] + "\n")
                    sys.stderr.flush()
            if not check == 0 :
                sys.exit()

        CMD.clear()
        for i, j in SAMPLE_DATA.items() :
            ling = ""
            log = ""
            line = "java -Xmx4g -jar " + VariantTool + " -T PrintReads " + baserecal_printreads_option_line + "-nct " + str(th) + " -R " + REFERENCE + " -I " + out + "/02_VariantCalling/02.IndelRealignment/" + i + ".realn.reorder.addRG.marked.sort.bam -BQSR " + out + "/02_VariantCalling/03.Recalibration/" + i + ".table -o " + out + "/02_VariantCalling/03.Recalibration/" + i + ".recal,realn.reorder.addRG.marked.sort.bam"
            log = out + "/02_VariantCalling/logs/03.Recalibration/" + i + ".recal.log"
            CMD.append([line, log])
            if verbose == "1" :
                sys.stderr.write(line + " &> " + log + "\n")
                sys.stderr.flush()
        
        with Pool(1) as p :
            value = p.map(multi_run_wrapper, CMD)
            check = 0
            for i in range(len(value)) :
                if not value[i] == 0 :
                    check += 1
                    sys.stderr.write("[ERROR] Check the log file : " + (CMD[i])[1] + "\n")
                    sys.stderr.flush()
            if not check == 0 :
                sys.exit()


    elif STATE == 2 :
        sys.stderr.write("\n\n#01.BaseRecalibration\n")
        sys.stderr.flush()
        if not os.path.isdir(out + "/02_VariantCalling/01.BaseRecalibration") :
            sub.call(f'mkdir {out}/02_VariantCalling/01.BaseRecalibration', shell=True)
        if not os.path.isdir(out + "/02_VariantCalling/logs/01.BaseRecalibration") :
            sub.call(f'mkdir {out}/02_VariantCalling/logs/01.BaseRecalibration', shell=True)

        CMD.clear()
        for i, j in SAMPLE_DATA.items() :
            line = ""
            log = ""
            line = VariantTool + " BaseRecalibrator   --java-options '-DGATK_STACKTRACE_ON_USER_EXCEPTION=true' " + baserecal_option_line + "-I " + j + " -R " + REFERENCE + " --known-sites " + DBSNP + " -O " + out + "/02_VariantCalling/01.BaseRecalibration/" + i + ".table"
            log = out + "/02_VariantCalling/logs/01.BaseRecalibration/" + i + ".table.log"
            CMD.append([line, log])
            if verbose == "1" :
                sys.stderr.write(line + " &> " + log + "\n")
                sys.stderr.flush()

        with Pool(int(th)) as p :
            value = p.map(multi_run_wrapper, CMD)
            check = 0
            for i in range(len(value)) :
                if not value[i] == 0 :
                    check += 1
                    sys.stderr.write("[ERROR] Check the log file : " + (CMD[i])[1] + "\n")
                    sys.stderr.flush()
            if not check == 0 :
                sys.exit()

        CMD.clear()
        for i,j in SAMPLE_DATA.items() :
            line = ""
            log = ""
            line = VariantTool + " ApplyBQSR " + baserecal_applybqsr_option_line + "-I " + j + " --bqsr-recal-file " + out + "/02_VariantCalling/01.BaseRecalibration/" + i + ".table -O " + out + "/02_VariantCalling/01.BaseRecalibration/" + i + ".recal.addRG.marked.sort.bam"
            log = out + "/02_VariantCalling/logs/01.BaseRecalibration/" + i + ".apply.log"
            CMD.append([line, log])
            if verbose == "1" :
                sys.stderr.write(line + " &> " + log + "\n")
                sys.stderr.flush()

        with Pool(int(th)) as p :
            value = p.map(multi_run_wrapper, CMD)
            check = 0
            for i in range(len(value)) :
                if not value[i] == 0 :
                    check += 1
                    sys.stderr.write("[ERROR] Check the log file : " + (CMD[i])[1] + "\n")
                    sys.stderr.flush()
            if not check == 0 :
                sys.exit()


def GatkVariantcalling(out, th, memory, job, verbose) :
    global STATE
    global VCF_prefix
    global VariantTool

    global REFERENCE
    global DBSNP
    global SAMPLE_DATA

    global variantcalling_option_line
    sample_name = list(SAMPLE_DATA.keys())
    CMD = list()

    if STATE == 1 :
        sys.stderr.write("\n\n#Variant Calling\n")
        sys.stderr.flush()
        gvcf_list = ""

        if not os.path.isdir(out + "/02_VariantCalling/VariantCalling") :
            sub.call(f'mkdir {out}/02_VariantCalling/VariantCalling', shell=True)
        if not os.path.isdir(out + "/02_VariantCalling/logs/VariantCalling") :
            sub.call(f'mkdir {out}/02_VariantCalling/logs/VariantCalling', shell=True)

        for i, j in SAMPLE_DATA.items() :
            line, log = "", ""
            line = "java -Xmx" + str(memory) + "g -jar " + VariantTool + " -T HaplotypeCaller " + variantcalling_option_line + "-nct " + str(th) + " -R " + REFERENCE + " -I " + out + "/02_VariantCalling/03.Recalibration/" + i + ".recal,realn.reorder.addRG.marked.sort.bam -o " + out + "/02_VariantCalling/VariantCalling/" + i + ".variant.g.vcf -ERC GVCF -variant_index_type LINEAR -variant_index_parameter 128000"
            log = out + "/02_VariantCalling/logs/VariantCalling/" + i + ".variant.log"
            gvcf_list += " --variant " + out + "/02_VariantCalling/VariantCalling/" + i + ".variant.g.vcf";
            CMD.append([line, log])
            if verbose == "1" :
                sys.stderr.write(line + " &> " + log + "\n")
                sys.stderr.flush()

        with Pool(1) as p :
            value = p.map(multi_run_wrapper, CMD)
            check = 0
            for i in range(len(value)) :
                if not value[i] == 0 :
                    check += 1
                    sys.stderr.write("[ERROR] Check the log file : " + (CMD[i])[1] + "\n")
                    sys.stderr.flush()
            if not check == 0 :
                sys.exit()

        ##Combine gvcf
        sys.stderr.write("\n\nCombine GVCFs\n")
        sys.stderr.flush()
        CMD.clear()
        line, log = "", ""
        line = "java -Xmx" + str(memory) + "g -jar " + VariantTool + " -T CombineGVCFs -R " + REFERENCE + gvcf_list + " --out " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.gvcf"
        log = out + "/02_VariantCalling/logs/VariantCalling/" + VCF_prefix + ".combineGVCFs.log"
        CMD.append([line, log])
        
        if verbose == "1" :
            sys.stderr.write(line + " &> " + log + "\n")
            sys.stderr.flush()
        
        with Pool(1) as p :
            value = p.map(multi_run_wrapper, CMD)
            if not 0 in value :
                sys.stderr.write("[ERROR] Check the log file : " + (CMD[0])[1] + "\n")
                sys.stderr.flush()
                sys.exit()
        
        ##Genotyping
        sys.stderr.write("\n\nGenotype GVCFs\n")
        sys.stderr.flush()
        CMD.clear()
        line, log = "", ""
        if DBSNP == "" :
            line = "java -Xmx4g -jar " + VariantTool + " -T GenotypeGVCFs -R " + REFERENCE + " --variant " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.gvcf --out " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.GT.vcf"
            log = out + "/02_VariantCalling/logs/VariantCalling/" + VCF_prefix + ".genotypeGVCFs.log"
        else :
            line = "java -Xmx4g -jar " + VariantTool + " -T GenotypeGVCFs -R " + REFERENCE + " --dbsnp " + DBSNP + " --variant " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.gvcf --out " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.GT.vcf"
            log = out + "/02_VariantCalling/logs/VariantCalling/" + VCF_prefix + ".genotypeGVCFs.log"
        CMD.append([line, log])
        
        if verbose == "1" :
            sys.stderr.write(line + " &> " + log + "\n")
            sys.stderr.flush()

        with Pool(1) as p :
            value = p.map(multi_run_wrapper, CMD)
            if not 0 in value :
                sys.stderr.write("[ERROR] Check the log file : " + (CMD[0])[1] + "\n")
                sys.stderr.flush()
                sys.exit()
        
        ##Variant Selection
        sys.stderr.write("\n\nVariant Selection\n")
        sys.stderr.flush()
        CMD.clear()
        line, log = "", ""
        line = "java -Xmx4g -jar " + VariantTool + " -T SelectVariants -R " + REFERENCE + " --variant " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.GT.vcf -selectType SNP -o " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.GT.SNP.vcf"
        log = out + "/02_VariantCalling/logs/VariantCalling/" + VCF_prefix + ".selectVariant.log"
        CMD.append([line, log])

        if verbose == "1" :
            sys.stderr.write(line + " &> " + log + "\n")
            sys.stderr.flush()

        with Pool(1) as p :
            value = p.map(multi_run_wrapper, CMD)
            if not 0 in value :
                sys.stderr.write("[ERROR] Check the log file : " + (CMD[0])[1] + "\n")
                sys.stderr.flush()
                sys.exit()


    elif STATE == 2 :
        sys.stderr.write("\n\n#Variant Calling\n")
        sys.stderr.flush()
        gvcf_list = ""

        if not os.path.isdir(out + "/02_VariantCalling/VariantCalling") :
            sub.call(f'mkdir {out}/02_VariantCalling/VariantCalling', shell=True)
        if not os.path.isdir(out + "/02_VariantCalling/logs/VariantCalling") :
            sub.call(f'mkdir {out}/02_VariantCalling/logs/VariantCalling', shell=True)

        CMD = list()
        for i,j in sorted(SAMPLE_DATA.items()) :
            line, log = "", ""
            line = VariantTool + " --java-options \"-Xmx" + str(memory) + "g\" HaplotypeCaller --native-pair-hmm-threads  "+th+" " + variantcalling_option_line + "-R " + REFERENCE + " -I " + out + "/02_VariantCalling/01.BaseRecalibration/" + i + ".recal.addRG.marked.sort.bam -O " + out + "/02_VariantCalling/VariantCalling/" + i + ".variant.g.vcf.gz -ERC GVCF"
            log = out + "/02_VariantCalling/logs/VariantCalling/" + i + ".variant.log"
            gvcf_list += " --variant " + out + "/02_VariantCalling/VariantCalling/" + i + ".variant.g.vcf.gz"
            CMD.append([line, log])
            if verbose == "1" :
                sys.stderr.write(line + " &> " + log + "\n")
                sys.stderr.flush()

        with Pool(1) as p :
            value = p.map(multi_run_wrapper, CMD)
            check = 0
            for i in range(len(value)) :
                if not value[i] == 0 :
                    check += 1
                    sys.stderr.write("[ERROR] Check the log file : " + (CMD[0])[1] + "\n")
                    sys.stderr.flush()
            if not check == 0 :
                sys.exit()

        #Combine GVCF
        sys.stderr.write("\n\nCombine GVCFs\n")
        sys.stderr.flush()
        
        CMD.clear()
        line = VariantTool + " --java-options \"-Xmx10g\" CombineGVCFs -R " + REFERENCE + gvcf_list + " -O " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.g.vcf.gz"
        log = out + "/02_VariantCalling/logs/VariantCalling/" + VCF_prefix + ".combineGVCFs.log"
        CMD.append([line, log])

        if verbose == "1" :
            sys.stderr.write(line + " &> " + log + "\n")
            sys.stderr.flush()

        with Pool(1) as p :
            value = p.map(multi_run_wrapper, CMD)
            if not 0 in value :
                sys.stderr.write("[ERROR] Check the log file : " + (CMD[0])[1] + "\n")
                sys.stderr.flush()
                sys.exit()

        #Genotyping
        sys.stderr.write("\n\nGenotype GVCF\n")
        sys.stderr.flush()
        
        CMD.clear()
        line, log = "", ""
        if DBSNP == "" :
            line = VariantTool + " --java-options \"-Xmx10g\" GenotypeGVCFs -R " + REFERENCE + " -V " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.g.vcf.gz -O " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.GT.vcf.gz"
            log = out + "/02_VariantCalling/logs/VariantCalling/" + VCF_prefix + ".genotypeGVCFs.log"
        else :
            line = VariantTool + " --java-options \"-Xmx10g\" GenotypeGVCFs -R " + REFERENCE + " --dbsnp " + DBSNP + " -V " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.g.vcf.gz -O " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.GT.vcf.gz"
            log = out + "/02_VariantCalling/logs/VariantCalling/" + VCF_prefix + ".genotypeGVCFs.log"
        CMD.append([line, log])

        if verbose == "1" :
            sys.stderr.write(line + " &> " + log + "\n")
            sys.stderr.flush()

        with Pool(1) as p :
            value = p.map(multi_run_wrapper, CMD)
            if not 0 in value :
                sys.stderr.write("[ERROR] Check the log file : " + (CMD[0])[1] + "\n")
                sys.stderr.flush()
                sys.exit()

        #Variant Selection
        sys.stderr.write("\n\nVariant Selection\n")
        sys.stderr.flush()
        
        CMD.clear()
        line, log = "", ""
        line = VariantTool + " SelectVariants -R " + REFERENCE + " -V " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.GT.vcf.gz --select-type-to-include SNP -O " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.GT.SNP.vcf.gz"
        log = out + "/02_VariantCalling/logs/VariantCalling/" + VCF_prefix + ".selectVariants.log"
        CMD.append([line, log])

        if verbose == "1" :
            sys.stderr.write(line + " &> " + log + "\n")
            sys.stderr.flush()

        with Pool(1) as p :
            value = p.map(multi_run_wrapper, CMD)
            if not 0 in value :
                sys.stderr.write("[ERROR] Check the log file : " + (CMD[0])[1] + "\n")
                sys.stderr.flush()
                sys.exit()


def GatkVariantfiltering(out, verbose) :
    global STATE
    global VCF_prefix
    global VariantTool

    global REFERENCE
    global DBSNP

    global variantfilt_option_line
    global filterExpression
    
    CMD = list()
    if STATE == 1 :
        sys.stderr.write("\n\nVariant filtering\n")
        sys.stderr.flush()
        
        line, log = "", ""
        if DBSNP == "" :
            line = "java -Xmx4g -jar " + VariantTool + " -T VariantFiltration " + variantfilt_option_line + "-R " + REFERENCE + " --variant " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.GT.SNP.vcf --filterName \"SNPFILTER\" --filterExpression " + filterExpression + " --out " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.GT.SNP.tag.vcf"
            log = out + "/02_VariantCalling/logs/VariantCalling/" + VCF_prefix + ".tagging.log"
        else :
            line = "java -Xmx4g -jar " + VariantTool + " -T VariantFiltration " + variantfilt_option_line + "-R " + REFERENCE + " --variant " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.GT.SNP.vcf --filterName \"SNPFILTER\" --mask " + DBSNP + " --filterExpression " + filterExpression + " --out " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.GT.SNP.tag.vcf"
            log = out + "/02_VariantCalling/logs/VariantCalling/" + VCF_prefix + ".tagging.log"
        CMD.append([line, log])

        if verbose == "1" :
            sys.stderr.write(line + " &> " + log + "\n")
            sys.stderr.flush()

        with Pool(1) as p :
            value = p.map(multi_run_wrapper, CMD)
            if not 0 in value :
                sys.stderr.write("[ERROR] Check the log file : " + (CMD[0])[1] + "\n")
                sys.stderr.flush()
                sys.exit()

        CMD.clear()
        line = "java -Xmx4g -jar " + VariantTool + " -T SelectVariants -R " + REFERENCE + " --variant " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.GT.SNP.tag.vcf -select \"FILTER == SNPFILTER\" --invertselect -o " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.GT.SNP.flt.vcf"
        log = out + "/02_VariantCalling/logs/VariantCalling/" + VCF_prefix + ".filtering.log"
        CMD.append([line, log])

        if verbose == "1" :
            sys.stderr.write(line + " &> " + log + "\n")
            sys.stderr.flush()

        with Pool(1) as p :
            value = p.map(multi_run_wrapper, CMD)
            if not 0 in value :
                sys.stderr.write("[ERROR] Check the log file : " + (CMD[0])[1] + "\n")
                sys.stderr.flush()
                sys.exit()


    elif STATE == 2 :
        sys.stderr.write("\n\nVariant filtering\n")
        sys.stderr.flush()
        
        CMD = list()
        line, log = "", ""
        if DBSNP == "" :
            line = VariantTool + " VariantFiltration " + variantfilt_option_line + "-R " + REFERENCE + " -V " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.GT.SNP.vcf.gz -O " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.GT.SNP.tag.vcf.gz --filter-expression " + filterExpression + " --filter-name \"SNPFILTER\""
            log = out + "/02_VariantCalling/logs/VariantCalling/" + VCF_prefix + ".tagging.log"
        else :
            line = VariantTool + " VariantFiltration " + variantfilt_option_line + "-R " + REFERENCE + " -V " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.GT.SNP.vcf.gz -O " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.GT.SNP.tag.vcf.gz --filter-expression " + filterExpression + " --filter-name \"SNPFILTER\" --mask " + DBSNP
            log = out + "/02_VariantCalling/logs/VariantCalling/" + VCF_prefix + ".tagging.log"
        CMD.append([line, log])

        if verbose == "1" :
            sys.stderr.write(line + " &> " + log + "\n")
            sys.stderr.flush()

        with Pool(1) as p :
            value = p.map(multi_run_wrapper, CMD)
            if not 0 in value :
                sys.stderr.write("[ERROR] Check the log file : " + (CMD[0])[1] + "\n")
                sys.stderr.flush()
                sys.exit()

        CMD.clear()
        line = VariantTool + " SelectVariants -R " + REFERENCE + " -V " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.GT.SNP.tag.vcf.gz -select \"FILTER == SNPFILTER\" --invertSelect -O " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.GT.SNP.flt.vcf.gz"
        log = out + "/02_VariantCalling/logs/VariantCalling/" + VCF_prefix + ".filtering.log"
        CMD.append([line, log])

        if verbose == "1" :
            sys.stderr.write(line + " &> " + log + "\n")
            sys.stderr.flush()

        with Pool(1) as p :
            value = p.map(multi_run_wrapper, CMD)
            if not 0 in value :
                sys.stderr.write("[ERROR] Check the log file : " + (CMD[0])[1] + "\n")
                sys.stderr.flush()
                sys.exit()


def SamtoolsVariantCalling(out, th,  job, verbose) :
    global STATE
    global VCF_prefix
    global SAMTOOLS
    global BCFTOOLS
    global VCFTOOLS
    global VariantTool

    global REFERENCE
    global DBSNP
    global SAMPLE_DATA

    global variantcalling_option_line
    
    input_list = ""
    CMD = list()

    sys.stderr.write("\n\n#Variant Calling\n")
    sys.stderr.flush()

    if not os.path.isdir(out + "/02_VariantCalling/VariantCalling") :
        sub.call(f'mkdir {out}/02_VariantCalling/VariantCalling', shell=True)
    if not os.path.isdir(out + "/02_VariantCalling/logs/VariantCalling") :
        sub.call(f'mkdir {out}/02_VariantCalling/logs/VariantCalling', shell=True)

    for i,j in SAMPLE_DATA.items() :
        input_list += " " + j

    line = SAMTOOLS + " mpileup -g -f " + REFERENCE + input_list + " > " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".raw.bcf"
    log = out + "/02_VariantCalling/logs/VariantCalling/" + VCF_prefix + ".mpilup.log"
    CMD.append([line, log])

    if verbose == "1" :
        sys.stderr.write(line + " &> " + log + "\n")
        sys.stderr.flush()

    with Pool(1) as p :
        value = p.map(multi_run_wrapper, CMD)
        if not 0 in value :
            sys.stderr.write("[ERROR] Check the log file : " + (CMD[0])[1] + "\n")
            sys.stderr.flush()
            sys.exit()
    
    CMD.clear()
    line = "(" + BCFTOOLS + " call -c -v --output-type b --threads "+th+" " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".raw.bcf | " + BCFTOOLS + " view -m 2 --output-type b > " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.bcf)"
    log = out + "/02_VariantCalling/logs/VariantCalling/" + VCF_prefix + ".bcftools.call.log"
    CMD.append([line, log])

    if verbose == "1" :
        sys.stderr.write(line + " &> " + log + "\n")
        sys.stderr.flush()

    with Pool(1) as p :
        value = p.map(multi_run_wrapper, CMD)
        if not 0 in value :
            sys.stderr.write("[ERROR] Check the log file : " + (CMD[0])[1] + "\n")
            sys.stderr.flush()
            sys.exit()

    sys.stderr.write("\n\n#Filter SNPs\n")
    sys.stderr.flush()
    CMD.clear()
    line = BCFTOOLS + " view --threads "+th+" "+ out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.bcf | vcfutils.pl varFilter - > " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.flt.vcf"
    log = out + "/02_VariantCalling/logs/VariantCalling/" + VCF_prefix + ".filter.log"
    CMD.append([line, log])

    if verbose == "1" :
        sys.stderr.write(line + " &> " + log + "\n")
        sys.stderr.flush()

    with Pool(1) as p :
        value = p.map(multi_run_wrapper, CMD)
        if not 0 in value :
            sys.stderr.write("[ERROR] Check the log file : " + (CMD[0])[1] + "\n")
            sys.stderr.flush()
            sys.exit()

    sys.stderr.write("\n\n#Variant Selection\n")
    sys.stderr.flush()

    CMD.clear()
    line = VCFTOOLS + " --vcf " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.flt.vcf --remove-indels --recode --recode-INFO-all --out " + out + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.flt.SNP.vcf"
    log = out + "/02_VariantCalling/logs/VariantCalling/" + VCF_prefix + ".SelectVariant.log"
    CMD.append([line, log])

    if verbose == "1" :
        sys.stderr.write(line + " &> " + log + "\n")
        sys.stderr.flush()

    with Pool(1) as p :
        value = p.map(multi_run_wrapper, CMD)
        if not 0 in value :
            sys.stderr.write("[ERROR] Check the log file : " + (CMD[0])[1] + "\n")
            sys.stderr.flush()
            sys.exit()


def start(out, th, memory, job, verbose) :
    global STATE
    
    Indexing(os.path.abspath(out), th, verbose)
    sys.stderr.write("Success the Indexing\n")
    sys.stderr.flush()
    if STATE == 1 :
        #LocalRealignment(os.path.abspath(out), th, memory, job, verbose)
        sys.stderr.write("Success the Local Re-alignment\n")
        sys.stderr.flush()
        IndelRealignment(os.path.abspath(out), th, memory, job, verbose)
        sys.stderr.write("Success the Indel Re-alignment\n")
        sys.stderr.flush()
        BaseRecalibration(os.path.abspath(out), th, memory, job, verbose)
        sys.stderr.write("Success the Base Recalibration\n")
        sys.stderr.flush()
        GatkVariantcalling(os.path.abspath(out), th, memory, job, verbose)
        sys.stderr.write("Success the Variant Calling\n")
        sys.stderr.flush()
        GatkVariantfiltering(os.path.abspath(out), verbose)
        sys.stderr.write("Success the Variant filtering\n")
        sys.stderr.flush()
    elif STATE == 2 :
        BaseRecalibration(os.path.abspath(out), th, memory, job, verbose)
        sys.stderr.write("Success the Base Recalibration\n")
        sys.stderr.flush()
        GatkVariantcalling(os.path.abspath(out), th, memory, job, verbose)
        sys.stderr.write("Success the Variant Calling\n")
        sys.stderr.flush()
        GatkVariantfiltering(os.path.abspath(out), verbose)
        sys.stderr.write("Success the Variant filtering\n")
        sys.stderr.flush()
    elif STATE == 3 :
        SamtoolsVariantCalling(os.path.abspath(out), th, job, verbose)
        sys.stderr.write("Success the Variant Calling\n")
        sys.stderr.flush()
    sys.stderr.write("\nFinish the Variant calling step\n\n")
    sys.stderr.flush()


def main() :
    args = config()

    sys.stderr.write("------------VariantCalling-------------\n")
    sys.stderr.flush()
    
    if not os.path.isdir(args.out_dir + "/02_VariantCalling") :
        sub.call(f'mkdir -p {args.out_dir}/02_VariantCalling', shell=True)
    if not os.path.isdir(args.out_dir + "/02_VariantCalling/logs") :
        sub.call(f'mkdir -p {args.out_dir}/02_VariantCalling/logs', shell=True)

    param_file(args.param)
    start(args.out_dir, args.threads, args.memory, args.job, args.verbose)


def main_pipe(args, dict_param, index) :
    sys.stderr.write("------------VariantCalling-------------\n")
    sys.stderr.flush()
    
    sub.call(f'mkdir -p {args.out}/02_VariantCalling/logs', shell=True)

    global STATE

    if index == 0 :
        ParseInput(args.input, args.out)

    var_param = Param.VariantCalling(args.out, dict_param)
    param_file(var_param.name)
    start(args.out, args.threads, args.memory, args.job, args.verbose)
    
    vcf = ""
    if STATE == 1 :
        vcf = os.path.abspath(args.out) + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.GT.SNP.flt.vcf"
    elif STATE == 2 :
        vcf = os.path.abspath(args.out) + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.combined.GT.SNP.flt.vcf.gz"
    elif STATE == 3 :
        vcf = os.path.abspath(args.out) + "/02_VariantCalling/VariantCalling/" + VCF_prefix + ".variant.flt.SNP.vcf.recode.vcf"
  
    sub.call(f'mkdir -p {args.out}/02_VariantCalling/VariantCalling/FINAL', shell=True)
    sub.call(f'ln -s {vcf} {os.path.abspath(args.out)}/02_VariantCalling/VariantCalling/FINAL', shell=True)
