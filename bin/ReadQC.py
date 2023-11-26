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
OPTION = ""

## Data Variable
REFERENCE = ""

## Sample Variable
SAMPLE_NAME = ""
PLATFORM = ""
LIBRARY = ""
LIBRARY_UNIT = ""
LIBRARY_sample = []

def tree() :
    return defaultdict(tree)
SAMPLE_DATA = tree()


def ParseInput(input_) :
    dict_input = tree()
    for line in open(input_, 'r') :
        line = line.strip()
        if re.match(r'\s*$', line) :
            continue
        elif line.startswith('####') :
            match = (line.replace('####', '')).strip()
            if not match == "ReadMapping" :
                sys.stderr.write("Require the readQC input file\n")
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

def callQCPipe(outdir, input, th) :
    bindir = os.path.abspath(os.path.dirname(__file__))
    READQC = bindir + "/qc_script/QualityControl.pl "
    CMD = "perl "+READQC+"  "+outdir+"/param/ReadQC.txt  "+input
    log = outdir+"/00_ReadQC/readQC.log"
    sys.stderr.write(CMD + " &> " + log + "\n")
    sys.stderr.flush()
    
    with open(log, 'w') as outfile :
        value = sub.call(CMD, shell=True, stdout = outfile, stderr = outfile)
    if value != 0 :
        sys.stderr.write("[ERROR] Check the log file : " + outdir + "/00_ReadQC")
        sys.stderr.flush()
        sys.exit()



def main_pipe(args, dict_param, index) :
    sys.stderr.write("---------------Read QC--------------\n")
    sys.stderr.flush()

    sub.call(f'mkdir -p {args.out}/00_ReadQC', shell=True)
    Param.ReadQC(os.path.abspath(args.out), dict_param)
    callQCPipe(os.path.abspath(args.out), os.path.abspath(args.input), args.threads)
    new_input = os.path.abspath(os.path.abspath(args.out)+"/00_ReadQC/updated.input.txt")
    sys.stderr.write("\nFinish the Read QC step\n\n")
    sys.stderr.flush()
    return new_input
