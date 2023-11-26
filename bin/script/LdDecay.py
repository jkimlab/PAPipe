import os
import re
import sys
import argparse

import subprocess as sub
from collections import defaultdict
from multiprocessing import Pool

##Definition of variables
PopLDdecay = ""
VCF = ""
Dist = []
Breed = []

#Argument
def config() :
    parser = argparse.ArgumentParser(description='LD analysis')
    parser.add_argument('-p', '--param', help='<Path> paramenter file', required=True)
    parser.add_argument('-s', '--sample', help='<Path> sample file', required=True)
    parser.add_argument('-o', '--out', help='<Path> Output directory', required=True)
    args = parser.parse_args()
    return args

#Function for subprocess
def multi_run_wrapper(args) :
    return f(*args)

def f(x, log) :
    with open(log, 'w') as outfile :
        value = sub.call(x, shell=True, stdout = outfile, stderr = outfile)
    return value


#Parsing to parameter file
def param_file(param) :
    global PopLDdecay
    global VCF
    global Dist

    for line in open(param, 'r') :
        line = line.strip()
        if line.startswith('#') :
            continue
        elif re.match(r'^\s*$', line) :
            continue
        else :
            match = ((line.split('='))[0]).strip()
            path = ((line.split('='))[1]).strip()
            if match == "PopLDdecay_BIN" :
                PopLDdecay = path
            elif match == "VCF" : 
                VCF = path
            elif match == "MaxDist" :
                path = path.strip()
                for dis in path.split(',') :
                    dis = dis.strip()
                    Dist.append(dis)
                if len(Dist) == 0 :
                    Dist.append(500)
                    Dist.append(1000)
                    Dist.append(5000)
                    Dist.append(10000)


def make_samplelist(out, sample) :
    global Breed
    BRE = ""

    sys.stderr.write("Make the sample list\n")
    sys.stderr.flush()

    for line in open(sample, 'r') :
        line = line.strip()
        [sample, sex, breed] = [i.strip() for i in line.split()]
        
        if breed != BRE :
            O_S = open(f'{out}/{breed}.list', 'w')
            O_S.write(breed + "_" + sample + "\n")
            BRE = breed
            Breed.append(breed)
        else :
            O_S.write(breed + "_" + sample + "\n")


def LD_analysis(out) :
    global PopLDdecay
    global VCF
    global Dist
    global Breed

    sys.stderr.write("\n\nCaluculate the r^2 by distance\n")
    sys.stderr.flush()

    CMD = []
    for dist in Dist :
        sub.call(f'mkdir {out}/{dist}', shell=True)
        os.system("mkdir " + out + "/" + dist)
        sys.stderr.write("\n\n#" + dist + "\n")
        sys.stderr.flush()
        CMD.clear()
        for breed in Breed :
            line, log = "", ""
            line = PopLDdecay + "/PopLDdecay -InVCF " + VCF + " -OutStat " + out + "/" + dist + "/" + breed + ".stat.gz -SubPop " + out + "/" + breed + ".list -MaxDist " + dist
            log = out + "/" + dist + "/" + breed + ".log"
        
            sys.stderr.write(breed + "\n" + line + " 2> " + log + "\n")
            sys.stderr.flush()
            CMD.append([line, log])

        with Pool(5) as p :
            value = p.map(multi_run_wrapper, CMD)    
            check = 0
            for i in range(len(value)) :
                if not value[i] == 0 :
                    check += 1
                    sys.stderr.write("[ERROR] Check the log file : " + (CMD[i])[1] + "\n")
                    sys.stderr.flush()
            if not check == 0 :
                sys.exit(1)


def Draw(out) :
    global PopLDdecay
    global Dist
    global Breed

    CMD = []
    sys.stderr.write("\n\nDrawing\n")
    sys.stderr.flush()

    for dist in Dist :
        line, log ="", ""
        sub.call(f'mkdir {out}/{dist}/Plot', shell=True)
        sys.stderr.write("\n\n#" + dist + "\n")
        sys.stderr.flush()
        os.system("mkdir " + out + "/" + dist + "/Plot")
        O_L = open(f'{out}/{dist}/Plot/Multi.list', 'w')
        for breed in Breed :
            O_L.write(out + "/" + dist + "/" + breed + ".stat.gz\t" + breed + "\n")
        O_L.close()
        
        line = PopLDdecay + "/Plot_MultiPop.pl -inList " + out + "/" + dist + "/Plot/Multi.list -output " + out + "/" + dist + "/Plot/out"
        log = out + "/" + dist + "/Plot/log"
        
        sys.stderr.write(line + " 2> " + log + "\n")
        sys.stderr.flush()
        CMD.append([line, log])

    with Pool(5) as p :
        value = p.map(multi_run_wrapper, CMD)
        check = 0
        for i in range(len(value)) :
            if not value[i] == 0 :
                check += 1
                sys.stderr.write("[ERROR] Check the log file : " + (CMD[i])[1] + "\n")
                sys.stderr.flush()
        if not check == 0 :
            sys.exit(1)
        #p.map(f,cmd)



def main() :
    args = config()
    param_file(args.param)
    make_samplelist(os.path.abspath(args.out), args.sample)
    LD_analysis(os.path.abspath(args.out))
    Draw(os.path.abspath(args.out))


if __name__ == '__main__' :
    main()
