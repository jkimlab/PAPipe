import os
import re
import sys
import argparse

import ReadMapping
import VariantCalling
import Postprocessing
import Population

import subprocess as sub
from collections import defaultdict

def config() :
    parser = argparse.ArgumentParser(description = 'Pipeline of population analysis')
    parser.add_argument('-P', '--param', help='<Path> Parameter file', required=True)
    parser.add_argument('-I', '--input', help='<Path> Input file', required = True)
    parser.add_argument('-A', '--sample', help='<Path> Sample file', required=False)
    parser.add_argument('-O', '--out', default=".", help='<Path> Output directory (default current directory)', required=False)
    parser.add_argument('-J', '--job' , default=3, help='<Int> The number of jobs to process at one time (default 1)', required=False)
    parser.add_argument('-S', '--step', default="1-4", help='<Str> Select the steps you want up to 1-4 (default 1-4)', required=False)
    parser.add_argument('-V', '--verbose', default="0", help='<Int> If you want to see command line, set 1 (default 0)', required=False)
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
    if not os.path.isdir(args.out + "/param") :
        sub.call(f'mkdir {args.out}/param', shell=True)

    dict_param = ParseParam(args.param)
    
    sub_step = (args.step).split('-')
    for index, step in enumerate(range(int(min(sub_step)), int(max(sub_step))+1)) :
        if step == 1 :
            ReadMapping.main_pipe(args, dict_param, index)
        elif step == 2 :
            VariantCalling.main_pipe(args, dict_param, index)
        elif step == 3 :
            Postprocessing.main_pipe(args, dict_param, index)
        elif step == 4 :
            Population.main_pipe(args, dict_param, index)


    sys.stderr.write("\n\nFinish the population pipeline\n")
    sys.stderr.flush()
