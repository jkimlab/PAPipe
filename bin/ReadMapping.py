import re
import os
import sys
import argparse

from time import sleep
from collections import defaultdict
from multiprocessing import Pool
import subprocess as sub

import Param

###########################
### Variable Definition ###
###########################
## Program Variable 
BWA = ""
BOWTIE2 = ""
PICARD = ""
SAMTOOLS = ""
JAVA = ""
OPTION = ""

## Data Variable
REFERENCE = ""

## Sample Variable
SAMPLE_NAME = ""
PLATFORM = ""
LIBRARY = ""
LIBRARY_UNIT = ""
LIBRARY_sample = []

## Option Variable
indexing_option_line = ""
mapping_option_line = ""
markduplicate_option_line = ""
readgrouping_option_line = ""

###########################
### Function Definition ###
###########################

def tree() :
    return defaultdict(tree)

SAMPLE_DATA = tree()

def multi_run_wrapper(args) :
    return f(*args)

def f(x, log) :
    with open(log, 'w') as outfile :
        value = sub.call(x, shell=True, stdout = outfile, stderr = outfile)
    return value

def map_f(x) : 
    value = 0
    for line, log in x :
        with open(log, 'w') as outfile :
            value += int(sub.call(line, shell=True, stdout = outfile, stderr = outfile))
    return value

def config() :
    parser = argparse.ArgumentParser(description = "ReadMapping")
    parser.add_argument('-P', '--param', help='<Path> parameter file', required = True)
    parser.add_argument('-O', '--out_dir', help='<Path> Output directory', required = True)
    parser.add_argument('-@', '--threads', default = 10, help='<Int> Number of threads (default 10)', required = False)
    parser.add_argument('-M', '--memory', default = 10, help='<Int> Memory (default 10)', required = False)
    parser.add_argument('-J', '--job', default = 1, help = '<Int> number of parallele jobs (default 1)', required = False)
    parser.add_argument('-V', '--verbose', default = "0", help = '<Int> if you want to see command line, set 1 (default 0)', required = False)
    args = parser.parse_args()

    return args

def param_file(param) :
    sample_cnt = 0
    sample_rcnt = 1
    library_cnt = 0

    global JAVA
    global BWA
    global BOWTIE2
    global SAMTOOLS 
    global OPTION
    global PICARD
    global REFERENCE

    global SAMPLE_NAME
    global PLATFORM
    global LIBRARY
    global LIBRARY_UNIT
    global LIBRARY_sample
    global SAMPLE_DATA

    global indexing_option_line
    global mapping_option_line
    global markduplicate_option_line
    global readgrouping_option_line

    for line in open(param, 'r') :
        line = line.strip()
        if re.match(r'^\s*$', line) :
            continue
        elif line.startswith("#") :
            continue
        elif line.startswith("<") :
            sample_cnt += 1
            library_cnt = 0
            SAMPLE_NAME = line[1:len(line)-1].strip()
            LIBRARY_sample.append(SAMPLE_NAME)
        elif line.startswith("[") :
            if sample_cnt >= 1 :
                library_cnt += 1
                sample_rcnt = 1
                LIBRARY = line[1:len(line)-1]

        else :
            if sample_cnt >= 1 :
                if sample_rcnt == 1 :
                    SAMPLE_DATA[SAMPLE_NAME][LIBRARY][sample_rcnt] = os.path.abspath(line)
                    sample_rcnt += 1
                elif sample_rcnt == 2 :
                    SAMPLE_DATA[SAMPLE_NAME][LIBRARY][sample_rcnt] = os.path.abspath(line)

            else :
                match = ((line.split('='))[0]).strip()
                path = ((line.split('='))[1]).strip()
                if match == "Platform" :
                    PLATFORM = path
                elif match == "Platform_unit" :
                    LIBRARY_UNIT = path
                elif match == "OPTION" :
                    OPTION = path
                elif match == "JAVA" :
                    #JAVA = os.path.abspath(path)
                    JAVA = path
                elif match == "BWA" :
                    #BWA = os.path.abspath(path)
                    BWA = path
                elif match == "BOWTIE2" :
                    #BOWTIE2 = os.path.abspath(path)
                    BOWTIE2 = path
                elif match == "SAMTOOLS" :
                    #SAMTOOLS = os.path.abspath(path)
                    SAMTOOLS = path
                elif match == "PICARD" :
                    #PICARD = os.path.abspath(path)
                    PICARD = path
                elif match == "Reference" :
                    REFERENCE = os.path.abspath(path)
                elif match == "indexing_option_line" :
                    indexing_option_line = path + " "
                elif match == "mapping_option_line" :
                    mapping_option_line = path + " " 
                elif match == "markduplicate_option_line" :
                    markduplicate_option_line = path + " "
                elif match == "readgrouping_option_line" :
                    readgrouping_option_line = path + " "


def ParseInput(input_) :
    dict_input = tree()
    
    read, flag, sample, lib = 1, 0, "", ""
    for line in open(input_, 'r') :
        line = line.strip()
        if re.match(r'^\s*$', line) :
            continue
        elif line.startswith('####') :
            step = (line.replace('####', '')).strip()
            if not step == "ReadMapping" :
                sys.stderr.write("Require the readmapping input file\n")
                sys.stderr.flush()
                sys.exit()
        elif line.startswith('<') :
            sample = (line.replace('<', '').replace('>', '')).strip()
        elif line.startswith('[') :
            lib = (line.replace('[', '').replace(']', '')).strip()
            read = 1
        elif not line.startswith('#') :
            if read == 1 :
                dict_input[sample][lib][read] = line
                read += 1
            elif read == 2 :
                dict_input[sample][lib][read] = line
                read = 1
        elif line.startswith('#') :
            continue

    return dict_input

def Indexing(out, th, verbose) :
    global OPTION
    global BWA
    global JAVA
    global BOWTIE2

    global REFERENCE
    global indexing_option_line
    value = 0

    sys.stderr.write("#01.Indexing\n")
    sys.stderr.flush()
    if not os.path.isdir(out + "/01_ReadMapping/01.Indexing") :
        sub.call(f'mkdir {out}/01_ReadMapping/01.Indexing', shell=True)

    if not os.path.isdir(out + "/01_ReadMapping/logs/01.Indexing") :
        sub.call(f'mkdir {out}/01_ReadMapping/logs/01.Indexing', shell=True)

    f_incomplete = out+"/01_ReadMapping/01.Indexing/incomplete"
    f_incomplete_tmp = out+"/01_ReadMapping/01.Indexing/incomplete_tmp"
    O_incomplete_tmp = open(f'{f_incomplete_tmp}','w')
    RENEW_CMD = list()
    single_CMD = list()
    incomplete_line = 0
    if os.path.exists(f_incomplete):
        for line in open(f_incomplete, 'r') :
            line = line.strip()
            cmd, log = [i.strip() for i in line.split('&>')]
            single_CMD.append([cmd, log])
            incomplete_line += 1

        RENEW_CMD.append(single_CMD)
        with Pool(incomplete_line) as p :
            value = p.map(map_f, RENEW_CMD)
            check = 0
            for i in range(len(value)) :
                if not value[i] == 0 :
                    check += 1
                    sys.stderr.write("[ERROR] Check the log file : " + RENEW_CMD[i][0][1] + "\n")
                    O_incomplete_tmp.write(RENEW_CMD[i][0][0] +" &> "+ RENEW_CMD[i][0][1] +"\n")
                    sys.stderr.flush()
            if not check == 0 :
                sub.call(f'mv -f {f_incomplete_tmp} {f_incomplete}', shell=True)
                sys.exit()
        sub.call(f'touch  {out}/01_ReadMapping/01.Indexing/complete', shell=True)
        sub.call(f'rm -f  {out}/01_ReadMapping/01.Indexing/incomplete', shell=True)
        return

    O_incomplete = open(f'{f_incomplete}','w')

    if OPTION == "1" :
        sys.stderr.write("Start indexing the reference file using the bwa tools\n")
        sys.stderr.flush()
        CMD = BWA + " index " + indexing_option_line + "-p " + out + "/01_ReadMapping/01.Indexing/ref " + REFERENCE
        log = out + "/01_ReadMapping/logs/01.Indexing/index.bwa.log"
        if verbose == "1" :
            sys.stderr.write(CMD + " &> " + log + "\n")
            sys.stderr.flush()

        
        with open(log, 'w') as outfile :
            value = sub.call(CMD, shell=True, stdout = outfile, stderr = outfile)
        
        if value != 0 :
            sys.stderr.write("[ERROR] Check the log file : " + out + "/01_ReadMapping/logs/01.Indexing/index.bwa.log")
            O_incomplete.write(CMD + " &> " + log+"\n")
            sys.stderr.flush()
            sys.exit()
    
    elif OPTION == "2" :
        sys.stderr.write("Start to indexing the reference file using the bowtie2 tools\n")
        sys.stderr.flush()
        CMD = BOWTIE2 + "-build " +"--threads "+str(th)+"  "+ REFERENCE + " " + out + "/01_ReadMapping/01.Indexing/ref" + indexing_option_line 
        log = out + "/01_ReadMapping/logs/01.Indexing/index.bowtie2.log"
        
        if verbose == "1" : 
            sys.stderr.write(CMD + " &> " + log + "\n") 
            sys.stderr.flush()
        
        with open(log, 'w') as outfile :
            value = sub.call(CMD, shell=True, stdout = outfile, stderr = outfile)
        if value != 0 :
            sys.stderr.write("[ERROR] Check the log file : " + out + "/01_ReadMapping/logs/01.Indexing/index.bowtie2.log")
            O_incomplete.write(CMD + " &> " + log+"\n")
            sys.stderr.flush()
            sys.exit()
    

def Mapping(out, th, job, verbose) :
    global OPTION
    global JAVA
    global BWA
    global BOWTIE2
    global SAMTOOLS

    global SAMPLE_DATA
    global LIBRARY_sample
    global mapping_option_line
    
    sample_list = []

    sys.stderr.write("#02.Mapping\n")
    sys.stderr.flush()
    if not os.path.isdir(out + "/01_ReadMapping/02.Mapping") :
        sub.call(f'mkdir -p {out}/01_ReadMapping/02.Mapping', shell=True)

    if not os.path.isdir(out + "/01_ReadMapping/logs/02.Mapping") :
        sub.call(f'mkdir {out}/01_ReadMapping/logs/02.Mapping', shell=True)

    f_incomplete = out+"/01_ReadMapping/02.Mapping/incomplete"
    f_incomplete_tmp = out+"/01_ReadMapping/02.Mapping/incomplete_tmp"
    O_incomplete_tmp = open(f'{f_incomplete_tmp}','w')
    RENEW_CMD = list()
    single_CMD = list()
    if os.path.exists(f_incomplete):
        for line in open(f_incomplete, 'r') :
            line = line.strip()
            cmd, log = [i.strip() for i in line.split('&>')]
            single_CMD.append([cmd, log])
        
        RENEW_CMD.append(single_CMD)
        with Pool(int(job)) as p :
            value = p.map(map_f, RENEW_CMD)
            check = 0
            for i in range(len(value)) :
                if not value[i] == 0 :
                    check += 1
                    sys.stderr.write("[ERROR] Check the log file : " + RENEW_CMD[i][0][1] + "\n")
                    O_incomplete_tmp.write( RENEW_CMD[i][0][0] +" &> "+ RENEW_CMD[i][0][1] +"\n")
                    sys.stderr.flush()
            if not check == 0 :
                sys.exit()
        sub.call(f'touch  {out}/01_ReadMapping/02.Mapping/complete', shell=True)
        return;

    O_incomplete = open(f'{f_incomplete}','w')
    ALL_CMD = list()
    sample_CMD = list()
    if OPTION == "1" :
        for i,j in SAMPLE_DATA.items() :
            library_iter = 1
            sample_CMD = list()
            merge_line = SAMTOOLS + " merge -@ " + str(th) + " " + out + "/01_ReadMapping/02.Mapping/" + i + ".sort.bam"
            for k,l in j.items() :
                line, samtools_line, rm_line, log, samtools_log, rm_log = "", "", "", "", "", ""
                if len(SAMPLE_DATA[i].keys()) == 1 :
                    line = BWA + " mem -t " + str(th) + " " + mapping_option_line + out + "/01_ReadMapping/01.Indexing/ref" + " " + SAMPLE_DATA[i][k][1] + " " + SAMPLE_DATA[i][k][2] + " > " + out + "/01_ReadMapping/02.Mapping/" + i + ".sam"
                    log = out + "/01_ReadMapping/logs/02.Mapping/" + i + ".mapping.log"
                    samtools_line = SAMTOOLS + " view -Sb " + out + "/01_ReadMapping/02.Mapping/" + i + ".sam | " + SAMTOOLS + " sort -o " + out + "/01_ReadMapping/02.Mapping/" + i + ".sort.bam -"
                    samtools_log = out + "/01_ReadMapping/logs/02.Mapping/" + i + ".sort.log"
                    rm_line = "rm -rf " + out + "/01_ReadMapping/02.Mapping/" + i + ".sam"
                    rm_log = out + "/01_ReadMapping/logs/02.Mapping/" + i + ".rm.log"

                    sample_CMD.append([line,log])
                    sample_CMD.append([samtools_line, samtools_log])
                    sample_CMD.append([rm_line, rm_log])
                    sample_list.append(i)
                    
                    if verbose == "1" :
                        sys.stderr.write(line + " &> " + log + "\n" + samtools_line + " &> " + samtools_log + "\n")
                        sys.stderr.flush()

                else :
                    merge_log = ""
                    line = BWA + " mem -t " + str(th) + " " + mapping_option_line + out + "/01_ReadMapping/01.Indexing/ref" + " " + SAMPLE_DATA[i][k][1] + " " + SAMPLE_DATA[i][k][2] + " > " + out + "/01_ReadMapping/02.Mapping/" + i + "_" + k + ".sam"
                    log = out + "/01_ReadMapping/logs/02.Mapping/" + i + "_" + k + ".mapping.log" 
                    samtools_line = SAMTOOLS + " view -Sb " + out + "/01_ReadMapping/02.Mapping/" + i + "_" + k + ".sam | " + SAMTOOLS + " sort -o " + out + "/01_ReadMapping/02.Mapping/" + i + "_" + k + ".sort.bam -"
                    samtools_log = out + "/01_ReadMapping/logs/02.Mapping/" + i + "_" + k + ".sort.log"
                    merge_line = merge_line + " " + out + "/01_ReadMapping/02.Mapping/" + i + "_" + k + ".sort.bam"
                    merge_log = out + "/01_ReadMapping/logs/02.Mapping/" + i + ".merge.log"
                    rm_line = "rm -rf " + out + "/01_ReadMapping/02.Mapping/" + i + "_" + k + ".sam"
                    rm_log = out + "/01_ReadMapping/logs/02.Mapping/" + i + ".rm.log"
                    library_iter += 1
                    
                    sample_CMD.append([line, log])
                    sample_CMD.append([samtools_line, samtools_log])
                    sample_CMD.append([rm_line, rm_log])
                    sample_list.append(i + "_" + k)
                    if verbose == "1" :
                            sys.stderr.write(line + " &> " + log + "\n" + samtools_line + " &> " + samtools_log + "\n")
                            sys.stderr.flush()

            if library_iter > 1 :
                sample_CMD.append([merge_line, merge_log])
            ALL_CMD.append(sample_CMD)
        
    elif OPTION == "2" :
        for i,j in SAMPLE_DATA.items() :
            library_iter = 1
            sample_CMD = list()
            merge_line = SAMTOOLS + " merge -@ " + str(th) + " " + out + "/01_ReadMapping/02.Mapping/" + i + ".sort.bam"
            for k,l in j.items() :
                line, samtools_line, rm_line, log, samtools_log, rm_log = "", "", "", "", "", ""
                if len(SAMPLE_DATA[i].keys()) == 1 :
                    line = BOWTIE2 + " -p " + str(th) + " " + mapping_option_line + "-x " + out + "/01_ReadMapping/01.Indexing/ref" + " -1 " + SAMPLE_DATA[i][k][1] + " -2 " + SAMPLE_DATA[i][k][2] + " -S " + out + "/01_ReadMapping/02.Mapping/" + i + ".sam"
                    log = out + "/01_ReadMapping/logs/02.Mapping/" + i + ".mapping.log"
                    samtools_line = SAMTOOLS + " view -Sb " + out + "/01_ReadMapping/02.Mapping/" + i + ".sam | " + SAMTOOLS + " sort -o " + out + "/01_ReadMapping/02.Mapping/" + i + ".sort.bam -"
                    samtools_log = out + "/01_ReadMapping/logs/02.Mapping/" + i + ".sort.log"
                    rm_line = "rm -rf " + out + "/01_ReadMapping/02.Mapping/" + i + ".sam"
                    rm_log = out + "/01_ReadMapping/logs/02.Mapping/" + i + ".rm.log"

                    sample_CMD.append([line, log])
                    sample_CMD.append([samtools_line, samtools_log])
                    sample_CMD.append([rm_line, rm_log])
                    sample_list.append(i)
                    
                    if verbose == "1" :
                        sys.stderr.write(line + " &> " + log + "\n" + samtools_line + " &> " + samtools_log + "\n")
                        sys.stderr.flush()
                
                else :
                    merge_log = ""
                    line = BOWTIE2 + " -p " + str(th) + " " + mapping_option_line + "-x " + out + "/01_ReadMapping/01.Indexing/ref" + " -1 " + SAMPLE_DATA[i][k][1] + " -2 " + SAMPLE_DATA[i][k][2] + " -S " + out + "/01_ReadMapping/02.Mapping/" + i + "_" + k + ".sam"
                    log = out + "/01_ReadMapping/logs/02.Mapping/" + i + "_" + k + ".mapping.log"
                    samtools_line = SAMTOOLS + " view -Sb " + out + "/01_ReadMapping/02.Mapping/" + i + "_" + k + ".sam | " + SAMTOOLS + " sort -o " + out + "/01_ReadMapping/02.Mapping/" + i + "_" + k + ".sort.bam"
                    samtools_log = out + "/01_ReadMapping/logs/02.Mapping/" + i + "_" + k + ".sort.log"
                    merge_line = merge_line + " " + out + "/01_ReadMapping/02.Mapping/" + i + "_" + k + ".sort.bam"
                    merge_log = out + "/01_ReadMapping/logs/02.Mapping/" + i + ".merge.log"
                    rm_line = "rm -rf " + out + "/01_ReadMapping/02.Mapping/" + i + "_" + k + ".sam"
                    rm_log = out + "/01_ReadMapping/logs/02.Mapping/" + i + ".rm.log"
                    library_iter += 1

                    sample_CMD.append([line, log])
                    sample_CMD.append([samtools_line, samtools_log])
                    sample_CMD.append([rm_line, rm_log])
                    sample_list.append(i + "_" + k)
                    
                    if verbose == "1" :
                        sys.stderr.write(line + " &> " + log + "\n" + samtools_line + " &> " + samtools_log + "\n")
                        sys.stderr.flush()


            if library_iter > 1 :
                sample_CMD.append([merge_line, merge_log])
            ALL_CMD.append(sample_CMD)


    with Pool(int(job)) as p :
        value = p.map(map_f, ALL_CMD)
        check = 0
        for i in range(len(value)) :
            if not value[i] == 0 :
                check += 1
                sys.stderr.write("[ERROR] Check the log file : " + ALL_CMD[i][0][1] + "\n")
                O_incomplete.write(ALL_CMD[i][0][0]+" &> "+ALL_CMD[i][0][1]+"\n")
                #sys.stderr.write("[ERROR] Check the log file : " + out + "/01_ReadMapping/logs/02.Mapping/" + sample_list[i] + ".mapping.log\n")
                sys.stderr.flush()
        if not check == 0 :
            sys.exit()




def Mark_Duplicate(out, memory, th, job, verbose) :
    global PICARD
    global JAVA
    global SAMPLE_DATA
    global LIBRARY_sample
    global markduplicate_option_line
    CMD = list()

    sys.stderr.write("#03.MarkDuplicate\n")
    sys.stderr.flush()
    if not os.path.isdir(out + "/01_ReadMapping/03.MarkDuplicate") :
        sub.call(f'mkdir {out}/01_ReadMapping/03.MarkDuplicate', shell=True)

    if not os.path.isdir(out + "/01_ReadMapping/logs/03.MarkDuplicate") :
        sub.call(f'mkdir {out}/01_ReadMapping/logs/03.MarkDuplicate', shell=True)


    f_incomplete = out+"/01_ReadMapping/03.MarkDuplicate/incomplete"
    f_incomplete_tmp = out+"/01_ReadMapping/03.MarkDuplicate/incomplete_tmp"
    O_incomplete_tmp = open(f'{f_incomplete_tmp}','w')
    RENEW_CMD = list()
    single_CMD = list()
    if os.path.exists(f_incomplete):
        for line in open(f_incomplete, 'r') :
            line = line.strip()
            cmd, log = [i.strip() for i in line.split('&>')]
            single_CMD.append([cmd, log])
        
        RENEW_CMD.append(single_CMD)
        with Pool(int(job)) as p :
            value = p.map(map_f, RENEW_CMD)
            check = 0
            for i in range(len(value)) :
                if not value[i] == 0 :
                    check += 1
                    sys.stderr.write("[ERROR] Check the log file : " + RENEW_CMD[i][0][1] + "\n")
                    O_incomplete_tmp.write(RENEW_CMD[i][0][0]+" &> "+RENEW_CMD[i][0][1]+"\n")
                    sys.stderr.flush()
            if not check == 0 :
                sub.call(f'mv -f {f_incomplete_tmp} {f_incomplete}', shell=True)
                sys.exit()
        sub.call(f'touch  {out}/01_ReadMapping/03.MarkDuplicate/complete', shell=True)
        return

    O_incomplete = open(f'{f_incomplete}','w')
    line, log = "", ""
    for i,j in SAMPLE_DATA.items() :
        line = JAVA+" -Xmx" + str(memory) + "g -jar " + PICARD + " MarkDuplicates " + markduplicate_option_line + "I=" + out + "/01_ReadMapping/02.Mapping/" + i + ".sort.bam O=" + out + "/01_ReadMapping/03.MarkDuplicate/" + i + ".marked.sort.bam M=" + out + "/01_ReadMapping/03.MarkDuplicate/" + i + ".marked_dup_matrix"
        log = out + "/01_ReadMapping/logs/03.MarkDuplicate/" + i + ".mark_duplicate.log"
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
                O_incomplete.write( (CMD[i])[0] + " &> " +  (CMD[i])[1]+"\n")
                sys.stderr.flush()
        if not check == 0 :
            sys.exit()


def Read_Regrouping(out, memory, th, job, verbose) :
    global PICARD
    global JAVA
    global SAMPLE_DATA
    global PLATFORM
    global LIBRARY_sample
    global LIBRARY
    global LIBRARY_UNIT
    global readgrouping_option_line
    value = 0
    CMD = list()

    sys.stderr.write("#04.ReadRegrouping\n")
    sys.stderr.flush()
    if not os.path.isdir(out + "/01_ReadMapping/04.ReadRegrouping") :
        sub.call(f'mkdir {out}/01_ReadMapping/04.ReadRegrouping', shell=True)

    if not os.path.isdir(out + "/01_ReadMapping/logs/04.ReadRegrouping") :
        sub.call(f'mkdir {out}/01_ReadMapping/logs/04.ReadRegrouping', shell=True)

    f_incomplete = out+"/01_ReadMapping/04.ReadRegrouping/incomplete"
    f_incomplete_tmp = out+"/01_ReadMapping/04.ReadRegrouping/incomplete_tmp"
    O_incomplete_tmp = open(f'{f_incomplete_tmp}','w')
    RENEW_CMD = list()
    single_CMD = list()
    if os.path.exists(f_incomplete):
        for line in open(f_incomplete, 'r') :
            line = line.strip()
            cmd, log = [i.strip() for i in line.split('&>')]
            single_CMD.append([cmd, log])

        RENEW_CMD.append(single_CMD)
        with Pool(int(job)) as p :
            value = p.map(map_f, RENEW_CMD)
            check = 0
            for i in range(len(value)) :
                if not value[i] == 0 :
                    check += 1
                    sys.stderr.write("[ERROR] Check the log file : " + RENEW_CMD[i][0][1] + "\n")
                    O_incomplete_tmp.write(RENEW_CMD[i][0][0]+" &> "+RENEW_CMD[i][0][1]+"\n")
                    sys.stderr.flush()
            if not check == 0 :
                sub.call(f'mv -f {f_incomplete_tmp} {f_incomplete}', shell=True)
                sys.exit()
        sub.call(f'rm -f  {f_incomplete_tmp} {f_incomplete}', shell=True)
        sub.call(f'touch  {out}/01_ReadMapping/04.ReadRegrouping/complete', shell=True)
        return

    O_incomplete = open(f'{f_incomplete}','w')

    line, log = "", ""
    for i,j in SAMPLE_DATA.items() :
        line = JAVA+" -Xmx" + str(memory) + "g -jar " + PICARD + " AddOrReplaceReadGroups " + readgrouping_option_line + "I=" + out + "/01_ReadMapping/03.MarkDuplicate/" + i + ".marked.sort.bam O=" + out + "/01_ReadMapping/04.ReadRegrouping/" + i + ".addRG.marked.sort.bam RGLB=lib1 RGPL=" + PLATFORM + " RGPU=" + LIBRARY_UNIT + " RGSM=" + i
        log = out + "/01_ReadMapping/logs/04.ReadRegrouping/" + i + ".addRG.log"
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
                O_incomplete.write(CMD[i][0] + " &> " + CMD[i][1]+"\n")
                sys.stderr.flush()
        if not check == 0 :
            sys.exit()



###########################
###### Main Function ######
###########################
def main_pipe(args, dict_param, index) :
    global SAMPLE_DATA
    global LIBRARY_sample

    sys.stderr.write("--------------ReadMapping--------------\n")
    sys.stderr.flush()
    if not os.path.isdir(args.out + "/01_ReadMapping") :
        sub.call(f'mkdir {args.out}/01_ReadMapping', shell=True)
    if not os.path.isdir(args.out + "/01_ReadMapping/logs") :
        sub.call(f'mkdir {args.out}/01_ReadMapping/logs', shell=True)

    SAMPLE_DATA = ParseInput(args.input)
    for sample in SAMPLE_DATA.keys() :
        LIBRARY_sample.append(sample)

    pre_param = Param.ReadMapping(args.out, dict_param, SAMPLE_DATA)
    param_file(pre_param.name)
    out = os.path.abspath(args.out)
    ####01.Indexing
    index_complete = args.out+"/01_ReadMapping/01.Indexing/complete"
    if os.path.exists(index_complete):
        sys.stderr.write("Skip Indexing\n\n")
        sys.stderr.flush()
    else:
        Indexing(os.path.abspath(args.out), args.threads ,args.verbose)
        sys.stderr.write("Success the Indexing\n\n")
        sys.stderr.flush()
        sub.call(f'touch  {out}/01_ReadMapping/01.Indexing/complete', shell=True)
    ####02.Mapping
    mapping_complete = args.out+"/01_ReadMapping/02.Mapping/complete"
    if os.path.exists(mapping_complete):
        sys.stderr.write("Skip Mapping\n\n")
        sys.stderr.flush()
    else:
        Mapping(os.path.abspath(args.out), args.threads, args.job, args.verbose)
        sys.stderr.write("Success the Mapping\n\n")
        sys.stderr.flush()
        sub.call(f'touch  {out}/01_ReadMapping/02.Mapping/complete', shell=True)
    ####03.MarkDuplicate
    mapping_complete = args.out+"/01_ReadMapping/03.MarkDuplicate/complete"
    if os.path.exists(mapping_complete):
        sys.stderr.write("Skip MarkDuplicate\n\n")
        sys.stderr.flush()
        sub.call(f'touch  {out}/01_ReadMapping/03.MarkDuplicate/complete', shell=True)
    else:
        Mark_Duplicate(os.path.abspath(args.out), args.memory, args.threads, args.job, args.verbose)
        sys.stderr.write("Success the MarkDuplicate\n\n")
        sys.stderr.flush()
    ####04.ReadRegrouping
    mapping_complete = args.out+"/01_ReadMapping/04.ReadRegrouping/complete"
    if os.path.exists(mapping_complete):
        sys.stderr.write("Skip ReadRegrouping\n\n")
        sys.stderr.flush()
    else:
        Read_Regrouping(os.path.abspath(args.out), args.memory, args.threads, args.job, args.verbose)
        sys.stderr.write("Success the ReadRegrouping\n\n")
        sys.stderr.flush()
        sub.call(f'touch  {out}/01_ReadMapping/04.ReadRegrouping/complete', shell=True)


    sys.stderr.write("Finish the Read mapping step\n\n")
    sys.stderr.flush()
