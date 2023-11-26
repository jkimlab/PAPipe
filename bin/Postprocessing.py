import os
import re
import sys
import glob
import Param

import subprocess as sub
from collections import defaultdict


def tree() :
    return defaultdict(tree)

Plink = ""
VCFTOOLS = ""
Plink_option = tree()
bindir = os.path.abspath(os.path.dirname(__file__))
Hapmap = bindir + "/script/vcf2HapMap.pl"
SAMPLE_NAME = ""
VCF = ""
new_vcf = ""

def f(x, log) :
    with open(log, 'w') as outfile :
        value = sub.call(x, shell=True, stdout = outfile, stderr = outfile)
    return value

def param(dict_param) :
    global Plink
    global VCFTOOLS
    global Plink_option
    global SAMPLE_NAME
    global VCF
    
    flag = 0
    sample = 0
    Plink_option["plink_option_line"] = ""
    for line in open(dict_param, 'r') :
        line = line.strip()
        if re.match(r'^\s*$', line) :
            continue
        elif line.startswith('#') :
            continue
        elif line.startswith('<') :
            sample += 1
            SAMPLE_NAME = line[1:len(line)-1].strip()
        else :
            match = ((line.split('='))[0]).strip()
            if match == "Plink" :
                path = ((line.split('='))[1]).strip()
                Plink = path
            elif match == "VCFTOOLS" :
                path = ((line.split('='))[1]).strip()
                VCFTOOLS = path
            else :
                if sample == 0 :
                    path = ((line.split('='))[1]).strip()
                    Plink_option[match] = path
                    if match == "allow_chr" :
                        flag += 1
                    elif match == "not_allow_chr" :
                        if flag > 0 :
                            sys.stderr.write("ERROR : conflict the chromosome option")
                            sys.stderr.flush()
                            sys.exit()
                    elif match == "plink_option_line" :
                        path = path + " "        
                        Plink_option[match] = path

                else :
                    VCF = line
    
def ParseInput(input_, out) :
    dict_input = tree()

    sample, step, flag, check = "", "", 0, 0
    for line in open(input_, 'r') :
        line = line.strip()
        if re.match(r'\s*$', line) :
            continue
        elif line.startswith('####') :
            match = (line.replace('####', '')).strip()
            if not match == "Postprocessing" :
                if check == 0 :
                    sys.stderr.write("Require the postprocessing input file\n")
                    sys.stderr.flush()
                    sys.exit()
                else :
                    step = 4
            else :
                step = 3
                check += 1
        elif line.startswith('<') :
            sample = (line.replace('<', '').replace('>', '')).strip()
        elif not line.startswith('#') :
            if step == 3 :
                sub.call(f'mkdir -p {out}/02_VariantCalling/VariantCalling/FINAL', shell=True)
                sub.call(f'ln -sf {line} {out}/02_VariantCalling/VariantCalling/FINAL/', shell=True)
            elif step == 4 :
                if not os.path.isdir(out + "/01_ReadMapping/") :
                    sub.call(f'mkdir {out}/01_ReadMapping', shell=True)
                if not os.path.isdir(out + "/01_ReadMapping/04.ReadRegrouping") :
                    sub.call(f'mkdir {out}/01_ReadMapping/04.ReadRegrouping', shell=True)
                    
                sub.call(f'ln -s {line} {out}/01_ReadMapping/04.ReadRegrouping/{sample}.bam', shell=True)

def VCF_Filt(out, th, verbose) :
    global VCFTOOLS
    global Plink_option
    global SAMPLE_NAME
    global VCF
    global new_vcf

    sys.stderr.write("\nVCF filtering by chrmosome\n")
    sys.stderr.flush()
    
    line = ""
    log = ""
    missingvarID = '@:#';
    if Plink_option['allow_chr'] :
        if not os.path.isdir(out + "/03_Postprocessing/VCF_Filt/") :
            sub.call(f'mkdir {out}/03_Postprocessing/VCF_Filt', shell=True)

        if ".gz" in VCF :
            new_vcf = (os.path.basename(VCF)).replace(".vcf.gz", "") + ".chrflt"
            line = VCFTOOLS +" --gzvcf " + VCF + " --chr " + str(Plink_option['allow_chr']) + " --out " + out + "/03_Postprocessing/VCF_Filt/" + new_vcf + " --recode"
            log = out + "/03_Postprocessing/logs/vcf_filt.log"
        else :
            new_vcf = (os.path.basename(VCF)).replace(".vcf", "") + ".chrflt"
            line = VCFTOOLS + " --vcf " + VCF + " --chr " + str(Plink_option['allow_chr']) + " --out " + out + "/03_Postprocessing/VCF_Filt/" + new_vcf + " --recode"
            log = out + "/03_Postprocessing/logs/vcf_filt.log"
    elif Plink_option['not_allow_chr'] :
        if not os.path.isdir(out + "/03_Postprocessing/VCF_Filt/") :
            sub.call(f'mkdir {out}/03_Postprocessing/VCF_Filt', shell=True)

        if ".gz" in VCF :
            new_vcf = (os.path.basename(VCF)).replace(".vcf.gz", "") + ".chrflt"
            line = VCFTOOLS + " --gzvcf " + VCF + " --not-chr " + str(Plink_option['not_allow_chr']) + " --out " + out + "/03_Postprocessing/VCF_Filt/" + new_vcf + " --recodd"
            log = out + "/03_Postprocessing/logs/vcf_filt.log"
        else :
            new_vcf = (os.path.basename(VCF)).replace(".vcf", "") + ".chrflt"
            line = VCFTOOLS + " --vcf " + VCF + " --not-chr " + str(Plink_option['not_allow_chr']) + " --out " + out + "/03_Postprocessing/VCF_Filt/" + new_vcf + " --recode"
            log = out + "/03_Postprocessing/logs/vcf_filt.log"
    else :
        sys.stderr.write("no filtering\n")
        sys.stderr.flush()
        return


    if verbose == "1" :
        sys.stderr.write(line + " &> " + log + "\n")
        sys.stderr.flush()


    value = f(line, log)
    
    if not value == 0 :
        sys.stderr.write("[ERROR] Check the log file : " + out + "/03_Postprocessing/logs/vcf_filt.log\n")
        sys.stderr.flush()
        sys.exit()
    else :
        for file_ in os.listdir(out + "/03_Postprocessing/VCF_Filt") :
            line = "bgzip -c " + out + "/03_Postprocessing/VCF_Filt/" + file_ + " > " + out + "/03_Postprocessing/VCF_Filt/" + file_ + ".gz"
            if verbose == "1" : 
                sys.stderr.write(line + "\n")
                sys.stderr.flush()

            sub.call(line, shell=True)

            line = "tabix -p vcf " + out + "/03_Postprocessing/VCF_Filt/" + file_ + ".gz"
            if verbose == "1" :
                sys.stderr.write(line + "\n")
                sys.stderr.flush()

            sub.call(line, shell=True)
            sub.call(f'rm -rf {out}/03_Postprocessing/VCF_Filt/{file_}', shell=True)



def PLINK(out, th, verbose) :
    global Plink
    global VCFTOOLS
    global Plink_option
    global SAMPLE_NAME
    global VCF
    
    sys.stderr.write("\nPlink\n")
    sys.stderr.flush()

    if not os.path.isdir(out + "/03_Postprocessing/plink") :
        sub.call(f'mkdir {out}/03_Postprocessing/plink', shell=True)

    line = ""
    log = ""
    if Plink_option['allow_chr'] :
        line = Plink + " --threads " + str(th) + "  --set-missing-var-ids @:#   --geno " + str(Plink_option['geno']) + " --maf " + str(Plink_option['maf']) + " --hwe " + str(Plink_option['hwe']) + " --make-bed --chr-set " + str(Plink_option['chr-set']) + " --chr " + str(Plink_option['allow_chr']) + " " + str(Plink_option['plink_option_line']) + "--vcf " + VCF + " --out " + out + "/03_Postprocessing/plink/" + SAMPLE_NAME
        log = out + "/03_Postprocessing/logs/plink_1.log"
    elif Plink_option['not_allow_chr'] :
        line = Plink + " --threads " + str(th) + "  --set-missing-var-ids @:# --geno " + str(Plink_option['geno']) + " --maf " + str(Plink_option['maf']) + " --hwe " + str(Plink_option['hwe']) + " --make-bed --chr-set " + str(Plink_option['chr-set']) + " --not-chr " + str(Plink_option['not_allow_chr']) + " " + str(Plink_option['plink_option_line']) + "--vcf " + VCF + " --out " + out + "/03_Postprocessing/plink/" + SAMPLE_NAME
        log = out + "/03_Postprocessing/logs/plink_1.log"
    else :
        line = Plink + " --threads " + str(th) + "  --set-missing-var-ids @:#  --geno " + str(Plink_option['geno']) + " --maf " + str(Plink_option['maf']) + " --hwe " + str(Plink_option['hwe']) + " --make-bed --chr-set " + str(Plink_option['chr-set']) + " " + str(Plink_option['plink_option_line']) + "--vcf " + VCF + " --out " + out + "/03_Postprocessing/plink/" + SAMPLE_NAME
        log = out + "/03_Postprocessing/logs/plink_1.log"


    if verbose == "1" :
        sys.stderr.write(line + " &> " + log + "\n")
        sys.stderr.flush()

    value = f(line, log)
    if not value == 0 :
        sys.stderr.write('[ERROR] Check the log file : ' + log + "\n")
        sys.stderr.flush()
        sys.exit()

    line = ""
    log = ""
    if os.path.isdir(out + "/03_Postprocessing/VCF_Filt/") :
        for file_ in os.listdir(out + "/03_Postprocessing/VCF_Filt/") :
            if not ".tbi" in file_ :
                if '.gz' in file_ :
                    line = VCFTOOLS + " --gzvcf " + out + "/03_Postprocessing/VCF_Filt/" + file_ + " --out " + out + "/03_Postprocessing/plink/" + SAMPLE_NAME + " --plink"
                    log = out + "/03_Postprocessing/logs/plink_2.log"
                else :
                    line = VCFTOOLS + " --vcf " + out + "/03_Postprocessing/VCF_Filt/" + file_ + " --out " + out + "/03_Postprocessing/plink/" + SAMPLE_NAME + " --plink"
                    log = out + "/03_Postprocessing/logs/plink_2.log"
    else :
        if '.gz' in VCF :
            line = VCFTOOLS + " --gzvcf " + VCF + " --out " + out + "/03_Postprocessing/plink/" + SAMPLE_NAME + " --plink"
            log = out + "/03_Postprocessing/logs/plink_2.log"
        else :
            line = VCFTOOLS + " --vcf " + VCF + " --out " + out + "/03_Postprocessing/plink/" + SAMPLE_NAME + " --plink"
            log = out + "/03_Postprocessing/logs/plink_2.log"

    if verbose == "1" :
        sys.stderr.write(line + " &> " + log + "\n")
        sys.stderr.flush()

    value = f(line, log)
    if not value == 0 :
        sys.stderr.write('[ERROR] Check the log file : ' + log + "\n")
        sys.stderr.flush()
        sys.exit()



def HAPMAP(out, verbose) :
    global Hapmap
    global VCF

    sys.stderr.write("\nHapmap\n")
    sys.stderr.flush()

    if not os.path.isdir(out + "/03_Postprocessing/Hapmap") :
        sub.call(f'mkdir {out}/03_Postprocessing/Hapmap', shell=True)
    cmd = []

    ling = ""
    log = ""
    if os.path.isdir(out + "/03_Postprocessing/VCF_Filt") :
        for file_ in os.listdir(out + "/03_Postprocessing/VCF_Filt") :
            if not ".tbi" in file_ :
                line = Hapmap + " " + out + "/03_Postprocessing/VCF_Filt/" + file_ + " " + out + "/03_Postprocessing/Hapmap"
                log = out + "/03_Postprocessing/logs/hapmap.log"
    else :
        line = Hapmap + " " + VCF + " " + out + "/03_Postprocessing/Hapmap"
        log = out + "/03_Postprocessing/logs/hapmap.log"
    cmd.append(line)

    if verbose == "1" :
        sys.stderr.write(line + " &> " + log + "\n")
        sys.stderr.flush()
   
    value = f(line, log)
    
    if not value == 0 :
        sys.stderr.write("[ERROR] Check the log file : " + out + "/03_Postprocessing/logs/hapmap.log\n")
        sys.stderr.flush()
        sys.exit()



def main_pipe(args, dict_param, index) :
    global Plink
    global Plink_option

    sys.stderr.write("------------Postprocessing-------------\n")
    sys.stderr.flush()

    if not os.path.isdir(args.out + "/03_Postprocessing") :
        sub.call(f'mkdir {args.out}/03_Postprocessing', shell=True)
    if not os.path.isdir(args.out + "/03_Postprocessing/logs") :
        sub.call(f'mkdir {args.out}/03_Postprocessing/logs', shell=True)
    
    if index == 0 :
        ParseInput(args.input, args.out)
    
    post_param = Param.Postprocessing(args.out, dict_param)
    param(post_param.name)
    VCF_Filt(os.path.abspath(args.out), args.threads, args.verbose)
    PLINK(os.path.abspath(args.out), args.threads, args.verbose)
    sys.stderr.write("Success the Plink\n")
    sys.stderr.flush()
    HAPMAP(os.path.abspath(args.out), args.verbose)
    sys.stderr.write("Success the Hapmap\n")
    sys.stderr.flush()
    sys.stderr.write("\nFinish the format converting or data filtering step\n\n")
