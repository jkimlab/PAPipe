
# Multiple runs of PAPipe for population genetic analyses 

- Using the same variant calling results, PAPipe can be run multiple times with different parameter values.
- This feature is supported only for population genetic analyses, not for the previous steps, such as read trimming, read mapping, genetic variant calling, and data filtering and format converting 

### Parameter setting 

After the first run of PAPipe, if you want to run PAPipe again for the same variant calling results, please follow the instruction below.

- In the "main_param.txt" parameter file, do not change anything above the following line.
```
#### PopulationAnalysis ####
```

- In the "main_param.txt" parameter file, you can find the parameter setting for various population genetic analyses.
- The following example shows the setting for the principal component analysis by GCTA.

```
#### PCA ####
# Principal component analysis by GCTA #
ON/OFF = OFF
### Program path ###
GCTA = gcta64
Rlib_path = /opt/conda/lib/R/library/
### GRM parameter ###
autosome-num = 1
maxPC = 5
PCA = 20
Variance = 80
PCA_title = PCA analysis
```
- You can turn on the analysis by setting:
```
ON/OFF = ON
```
- You can turn off the analysis by setting:
```
ON/OFF = OFF
```
- You can change various parameter values appearing after the ON/OFF setting:
```
### GRM parameter ###
autosome-num = 1
maxPC = 5
PCA = 20
Variance = 80
PCA_title = PCA analysis
```
- You can find the description of the various parameters in the parameter file generator of PAPipe [here](http://bioinfo.konkuk.ac.kr/PAPipe/parameter_builder/).

### Rerun PAPipe

After finishing the setting of parameter values, you can rerun PAPipe using the same command as shown below.


