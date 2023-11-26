#!/usr/bin/python
# -*- coding: UTF-8 -*-


"""
Author: Krisian Ullrich
date: December 2021
email: ullrich@evolbio.mpg.de
License: MIT
The MIT License (MIT)
Copyright (c) 2021 Kristian Ullrich
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""


import sys
import argparse
import textwrap
import gzip
import re


def multiple_replace(string, rep_dict):
    pattern = re.compile("|".join([re.escape(k) for k in sorted(rep_dict,key=len,reverse=True)]), flags=re.DOTALL)
    return pattern.sub(lambda x: rep_dict[x.group(0)], string)


def parse_lines(fin, fou, ind, keep, add):
    switchcount = 0
    removecount = 0
    outmissing = 0
    totalcount = 0
    for line in fin:
        if line[0] == '#':
            if(add):
                if(line.split('\t')[0] == '#CHROM'):
                    fou.write('##INFO=<ID=AA,Number=1,Type=String,Description="Ancestral Allele">\n')
                    fou.write(line)
                else:
                    fou.write(line)
            else:
                fou.write(line)
        if line[0] != '#':
            totalcount += 1
            linesplit = line.strip().split('\t')
            if linesplit[8 + ind] == './.' or linesplit[8 + ind] == '.|.':
                outmissing += 1
            if linesplit[8 + ind] == '0/0' or linesplit[8 + ind] == '0|0':
                if(add):
                    linesplit[7] = 'AA=' + linesplit[3] + ';' + linesplit[7]
                    fou.write('\t'.join(linesplit) + '\n')
                else:
                    fou.write(line)
            if linesplit[8 + ind] == '0/1' or linesplit[8 + ind] == '0|1' or linesplit[8 + ind] == '1/0' or linesplit[8 + ind] == '1|0':
                removecount += 1
                if keep:
                    fou.write(line)
            if linesplit[8 + ind] == '1/1' or linesplit[8 + ind] == '1|1':
                switchcount += 1
                REF = linesplit[4]
                ALT = linesplit[3]
                linesplit[3] = REF
                linesplit[4] = ALT
                changed = linesplit[:9] + [multiple_replace('\t'.join(linesplit[9:]),{'0':'1', '1':'0'})]
                if(add):
                    changed[7] = 'AA=' + changed[3] + ';' + changed[7]
                    fou.write('\t'.join(changed) + '\n')
                else:
                    fou.write('\t'.join(changed) + '\n')
    print('Parsed ' + str(totalcount) + ' sites.')
    print('Removed ' + str(outmissing) + ' sites due to missing allele info in switch individual.')
    if keep:
        print('Kept ' + str(removecount) + ' sites with undefined ancestral state.')
    if not keep:
        print('Removed ' + str(removecount) + ' sites with undefined ancestral state.')
    print('Switched REF and ALT allele for ' + str(switchcount) + ' sites.')


def main():
    parser = argparse.ArgumentParser(prog='polarizeVCFbyOutgroup', description='Switch REF and ALT allele of a vcf file, if specified individual is homozygous ALT.', formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('-vcf', help=textwrap.dedent('''\
specify vcf input file
vcf file should only contain bi-allelic sites and only GT field
bcftools commands to retain only bi-allelic sites and GT field:
(bcftools view -h VCFFILE;
 bcftools query -f
 "%%CHROM\\t%%POS\\t%%ID\\t%%REF\\t%%ALT\\t%%QUAL\\t%%FILTER\\t%%INFO\\tGT\\t[%%GT\\t]\\n" VCFFILE)
| cat | bcftools view -m2 -M2 -v snps
 '''))
    parser.add_argument('-out', help='specify output file')
    parser.add_argument('-ind', type=int, help='specify individual idx to be used for switch REF and ALT allele')
    parser.add_argument('-keep', action='store_true', help='specify if undefined ancestral states should be kept in output')
    parser.add_argument('-add', action='store_true', help='add ancestral state to INFO field')
    args = parser.parse_args()
    print(args)
    if args.vcf is None:
        parser.print_help()
        sys.exit('Please specify vcf input file')
    if args.out is None:
        parser.print_help()
        sys.exit('Please specify output file')
    if args.ind is None:
        parser.print_help()
        sys.exit('Please specify individual idx')
    if args.out.endswith('gz'):
        with gzip.open(args.out, 'wt') as fou:
            if args.vcf.endswith('gz'):
                with gzip.open(args.vcf, 'rt') as fin:
                    parse_lines(fin, fou, args.ind, args.keep, args.add)
            if not args.vcf.endswith('gz'):
                with open(args.vcf, 'rt') as fin:
                    parse_lines(fin, fou, args.ind, args.keep, args.add)
    if not args.out.endswith('gz'):
        with open(args.out, 'wt') as fou:
            if args.vcf.endswith('gz'):
                with gzip.open(args.vcf, 'rt') as fin:
                    parse_lines(fin, fou, args.ind, args.keep, args.add)
            if not args.vcf.endswith('gz'):
                with open(args.vcf, 'rt') as fin:
                    parse_lines(fin, fou, args.ind, args.keep, args.add)


if __name__ == '__main__':
    main()
