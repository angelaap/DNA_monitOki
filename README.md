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





