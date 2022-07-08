# Temporal physicochemical and biological data on Okinawa coastal ecosystems

This repository includes all the codes and intermediate documents and figures generated from the code analysing the seasonal physical, chemical and biological (16s) observed in Okinawa nearshore seawater from September of 2020 to September 2021. Samples were collected each two weeks.

Below a detailed description for each of the analysis

## Nutrient data analysis

Here an overview of the exploratory analysis of the nutrient concentrations 
http://rpubs.com/angelaap/869151

## Biological data analysis

This is an example of our workflow. This image was taken from the [Gibbons lab github] (https://github.com/Gibbons-Lab/isb_course_2021). This repository includes great resources for learning about **Amplicon Sequence Analysis with Qiime2**

![our workflow](https://github.com/Gibbons-Lab/isb_course_2021/raw/main/docs/16S/assets/steps.png)

The amplicon sequence analysis will is performed with Qiime 2 tool. The first part of the analysis is carried out in Terminal, where the most of computational demaning jobs are carried out on **Deigo** (OIST main cluster) and the second part will be performed in our local computer with R. 

The sequences are received from the OIST sequencing center are already demultiplexed paired-end sequences. For this project there are a total of four sequencing runs.

### Qiime2 Setup

QIIME 2 (v2021.4) software is usually installed by following the [official installation instructions](https://docs.qiime2.org/2022.2/install/).

In terminal, once logged in in **Deigo** , copy the result files from the sequencing center into a safe place, this time is the bucket folder. Then on flash directory: 

```
mkir DNAmonitRS

cd DNAmonitRS

mkdir qiime
```
Before starting with the denoising step we need to set up Qiime2 environment with conda. 

```
conda activate qiime2-2021.4
```
Our input data must be stored in Qiime artifacts (i.e. qza files). We can import the data with the import action from the tools.
We create a new slurm file to import the data into qiime2. 

```
nano import.slurm
```
Below are the code files for only one sequencing run.

```
#!/bin/bash

#SBATCH --job-name=denoise
#SBATCH --partition=compute
#SBATCH --time=1:00:00
#SBATCH --mem-per-cpu=64G
#SBATCH --nodes=1
#SBATCH --ntasks=3
#SBATCH --mail-user=xx.xxxx@oist.jp
#SBATCH --mail-type=FAIL,END
#SBATCH --input=none
#SBATCH --output=rsemref_%j.out


qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path /bucket/MitaraiU/Users/Angela/data/redsoil/DNAmonit/bact/plate1_ayse/Fastq_clean \
  --input-format CasavaOneEightSingleLanePerSampleDirFmt \
  --output-path 16demuxp1-paired-end.qza
```
### DADA2

The next step is denoising amplicon sequence variants. For that we will run the DADA2 plugin which will do 4 things:

1. filter and trim the reads
2. find the most likely set of unique sequences in the sample (ASVs)
3. remove chimeras
4. count the abundances of each ASV

This process takes a while. In my case for 4 sequencing runs, 64 G of memory and 16 tasks takes more than 14 hours. So be ready for waiting! 

In the same qiime directory:

```
nano import.slurm
```

```
#!/bin/bash

#SBATCH --job-name=denoise
#SBATCH --partition=compute
#SBATCH --time=24:00:00
#SBATCH --mem-per-cpu=64G
#SBATCH --nodes=1
#SBATCH --mail-user=xx.xxx@oist.jp
#SBATCH --mail-type=FAIL,END
#SBATCH --input=none
#SBATCH --output=rsemref_%j.out


  qiime dada2 denoise-paired \
--i-demultiplexed-seqs 16demuxp1-paired-end.qza \
--output-dir ./16dada2_p1 \
--o-representative-sequences 16rep1-seqs \
--p-trim-left-f 15 \
--p-trim-left-r 15 \
--p-trunc-len-f 295 \
--p-trunc-len-r 280 \
--p-n-threads 16  
```

I have got 4 directories (16dada2_p1, 16dada2_p2, 16dada2_p3, 16dada2_p4) for each for each sequence run. 
In each directory there are two files (denoising_stats.qza and table.qza). Additionally, another file is generated (16rep1-seqs.qza, 16rep2-seqs.qza, 16rep3-seqs.qza, 16rep4-seqs.qza) in the previous directory. Next step is to join merge all the generated feature tables and representative sequences from the different runs into one with the merge function

```
#Feature-Table
qiime feature-table merge --i-tables /flash/MitaraiU/Angela/DNAmonitRS/qiime2/16dada2_p1/table.qza --i-tables /flash/MitaraiU/Angela/DNAmonitRS/qiime2/16dada2_p2/table.qza --i-tables /flash/MitaraiU/Angela/DNAmonitRS/qiime2/16dada2_p3/table.qza --i-tables /flash/MitaraiU/Angela/DNAmonitRS/qiime2/16dada2_p4/table.qza --o-merged-table merged_table.qza

#Representative Sequences
qiime feature-table merge-seqs --i-data 16rep1-seqs.qza --i-data 16rep2-seqs.qza --i-data 16rep3-seqs.qza --i-data 16rep4-seqs.qza --o-merged-data merged_rep-seqs.qza
```
### Taxonomy

For the taxonomy I already had downloaded a pre-trained classifier. Choose your reference database or pre-trained classifier from [here](https://docs.qiime2.org/2019.4/data-resources/)

**For SILVA (132) database**

I wrote the next chunk of code in a separate .slurm file

```
#Rep_set
SILVA97otus=/flash/MitaraiU/Angela/DNAmonitRS/qiime2/silva_132_97_16S.fna

#Taxonomy
Tax97=/flash/MitaraiU/Angela/DNAmonitRS/qiime2/taxonomy_all_levels.txt

#converting the sequences and taxonomy to qiime files

qiime tools import \
    --type 'FeatureData[Sequence]' \
    --input-path $SILVA97otus \
    --output-path 97_otus16.qza


qiime tools import \
    --type 'FeatureData[Taxonomy]' \
    --input-format HeaderlessTSVTaxonomyFormat \
    --input-path $Tax97 \
    --output-path 97ref-taxonomy16.qza

#train the classifier

qiime feature-classifier fit-classifier-naive-bayes \
    --i-reference-reads 97_otus16.qza\
    --i-reference-taxonomy 97ref-taxonomy16.qza\
    --o-classifier 97classifier16.qza
    
#assign the taxonomy to our ASVs

qiime feature-classifier classify-sklearn \
    --i-classifier 97classifier16.qza \
    --i-reads merged_rep-seqs.qza \
    --o-classification 16taxonomy.qza
```

We can take a look to the 16taxonomy.qza file by opening it in qiime2 by converting it in a qzv file:

```
   qiime metadata tabulate \
    --m-input-file 16taxonomy.qza \
    --o-visualization 16taxonomy.qzv
```

### Preparation of R for downstream analysis

The Rmarkdown file and generated plots carried out with R and related packages can be found in the directory **Amplicon Sequence Analysis**. But here are explained the main steps.

Next step is to open R and make sure we have install all the required packages. Specially important are **Phyloseq** and **Qiime2R**. Phyloseq it is a very complete package that helps out with all the amplicon sequence analysis and Qiime2R it is useful to import qiime2 artifacts for Phyloseq

These are the most important packages we will use:

```
library("phyloseq")
library("ggplot2")
library("tidyr")
library(qiime2R)
library(DESeq2)
library(vegan)
library("breakaway")
set.seed(1)
```


