import re
import os
import sys

from collections import defaultdict

def tree() :
    return defaultdict(tree)

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

    O_pca_param = open(f'{os.path.abspath(out)}/param/PCA.txt' ,'w')

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

    O_snphylo_param = open(f'{os.path.abspath(out)}/param/PhylogeneticTree.txt', 'w')

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
    
    O_structure_param = open(f'{os.path.abspath(out)}/param/Structure.txt', 'w') 
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

    O_fst_param = open(f'{os.path.abspath(out)}/param/Fst.txt', 'w')

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

    O_effectivesize_param = open(f'{os.path.abspath(out)}/param/EffectiveSize.txt', 'w')
    for step in dict_param :
        if step == "Effective Size" :
            for var in dict_param[step] :
                O_effectivesize_param.write(var + "=" + dict_param[step][var] + "\n")

    if os.path.isdir(out + "/01_ReadMapping/04.ReadRegrouping") :
        for bam in os.listdir(out + "/01_ReadMapping/04.ReadRegrouping") :
            name = os.path.basename(bam).replace(".bam", "")
            name = os.path.basename(name).replace(".addRG.marked.sort", "")
            O_effectivesize_param.write("BAM_" + name + "=" + out + "/01_ReadMapping/04.ReadRegrouping/" + bam + "\n")


    O_effectivesize_param.close()
    Population_input["EffectiveSize"] = O_effectivesize_param.name

    O_admixtools_param = open(f'{os.path.abspath(out)}/param/AdmixtureProportion.txt', 'w')
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

    O_LD_param = open(f'{os.path.abspath(out)}/param/LdDecay.txt', 'w')
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
    
    return Population_input
