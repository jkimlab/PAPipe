import os
import re
import sys
import argparse

import ReadMapping
import VariantCalling
import Postprocessing
import Population
import ReadQC

import subprocess as sub
from collections import defaultdict

def config() :
    parser = argparse.ArgumentParser(description = 'Pipeline of population analysis')
    parser.add_argument('-P', '--param', help='<Path> Parameter file', required=True)
    parser.add_argument('-I', '--input', help='<Path> Input file', required = True)
    parser.add_argument('-A', '--sample', help='<Path> Sample file', required=False)
    parser.add_argument('-O', '--out', default="./test", help='<Path> Output directory (default current directory)', required=False)
    parser.add_argument('-J', '--job' , default=3, help='<Int> The number of jobs to process at one time (default 1)', required=False)
    parser.add_argument('-V', '--verbose', default="1", help='<Int> If you want to see command line, set 1 (default 0)', required=False)
    parser.add_argument('-T', '--threads', default=5, help='<Int> Threads number of cores (default 5)', required=False)
    parser.add_argument('-M', '--memory', default=10, help='<Int> Memory allocation (default 10)', required=False)
    args = parser.parse_args()

    return args


def tree() :
    return defaultdict(tree)

def ParseParam(param) :
    dict_param = tree()

    step = ""
    for line in open(param, 'r') :
        line = line.strip()
        if re.match(r'^\s*$', line) :
            continue
        elif line.startswith('####') :
            step = (line.replace('#', '')).strip()
        elif not line.startswith('#') :
            var, path = [i.strip() for i in line.split('=')]
            path = path.replace("\"", "")
            dict_param[step][var] = path

    return dict_param


if __name__ == "__main__" :
    sys.stderr.write("-----------------Start-----------------\n")
    sys.stderr.flush()

    args = config()

    dict_param = ParseParam(args.param)
    sub_step = (dict_param["Global"]["step"]).split('-')
    args.out = dict_param["Global"]["outdir"]
    sub.call(f'mkdir -p {args.out}/param', shell=True)
    args.threads = dict_param["Global"]["threads"]
    args.ref = dict_param["Global"]["reference"]

    ref_fa =os.path.abspath(args.ref)
    sub.call(f'gzip -d {ref_fa}',shell=True)
    ref_fa = ref_fa[0:-3]
    ref_size = ref_fa+".size"
    with open (ref_size,'w') as outfile:
                sub.call(f'faSize -detailed {ref_fa}', shell=True,stdout=outfile)
    args.ref = ref_fa

    for index, step in enumerate(range(int(min(sub_step)), int(max(sub_step))+1)) :
        if step == 0:
            if os.path.exists(args.out+"/00_ReadQC/complete"):
                sys.stderr.write("Skip ReadQC\n\n")
                sys.stderr.flush()
            else:
                args.input = ReadQC.main_pipe(args, dict_param, index)
                sub.call(f'touch  {args.out}/00_ReadQC/complete', shell=True)
        if step == 1 :
            if os.path.exists(args.out+"/01_ReadMapping/complete"):
                sys.stderr.write("Skip ReadMapping\n\n")
                sys.stderr.flush()
            else:
                ReadMapping.main_pipe(args, dict_param, index)
                sub.call(f'touch  {args.out}/01_ReadMapping/complete', shell=True)
        elif step == 2 :
            if os.path.exists(args.out+"/02_VariantCalling/complete"):
                sys.stderr.write("Skip VariantCalling\n\n")
                sys.stderr.flush()
            else:
                VariantCalling.main_pipe(args, dict_param, index)
                sub.call(f'touch  {args.out}/02_VariantCalling/complete', shell=True)
        elif step == 3 :
            if os.path.exists(args.out+"/03_Postprocessing/complete"):
                sys.stderr.write("Skip Postprocessing\n\n")
                sys.stderr.flush()
            else:
                Postprocessing.main_pipe(args, dict_param, index)
                sub.call(f'touch  {args.out}/03_Postprocessing/complete', shell=True)
        elif step == 4 :
            Population.main_pipe(args, dict_param, index)


    sys.stderr.write("\n\nFinish the population pipeline\n")
    sys.stderr.flush()
