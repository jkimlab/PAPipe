import re
import os
import sys

import subprocess as sub
from datetime import datetime
from collections import defaultdict


def tree() :
    return defaultdict(tree)

def ReadQC(out, dict_param):
    O_pre_param = open(f'{os.path.abspath(out)}/param/ReadQC.txt', 'w')
    O_pre_param.write("outdir  "+out+"/00_ReadQC/"+"\n")
    O_pre_param.write("threads  "+dict_param["Global"]["threads"]+"\n")
    O_pre_param.write("### programs ### \n")
    for step in dict_param :
        if step == "ReadQC" :
            for var in dict_param[step] :
                O_pre_param.write(var + "  " + dict_param[step][var] + "\n")
    #return O_pre_param

def ReadMapping(out, dict_param, dict_input) :
    O_pre_param = open(f'{os.path.abspath(out)}/param/ReadMapping.txt', 'w')
    
    for step in dict_param :
        if step == "ReadMapping" :
            for var in dict_param[step] :
                O_pre_param.write(var + " = " + dict_param[step][var] + "\n")


    for sample in dict_input :
        O_pre_param.write("<" + sample + ">\n")
        for lib in dict_input[sample] :
            O_pre_param.write("[" + lib + "]\n")
            for read in dict_input[sample][lib] :
                O_pre_param.write(dict_input[sample][lib][read] + "\n")

    O_pre_param.close()
    return O_pre_param

def VariantCalling(out, dict_param) :
    O_var_param = open(f'{os.path.abspath(out)}/param/VariantCalling.txt', 'w')

    if dict_param["VariantCalling"]["VCF_prefix"] == "" :
        sys.stderr.write("Fill the VCF_prefix name in parameter file\n")
        sys.stderr.flush()
        sys.exit()

    for step in dict_param :
        if step == "VariantCalling" :
            for var in dict_param[step] :
                O_var_param.write(var + " = " + dict_param[step][var] + "\n")

    if os.path.isdir(out + "/01_ReadMapping/04.ReadRegrouping") :
        for file_ in os.listdir(out + "/01_ReadMapping/04.ReadRegrouping") :
            basename = os.path.basename(file_)
            if not ("bam" in basename):
                continue
            basename = basename.replace(".addRG.marked.sort.bam", '')
            basename = basename.replace(".bam", '')
            O_var_param.write("<" + basename + ">\n")
            O_var_param.write(out + "/01_ReadMapping/04.ReadRegrouping/" + file_ + "\n")

    O_var_param.close()
    return O_var_param

def Postprocessing(out, dict_param) :
    O_post_param = open(f'{os.path.abspath(out)}/param/Postprocessing.txt', 'w')

    for step in dict_param :
        if step == "Postprocessing" :
            for var in dict_param[step] :
                O_post_param.write(var + "=" + dict_param[step][var] + "\n")

    
    if os.path.isdir(out + "/02_VariantCalling/VariantCalling/FINAL") :
        if dict_param["VariantCalling"]["VCF_prefix"] == "" :
            sys.stderr.write("Fill the VCF_prefix name in parameter file")
            sys.stderr.flush()
            sys.exit()
        else :
            for file_ in os.listdir(out + "/02_VariantCalling/VariantCalling/FINAL") :
                O_post_param.write("<" + dict_param["VariantCalling"]["VCF_prefix"] + ">\n")
                O_post_param.write(out + "/02_VariantCalling/VariantCalling/FINAL/" + file_ + "\n")


    O_post_param.close()
    return O_post_param

def Population(out, dict_param) :
    Population_input = tree()
    bindir = os.path.abspath(os.path.dirname(__file__))
    now = datetime.now()
    pop_outdir = out+"/04_Population/"+now.strftime("%d-%m-%Y_%H:%M:%S")
    param_outdir = out+"/param/"+now.strftime("%d-%m-%Y_%H:%M:%S")
    sub.call(f'mkdir -p {pop_outdir}', shell=True)
    sub.call(f'mkdir -p {param_outdir}', shell=True)
    Population_input["outdir"] =os.path.abspath(pop_outdir)

    O_pca_param = open(f'{os.path.abspath(param_outdir)}/PCA.txt' ,'w')

    O_pca_param.write("visPCA=")
    O_pca_param.write(bindir + "/script/visPCA.R\n")
    for step in dict_param :
        if step == "PCA" :
            for var in dict_param[step] :
                O_pca_param.write(var + "=" + dict_param[step][var] + "\n")

    O_pca_param.write("PLINK=")
    if os.path.isdir(out + "/03_Postprocessing/plink") :
        for file_ in os.listdir(out + "/03_Postprocessing/plink") :
            if "bed" in file_ :
                prefix = (os.path.basename(file_)).replace('.bed','')
                O_pca_param.write(out + "/03_Postprocessing/plink/" + prefix + "\n")

    O_pca_param.close()
    Population_input["PCA"] = O_pca_param.name

    O_snphylo_param = open(f'{os.path.abspath(param_outdir)}/PhylogeneticTree.txt', 'w')

    O_snphylo_param.write("dendogram=")
    O_snphylo_param.write(bindir + "/script/visTREE.R\n")
    for step in dict_param :
        if step == "Phylogenetic Tree" :
            for var in dict_param[step] :
                O_snphylo_param.write(var + "=" + dict_param[step][var] + "\n")

    if os.path.isdir(out + "/03_Postprocessing/Hapmap") :
        for file_ in os.listdir(out + "/03_Postprocessing/Hapmap") :
            if file_.endswith("hapmap") :
                O_snphylo_param.write("hapmap=")
                O_snphylo_param.write(out + "/03_Postprocessing/Hapmap/" + file_ + "\n")

    O_snphylo_param.close()
    Population_input["PhylogeneticTree"] = O_snphylo_param.name
    
    O_structure_param = open(f'{os.path.abspath(param_outdir)}/Structure.txt', 'w') 
    for step in dict_param :
        if step == "Population Structure" :
            for var in dict_param[step] :
                O_structure_param.write(var + "=" + dict_param[step][var] + "\n")

    O_structure_param.write("bed=")
    if os.path.isdir(out + "/03_Postprocessing/plink") :
        for file_ in os.listdir(out + "/03_Postprocessing/plink") :
            if "bed" in file_ :
                O_structure_param.write(out + "/03_Postprocessing/plink/" + file_ + "\n")

    O_structure_param.close()
    Population_input["Structure"] = O_structure_param.name

    O_fst_param = open(f'{os.path.abspath(param_outdir)}/Fst.txt', 'w')

    O_fst_param.write("qqmanS=")
    O_fst_param.write(bindir + "/script/visMP.R\n")
    for step in dict_param :
        if step == "Fst" :
            for var in dict_param[step] :
                O_fst_param.write(var + "=" + dict_param[step][var] + "\n")


    if os.path.isdir(out + "/03_Postprocessing/VCF_filt") :
        for file_ in os.listdir(out + "/03_Postprocessing/VCF_filt") :
            if not ".tbi" in file_ :
                O_fst_param.write("vcf = ") 
                O_fst_param.write(out + "/03_Postprocessing/VCF_filt/" + file_ + "\n")
    else :
        if os.path.isdir(out + "/02_VariantCalling/VariantCalling/FINAL") :
            for file_ in os.listdir(out + "/02_VariantCalling/VariantCalling/FINAL") :
                O_fst_param.write("vcf = ")
                O_fst_param.write(out + "/02_VariantCalling/VariantCalling/FINAL/" + file_ + "\n")


    O_fst_param.close()
    Population_input["Fst"] = O_fst_param.name

    O_effectivesize_param = open(f'{os.path.abspath(param_outdir)}/EffectiveSize.txt', 'w')
    for step in dict_param :
        if step == "Effective Size" :
            for var in dict_param[step] :
                O_effectivesize_param.write(var + "=" + dict_param[step][var] + "\n")

    if os.path.isdir(out + "/01_ReadMapping/04.ReadRegrouping") :
        for bam in os.listdir(out + "/01_ReadMapping/04.ReadRegrouping") :
            if not ("bam" in bam):
                continue
            if ("bam.bai" in bam):
                continue
            name = os.path.basename(bam).replace(".bam", "")
            name = os.path.basename(name).replace(".addRG.marked.sort", "")
            O_effectivesize_param.write("BAM_" + name + "=" + out + "/01_ReadMapping/04.ReadRegrouping/" + bam + "\n")


    O_effectivesize_param.close()
    Population_input["EffectiveSize"] = O_effectivesize_param.name

    O_admixtools_param = open(f'{os.path.abspath(param_outdir)}/AdmixtureProportion.txt', 'w')
    for step in dict_param :
        if step == "Admixture Proportion" :
            for var in dict_param[step] :
                O_admixtools_param.write(var + "=" + dict_param[step][var] + "\n")

    O_admixtools_param.write("PLINK=")
    if os.path.isdir(out + "/03_Postprocessing/plink") :
        for file_ in os.listdir(out + "/03_Postprocessing/plink") :
            if "bed" in file_ :
                prefix = (os.path.basename(file_)).replace('.bed', '')
                O_admixtools_param.write(out + "/03_Postprocessing/plink/" + prefix + "\n")

    O_admixtools_param.close()
    Population_input["AdmixtureProportion"] = O_admixtools_param.name

    O_LD_param = open(f'{os.path.abspath(param_outdir)}/LdDecay.txt', 'w')
    for step in dict_param :
        if step == "Ld Decay" :
            for var in dict_param[step] :
                O_LD_param.write(var + "=" + dict_param[step][var] + "\n")

    if os.path.isdir(out + "/02_VariantCalling/VariantCalling/FINAL") :
        for file_ in os.listdir(out + "/02_VariantCalling/VariantCalling/FINAL") :
            O_LD_param.write("VCF=")
            O_LD_param.write(out + "/02_VariantCalling/VariantCalling/FINAL/" + file_ + "\n")

    O_LD_param.close()
    Population_input['LdDecay'] = O_LD_param.name

#-------
    O_MSMC_param = open(f'{os.path.abspath(param_outdir)}/MSMC.txt', 'w')
    for step in dict_param :
        if step == "MSMC" :
            for var in dict_param[step] :
                O_MSMC_param.write(var + "=" + dict_param[step][var] + "\n")

    Population_input['MSMC'] = O_MSMC_param.name
    if os.path.isdir(out + "/01_ReadMapping/04.ReadRegrouping") :
        for bam in os.listdir(out + "/01_ReadMapping/04.ReadRegrouping") :
            if not ("bam" in bam):
                continue
            if ("bam.bai" in bam):
                continue
            name = os.path.basename(bam).replace(".bam", "")
            name = os.path.basename(name).replace(".addRG.marked.sort", "")
            O_MSMC_param.write("BAM_" + name + "=" + out + "/01_ReadMapping/04.ReadRegrouping/" + bam + "\n")
    O_MSMC_param.close()





    O_SF2_param = open(f'{os.path.abspath(param_outdir)}/SweepFinder2.txt', 'w')
    for step in dict_param :
        if step == "SweepFinder2" :
            for var in dict_param[step] :
                O_SF2_param.write(var + "=" + dict_param[step][var] + "\n")

    if os.path.isdir(out + "/02_VariantCalling/VariantCalling/FINAL") :
        for file_ in os.listdir(out + "/02_VariantCalling/VariantCalling/FINAL") :
            O_SF2_param.write("vcf=")
            O_SF2_param.write(out + "/02_VariantCalling/VariantCalling/FINAL/" + file_ + "\n")

    O_SF2_param.write("plink=")
    if os.path.isdir(out + "/03_Postprocessing/plink") :
        for file_ in os.listdir(out + "/03_Postprocessing/plink") :
            if "bed" in file_ :
                prefix = (os.path.basename(file_)).replace('.bed', '')
                O_SF2_param.write(out + "/03_Postprocessing/plink/" + prefix + "\n")


    O_SF2_param.close()
    Population_input['SweepFinder2'] = O_SF2_param.name

    O_Plink2_param = open(f'{os.path.abspath(param_outdir)}/Plink2.txt', 'w')
    for step in dict_param :
        if step == "Plink2" :
            for var in dict_param[step] :
                O_Plink2_param.write(var + "=" + dict_param[step][var] + "\n")
    if os.path.isdir(out + "/02_VariantCalling/VariantCalling/FINAL") :
        for file_ in os.listdir(out + "/02_VariantCalling/VariantCalling/FINAL") :
            O_Plink2_param.write("vcfInput=")
            O_Plink2_param.write(out + "/02_VariantCalling/VariantCalling/FINAL/" + file_ + "\n")
            O_Plink2_param.write("outdir=")
            O_Plink2_param.write(os.path.abspath(pop_outdir) + "/Plink2/\n")

    O_Plink2_param.close()
    Population_input['Plink2'] = O_Plink2_param.name

    O_Treemix_param = open(f'{os.path.abspath(param_outdir)}/Treemix.txt', 'w')
    for step in dict_param :
        if step == "Treemix" :
            for var in dict_param[step] :
                O_Treemix_param.write(var + "=" + dict_param[step][var] + "\n")
    if os.path.isdir(out + "/02_VariantCalling/VariantCalling/FINAL") :
        for file_ in os.listdir(out + "/02_VariantCalling/VariantCalling/FINAL") :
            O_Treemix_param.write("vcf=")
            O_Treemix_param.write(out + "/02_VariantCalling/VariantCalling/FINAL/" + file_ + "\n")

    O_Treemix_param.close()
    Population_input['Treemix'] = O_Treemix_param.name
    
    return Population_input
