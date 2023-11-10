import os
import re
import sys
import argparse

import subprocess as sub
from collections import defaultdict

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
                if not os.path.isdir(out + "/02_VariantCalling/") :
                    sub.call(f'mkdir {out}/02_VariantCalling', shell=True)
                if not os.path.isdir(out + "/02_VariantCalling/VariantCalling") :
                    sub.call(f'mkdir {out}/02_VariantCalling/VariantCalling', shell=True)
                if not os.path.isdir(out + "/02_VariantCalling/VariantCalling/FINAL") :
                    sub.call(f'mkdir {out}/02_VariantCalling/VariantCalling/FINAL', shell=True)

                sub.call(f'ln -s {line} {out}/02_VariantCalling/VariantCalling/FINAL/', shell=True)

            elif step == "Plink" :
                if not os.path.isdir(out + "/03_Postprocessing") :
                    sub.call(f'mkdir {out}/03_Postprocessing', shell=True)
                if not os.path.isdir(out + "/03_Postprocessing/plink") :
                    sub.call(f'mkdir {out}/03_Postprocessing/plink', shell=True)

                sub.call(f'ln -s {line}* {out}/03_Postprocessing/plink/', shell=True)

            elif step == "Hapmap" :
                if not os.path.isdir(out + "/03_Postprocessing") :
                    sub.call(f'mkdir {out}/02_Postprocessing', shell=True)
                if not os.path.isdir(out + "/03_Postprocessing/Hapmap") :
                    sub.call(f'mkdir {out}/03_Postprocessing/Hapmap', shell=True)

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
                return

    if not os.path.isdir(out + "/04_Population/PCA") :
        sub.call(f'mkdir {out}/04_Population/PCA', shell=True)
    line = PCA + " -p " + param + " -s " + sample + " -o " + out + "/04_Population/PCA"
    log = out + "/04_Population/logs/pca.log"
    
    if verbose == "1" :
        sys.stderr.write(line + " &> " + log + "\n")
        sys.stderr.flush()
    
    with open(log, 'w') as outfile :
        value = sub.call(line, shell=True, stdout = outfile, stderr = outfile)
    if not value == 0 :
        sys.stderr.write("[ERROR] Check the log file : " + out + "/04_Population/logs/pca.log\n")
        sys.stderr.flush()


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
                return

    if not os.path.abspath(out + "/04_Population/PhylogeneticTree") :
        sub.call(f'mkdir {out}/04_Population/PhylogeneticTree', shell=True)
    line = PhylogeneticTree + " -p " + param + " -o " + out + "/04_Population/PhylogeneticTree"
    log = out + "/04_Population/logs/snphylo.log"

    if verbose == "1" :
        sys.stderr.write(line + " &> " + log + "\n")
        sys.stderr.flush()

    with open(log, 'w') as outfile :
        value = sub.call(line, shell=True, stdout = outfile, stderr = outfile)
    if not value == 0 :
        sys.stderr.write("[ERROR] Check the log file : " + out + "/04_Population/logs/snphylo.log\n")
        sys.stderr.flush()


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
                return 

    if not os.path.abspath(out + "/04_Population/Structure") :
        sub.call(f'mkdir {out}/04_Population/Structure', shell=True)
    
    line = Structure + " -p " + param + " -s " + os.path.abspath(sample) + " -o " + out + "/04_Population/Structure"
    log = out + "/04_Population/logs/structure.log"
    
    if verbose == "1" :
        sys.stderr.write(line + " &> " + log + "\n")
        sys.stderr.flush()

    with open(log, 'w') as outfile :
        value = sub.call(line, shell=True, stdout = outfile, stderr = outfile)
    
    if not value == 0 :
        sys.stderr.write("[ERROR] Check the log file : " + out + "/04_Population/logs/structure.log\n")
        sys.stderr.flush()


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
                return

    if not os.path.abspath(out + "/04_Population/Fst") :
        sub.call(f'mkdir {out}/04_Population/Fst', shell=True)
    
    line = Fst + " -p " + param + " -o " + out + "/04_Population/Fst -s " + sample
    log = out + "/04_Population/logs/fst.log"

    if verbose == "1" :
        sys.stderr.write(line + " &> " + log + "\n")
        sys.stderr.flush()

    with open(log, 'w') as outfile :
        value = sub.call(line, shell=True, stdout = outfile, stderr = outfile)
    
    if not value == 0 :
        sys.stderr.write("[ERROR] Check the log file : " + out + "/04_Population/logs/fst.log\n")
        sys.stderr.flush()


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
                return

    if not os.path.abspath(out + "/04_Population/EffectiveSize") :
        sub.call(f'mkdir {out}/04_Population/EffectiveSize', shell=True)
    
    line = Eff + " -t " + str(th) + " -p " + param + " -o " + out + "/04_Population/EffectiveSize"
    log = out + "/04_Population/logs/effectivesize.log"

    if verbose == "1" :
        sys.stderr.write(line + " &> " + log + "\n")
        sys.stderr.flush()
    with open(log, 'w') as outfile :
        value = sub.call(line, shell=True, stdout = outfile, stderr= outfile)
    
    if not value == 0 :
        sys.stderr.write("[ERROR] Check the log file : " + out + "/04_Population/logs/effectivesize.log\n")
        sys.stderr.flush()


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
                return

    if not os.path.isdir(out + "/04_Population/AdmixtureProportion") :
        sub.call(f'mkdir {out}/04_Population/AdmixtureProportion', shell=True)
    
    line = AdmixtureProportion + " -p " + param + " -s " + sample + " -o " + out + "/04_Population/AdmixtureProportion"
    log = out + "/04_Population/logs/admixtureproportion.log"
    
    if verbose == "1" :
        sys.stderr.write(line + " &> " + log + "\n")
        sys.stderr.flush()
   
    with open(log, 'w') as outfile :
        value = sub.call(line, shell=True, stdout = outfile, stderr = outfile)
    
    if not value == 0 :
        sys.stderr.write("[ERROR] Check the log file : " + out + "/04_Population/logs/admixtureproportion.log\n")
        sys.stderr.flush()


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
                return

    if not os.path.isdir(out + "/04_Population/LdDecay") :
        sub.call(f'mkdir {out}/04_Population/LdDecay', shell=True)
    
    line = "python3 " + LD_script + " -p " + param + " -s " + sample + " -o " + out + "/04_Population/LdDecay"
    log = out + "/04_Population/logs/lddecay.log"

    if verbose == "1" :
        sys.stderr.write(line + " &> " + log + "\n")
        sys.stderr.flush()
    
    with open(log, 'w') as outfile :
        value = sub.call(line, shell=True, stdout = outfile, stderr = outfile)
    
    if not value == 0 :
        sys.stderr.write("[ERROR] Check the log file : " + out + "/04_Population/logs/lddecay.log\n")
        sys.stderr.flush()


def main_pipe(args, dict_param, index) :
    sys.stderr.write("---------------Population--------------\n")
    sys.stderr.flush()
    
    if not os.path.isdir(args.out + "/04_Population") :
        sub.call(f'mkdir {args.out}/04_Population', shell=True)
    if not os.path.isdir(args.out + "/04_Population/logs") :
        sub.call(f'mkdir {args.out}/04_Population/logs', shell=True)

    if index == 0 :
        ParseInput(args.input, args.out)
    
    pop_param = Param.Population(args.out, dict_param)
    PCA(os.path.abspath(args.out), args.verbose, pop_param['PCA'], args.sample)
    PhylogeneticTree(os.path.abspath(args.out), args.verbose, pop_param['PhylogeneticTree'])
    Structure(os.path.abspath(args.out), args.verbose, pop_param['Structure'], args.sample)
    Fst(os.path.abspath(args.out), args.verbose, pop_param['Fst'], args.sample)
    EffectiveSize(os.path.abspath(args.out), args.verbose, pop_param['EffectiveSize'], args.threads)
    AdmixtureProportion(os.path.abspath(args.out), args.verbose, pop_param['AdmixtureProportion'], args.sample)
    LdDecay(os.path.abspath(args.out), args.verbose, pop_param['LdDecay'], args.sample)
    sys.stderr.write("\nFinish the population analysis result generating step\n\n")
    sys.stderr.flush()
