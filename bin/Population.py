import os
import re
import sys
import argparse

import subprocess as sub
from collections import defaultdict
from threading import Thread
import multiprocessing
from datetime import datetime



import Param

def tree() :
    return defaultdict(tree)


def config() :
    parser = argparse.ArgumentParser(description='Popultaion analysis')
    parser.add_argument('-P', '--param', help='<Path> parameter file', required=True)
    parser.add_argument('-O', '--out_dir', help='<Path> output directory', required=True)
    parser.add_argument('-V', '--verbose', help='<Int> if you want to se command line, set 1 (default 0)', required=True)
    args = parser.parse_args()

    return args

def ParseInput(input_, out) :
    dict_input = tree()

    sample, step, flag = "", "", 0
    for line in open(input_, 'r') :
        line = line.strip()
        if re.match(r'\s*$', line) :
            continue
        elif line.startswith('####') :
            match = (line.replace('####', '')).strip()
            if not match == "Population" :
                sys.stderr.write("Require the population input file\n")
                sys.stderr.flush()
                sys.exit()
        elif line.startswith('###') :
            step = (line.replace('###', '')).strip()
        elif line.startswith('<') :
            sample = (line.replace('<', '').replace('>', '')).strip()
        elif not line.startswith('#') :
            if step == "BAM" :
                if not os.path.isdir(out + "/01_ReadMapping/") :
                    sub.call(f'mkdir {out}/01_ReadMapping', shell=True)
                if not os.path.isdir(out + "/01_ReadMapping/04.ReadRegrouping") :
                    sub.call(f'mkdir {out}/01_ReadMapping/04.ReadRegrouping', shell=True)
 
                sub.call(f'ln -s {line} {out}/01_ReadMapping/04.ReadRegrouping/{sample}.bam', shell=True)

            elif step == "Vcf" :
                sub.call(f'mkdir -p {out}/02_VariantCalling/VariantCalling/FINAL', shell=True)
                sub.call(f'ln -s {line} {out}/02_VariantCalling/VariantCalling/FINAL/', shell=True)

            elif step == "Plink" :
                sub.call(f'mkdir -p {out}/03_Postprocessing/plink', shell=True)
                sub.call(f'ln -s {line}* {out}/03_Postprocessing/plink/', shell=True)

            elif step == "Hapmap" :
                sub.call(f'mkdir -p {out}/03_Postprocessing/Hapmap', shell=True)
                sub.call(f'ln -s {line} {out}/03_Postprocessing/Hapmap/', shell=True)



def PCA(out, verbose, param, sample) :
    bindir = os.path.abspath(os.path.dirname(__file__))
    PCA = bindir + "/script/PCA.pl"

    sys.stderr.write("\nPCA\n")
    sys.stderr.flush()

    for line in open(param, 'r') :
        line = line.strip()
        if 'ON/OFF' in line :
            flag = line.split('=')[1].strip()
            if flag.upper() == "OFF" :
                sys.stderr.write("Pass the PCA analysis\n")
                sys.stderr.flush()
                return " "

    if not os.path.isdir(out + "/PCA") :
        sub.call(f'mkdir {out}/PCA', shell=True)
    line = PCA + " -p " + param + " -s " + sample + " -o " + out + "/PCA"
    log = out + "/logs/pca.log"
    O_var_param = open(f'{os.path.abspath(out)}/PCA/cmd', 'w')
    O_var_param.write(line+" &> "+log+"\n")
    
    return "PCA  "
    '''
    if verbose == "1" :
        sys.stderr.write(line + " &> " + log + "\n")
        sys.stderr.flush()
    
    with open(log, 'w') as outfile :
        value = sub.call(line, shell=True, stdout = outfile, stderr = outfile)
    if not value == 0 :
        sys.stderr.write("[ERROR] Check the log file : " + out + "/04_Population/logs/pca.log\n")
        sys.stderr.flush()
    '''


def PhylogeneticTree(out, verbose, param) :
    bindir = os.path.abspath(os.path.dirname(__file__))
    PhylogeneticTree = bindir + "/script/PhylogeneticTree.pl"

    sys.stderr.write("\nPhylogenetic Tree\n")
    sys.stderr.flush()

    for line in open(param, 'r') :
        line = line.strip()
        if 'ON/OFF' in line :
            flag = line.split('=')[1].strip()
            if flag.upper() == "OFF" :
                sys.stderr.write("Pass the PhylogeneticTree analysis\n")
                sys.stderr.flush()

                return " "

    sub.call(f'mkdir {out}/PhylogeneticTree', shell=True)
    line = PhylogeneticTree + " -p " + param + " -o " + out + "/PhylogeneticTree"
    log = out + "/logs/snphylo.log"

    O_var_param = open(f'{os.path.abspath(out)}/PhylogeneticTree/cmd', 'w')
    O_var_param.write(line+" &> "+log+"\n")

    return "PhylogeneticTree  "


'''    if verbose == "1" :
        sys.stderr.write(line + " &> " + log + "\n")
        sys.stderr.flush()

    with open(log, 'w') as outfile :
        value = sub.call(line, shell=True, stdout = outfile, stderr = outfile)
    if not value == 0 :
        sys.stderr.write("[ERROR] Check the log file : " + out + "/04_Population/logs/snphylo.log\n")
        sys.stderr.flush()
'''

def Structure(out, verbose, param, sample) :
    
    bindir = os.path.abspath(os.path.dirname(__file__))
    Structure = bindir + "/script/Structure.pl"

    sys.stderr.write("\nPopulation Structure\n")
    sys.stderr.flush()

    for line in open(param, 'r') :
        line = line.strip()
        if 'ON/OFF' in line :
            flag = line.split('=')[1].strip()
            if flag.upper() == "OFF" :
                sys.stderr.write("Pass the Population Structure analysis\n")
                sys.stderr.flush()
                return " "

    sub.call(f'mkdir -p {out}/Structure', shell=True)
    
    line = Structure + " -p " + param + " -s " + os.path.abspath(sample) + " -o " + out + "/Structure"
    log = out + "/logs/structure.log"

    O_var_param = open(f'{os.path.abspath(out)}/Structure/cmd', 'w')
    O_var_param.write(line+" &> "+log+"\n")

    return "Structure  "

    
'''    if verbose == "1" :
        sys.stderr.write(line + " &> " + log + "\n")
        sys.stderr.flush()

    with open(log, 'w') as outfile :
        value = sub.call(line, shell=True, stdout = outfile, stderr = outfile)
    
    if not value == 0 :
        sys.stderr.write("[ERROR] Check the log file : " + out + "/04_Population/logs/structure.log\n")
        sys.stderr.flush()
'''

def Fst(out, verbose, param, sample) :
    bindir = os.path.abspath(os.path.dirname(__file__))
    Fst = bindir + "/script/Fst.pl"

    sys.stderr.write("\nFst\n")
    sys.stderr.flush()

    for line in open(param, 'r') :
        line = line.strip()
        if 'ON/OFF' in line :
            flag = line.split('=')[1].strip()
            if flag.upper() == "OFF" :
                sys.stderr.write("Pass the Fst analysis\n")
                sys.stderr.flush()
                return " "

    sub.call(f'mkdir -p {out}/Fst', shell=True)
    
    line = Fst + " -p " + param + " -o " + out + "/Fst -s " + sample
    log = out + "/logs/fst.log"

    O_var_param = open(f'{os.path.abspath(out)}/Fst/cmd', 'w')
    O_var_param.write(line+" &> "+log+"\n")
    return "Fst  "

'''    if verbose == "1" :
        sys.stderr.write(line + " &> " + log + "\n")
        sys.stderr.flush()

    with open(log, 'w') as outfile :
        value = sub.call(line, shell=True, stdout = outfile, stderr = outfile)
    
    if not value == 0 :
        sys.stderr.write("[ERROR] Check the log file : " + out + "/04_Population/logs/fst.log\n")
        sys.stderr.flush()
'''

def EffectiveSize(out, verbose, param, th) :
    bindir = os.path.abspath(os.path.dirname(__file__))
    Eff = bindir + "/script/EffectiveSize.pl"

    sys.stderr.write("\nEffective Size\n")
    sys.stderr.flush()

    for line in open(param, 'r') :
        line = line.strip()
        if 'ON/OFF' in line :
            flag = line.split('=')[1].strip()
            if flag.upper() == "OFF" :
                sys.stderr.write("Pass the Effective size analysis\n")
                sys.stderr.flush()
                return " "

    sub.call(f'mkdir -p {out}/EffectiveSize', shell=True)
    
    line = Eff + " -t " + str(th) + " -p " + param + " -o " + out + "/EffectiveSize"
    log = out + "/logs/effectivesize.log"
    O_var_param = open(f'{os.path.abspath(out)}/EffectiveSize/cmd', 'w')
    O_var_param.write(line+" &> "+log+"\n")
    return "EffectiveSize  "

'''    if verbose == "1" :
        sys.stderr.write(line + " &> " + log + "\n")
        sys.stderr.flush()
    with open(log, 'w') as outfile :
        value = sub.call(line, shell=True, stdout = outfile, stderr= outfile)
    
    if not value == 0 :
        sys.stderr.write("[ERROR] Check the log file : " + out + "/04_Population/logs/effectivesize.log\n")
        sys.stderr.flush()
'''

def AdmixtureProportion(out, verbose, param, sample) :
    bindir = os.path.abspath(os.path.dirname(__file__))
    AdmixtureProportion = bindir + "/script/AdmixtureProportion.pl"

    sys.stderr.write("\nAdmixture Proportion\n")
    sys.stderr.flush()

    for line in open(param, 'r') :
        line = line.strip()
        if 'ON/OFF' in line :
            flag = line.split('=')[1].strip()
            if flag.upper() == "OFF" :
                sys.stderr.write("Pass the Admixture Proportion analysis\n")
                sys.stderr.flush()
                return " "

    sub.call(f'mkdir -p {out}/AdmixtureProportion', shell=True)
    
    line = AdmixtureProportion + " -p " + param + " -s " + sample + " -o " + out + "/AdmixtureProportion"
    log = out + "/logs/admixtureproportion.log"
    
    O_var_param = open(f'{os.path.abspath(out)}/AdmixtureProportion/cmd', 'w')
    O_var_param.write(line+" &> "+log+"\n")
    return "AdmixtureProportion  "

'''    if verbose == "1" :
        sys.stderr.write(line + " &> " + log + "\n")
        sys.stderr.flush()
   
    with open(log, 'w') as outfile :
        value = sub.call(line, shell=True, stdout = outfile, stderr = outfile)
    
    if not value == 0 :
        sys.stderr.write("[ERROR] Check the log file : " + out + "/04_Population/logs/admixtureproportion.log\n")
        sys.stderr.flush()
'''

def LdDecay(out, verbose, param, sample) :
    bindir = os.path.abspath(os.path.dirname(__file__))
    LD_script = bindir + "/script/LdDecay.py"

    sys.stderr.write("\nLD Decay\n")
    sys.stderr.flush()

    for line in open(param, 'r') :
        line = line.strip()
        if 'ON/OFF' in line :
            flag = line.split('=')[1].strip()
            if flag.upper() == "OFF" :
                sys.stderr.write("Pass the LD Decay analysis\n")
                sys.stderr.flush()
                return " "

    sub.call(f'mkdir -p {out}/LdDecay', shell=True)
    
    line = "python3 " + LD_script + " -p " + param + " -s " + sample + " -o " + out + "/LdDecay"
    log = out + "/logs/lddecay.log"
    O_var_param = open(f'{os.path.abspath(out)}/LdDecay/cmd', 'w')
    O_var_param.write(line+" &> "+log+"\n")
    return "LdDecay  "

'''
    if verbose == "1" :
        sys.stderr.write(line + " &> " + log + "\n")
        sys.stderr.flush()
    
    with open(log, 'w') as outfile :
        value = sub.call(line, shell=True, stdout = outfile, stderr = outfile)
    
    if not value == 0 :
        sys.stderr.write("[ERROR] Check the log file : " + out + "/04_Population/logs/lddecay.log\n")
        sys.stderr.flush()
'''

def MSMC(out, verbose, param, sample) :
    bindir = os.path.abspath(os.path.dirname(__file__))

    sys.stderr.write("\nMSMC\n")
    sys.stderr.flush()
    for line in open(param, 'r') :
        line = line.strip()
        if 'ON/OFF' in line :
            flag = line.split('=')[1].strip()
            if flag.upper() == "OFF" :
                sys.stderr.write("Pass the MSMC analysis\n")
                sys.stderr.flush()
                return " "
    sub.call(f'mkdir -p {out}/MSMC', shell=True)

    MSMC_script = bindir + "/script/MSMC.pl"
    line = "perl " + MSMC_script + " -p " + param + " -s " + sample + " -o " + out + "/MSMC"
    log = out + "/logs/MSMC.log"
    O_var_param = open(f'{os.path.abspath(out)}/MSMC/cmd', 'w')
    O_var_param.write(line+" &> "+log+"\n")
    return "MSMC  "            


def SweepFinder2(out, verbose, param, sample) :
    bindir = os.path.abspath(os.path.dirname(__file__))

    sys.stderr.write("\nSweepFinder2\n")
    sys.stderr.flush()
    for line in open(param, 'r') :
        line = line.strip()
        if 'ON/OFF' in line :
            flag = line.split('=')[1].strip()
            if flag.upper() == "OFF" :
                sys.stderr.write("Pass the SweepFinder2 analysis\n")
                sys.stderr.flush()
                return " "
    sub.call(f'mkdir -p {out}/SweepFinder2', shell=True)

    SweepFinder2_script = bindir + "/script/SweepFinder2.pl"
    line = "perl " + SweepFinder2_script + " -p " + param + " -s " + sample + " -o " + out + "/SweepFinder2"
    log = out + "/logs/SweepFinder2.log"
    O_var_param = open(f'{os.path.abspath(out)}/SweepFinder2/cmd', 'w')
    O_var_param.write(line+" &> "+log+"\n")
    return "SweepFinder2  "


def Plink2(out, verbose, param, sample) :
    bindir = os.path.abspath(os.path.dirname(__file__))

    sys.stderr.write("\nPlink2\n")
    sys.stderr.flush()
    for line in open(param, 'r') :
        line = line.strip()
        if 'ON/OFF' in line :
            flag = line.split('=')[1].strip()
            if flag.upper() == "OFF" :
                sys.stderr.write("Pass the Plink2 analysis\n")
                sys.stderr.flush()
                return " "
    sub.call(f'mkdir -p {out}/Plink2', shell=True)
    
    Plink2_script = bindir + "/script/Plink2.pl"
    line = "perl " + Plink2_script + " -p " + param + " -s " + sample + " -o " + out + "/Plink2"
    log = out + "/logs/Plink2.log"
    O_var_param = open(f'{os.path.abspath(out)}/Plink2/cmd', 'w')
    O_var_param.write(line+" &> "+log+"\n")
    return "Plink2  "

def Treemix(out, verbose, param, sample) :
    bindir = os.path.abspath(os.path.dirname(__file__))

    sys.stderr.write("\nTreemix\n")
    sys.stderr.flush()
    for line in open(param, 'r') :
        line = line.strip()
        if 'ON/OFF' in line :
            flag = line.split('=')[1].strip()
            if flag.upper() == "OFF" :
                sys.stderr.write("Pass the Treemix analysis\n")
                sys.stderr.flush()
                return " "
    sub.call(f'mkdir -p {out}/Treemix', shell=True)

    Treemix_script = bindir + "/script/Treemix.pl"
    line = "perl " + Treemix_script + " -p " + param + " -s " + sample + " -o " + out + "/Treemix"
    log = out + "/logs/Treemix.log"
    O_var_param = open(f'{os.path.abspath(out)}/Treemix/cmd', 'w')
    O_var_param.write(line+" &> "+log+"\n")
    return "Treemix  "  


def main_pipe(args, dict_param, index) :
    sys.stderr.write("---------------Population--------------\n")
    sys.stderr.flush()
    

    if index == 0 :
        ParseInput(args.input, args.out)
    
    pop_param = Param.Population(args.out, dict_param)
    args.out = pop_param["outdir"]
    sub.call(f'mkdir -p {args.out}/logs', shell=True)

    

    running_analysis = ""
    #estimate faSize
    sys.stderr.write("\nEstimate reference fasta size...\n")
    ref_fa = os.path.abspath(args.ref)
    ref_size = ref_fa+".size"
    
    with open (ref_size,'w') as outfile:
        sub.call(f'faSize -detailed {ref_fa}', shell=True,stdout=outfile)
    #setting CMDS
    running_analysis += PCA(os.path.abspath(args.out), args.verbose, pop_param['PCA'], args.sample)
    running_analysis += PhylogeneticTree(os.path.abspath(args.out), args.verbose, pop_param['PhylogeneticTree'])
    running_analysis += Structure(os.path.abspath(args.out), args.verbose, pop_param['Structure'], args.sample)
    running_analysis += Fst(os.path.abspath(args.out), args.verbose, pop_param['Fst'], args.sample)
    running_analysis += EffectiveSize(os.path.abspath(args.out), args.verbose, pop_param['EffectiveSize'], args.threads)
    running_analysis += AdmixtureProportion(os.path.abspath(args.out), args.verbose, pop_param['AdmixtureProportion'], args.sample)
    running_analysis += LdDecay(os.path.abspath(args.out), args.verbose, pop_param['LdDecay'], args.sample)
    running_analysis += MSMC(os.path.abspath(args.out), args.verbose, pop_param['MSMC'], args.sample)
    running_analysis += SweepFinder2(os.path.abspath(args.out), args.verbose, pop_param['SweepFinder2'], args.sample)
    running_analysis += Plink2(os.path.abspath(args.out), args.verbose, pop_param['Plink2'], args.sample)
    running_analysis += Treemix(os.path.abspath(args.out), args.verbose, pop_param['Treemix'], args.sample)
    
    #run fork
    bindir = os.path.abspath(os.path.dirname(__file__))
    FORK_RUNNER = bindir + "/script/POP_fork.pl "
    CMD = "perl "+FORK_RUNNER+"  "+os.path.abspath(args.out)+"/   "  + running_analysis  +" "
    log = os.path.abspath(args.out)+"/logs/all.log"
    sys.stderr.write(CMD + " &> " + log + "\n")
    sys.stderr.flush()

    with open(log, 'w') as outfile :
        value = sub.call(CMD, shell=True, stdout = outfile, stderr = outfile)
    if value != 0 :
        sys.stderr.write("[ERROR] Check the log file : " + log+"\n")
        sys.stderr.flush()
        sys.exit()

    sys.stderr.write("\nFinish the population analysis result generating step\n\n")
    sys.stderr.flush()
