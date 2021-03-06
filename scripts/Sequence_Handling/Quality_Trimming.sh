#!/bin/env bash

#PBS -l mem=1gb,nodes=1:ppn=8,walltime=20:00:00
#PBS -m abe 
#PBS -M liux1299@umn.edu
#PBS -q lab

set -e
set -u
set -o pipefail

module load parallel

#   This script is a qsub submission for quality trimming a batch of files.
#   To use, on line 5, change the 'user@example.com' to your own email address
#       to get notifications on start and completion for this script
#   Place the full directory path to your Seqqs installation on line 54
#       This should look like:
#           SEQQS_DIR=${HOME}/software/seqqs
#       Use ${HOME}, as it is a link that the shell understands as your home directory
#   Add the full file path to list of samples on the 'SAMPLE_INFO' field on line 59
#       This should look like:
#           SAMPLE_INFO=${HOME}/Directory/list.txt
#   Specify the forward and reverse file extensions in the 'FORWARD_NAMING' 
#       and 'REVERSE_NAMING' fields on lines 65 and 66
#       This should look like:
#           FORWARD_NAMING=_1_sequence.txt.gz
#           REVERSE_NAMING=_2_sequence.txt.gz
#   Name the project in the 'PROJECT' field on line 69
#       This should look lke:
#           PROJECT=Genetics
#   Put the full directory path for the output in the 'OUTDIR' field on line 72
#       This should look like:
#           OUTDIR="${HOME}/Out_Directory"
#       Adjust for your own out directory.
#   Specify the directory where samples are stored in the 'WORKING' field on line 75
#       This should look like:
#           WORKING=${HOME}/Working_Directory
#   Run this script using the qsub command
#       qsub Quality_Trimming.sh
#   This script outputs gzipped FastQ files with the extension fq.qz
#   In the stats directory, there are text files with more details about the trim
#       as well as a plots directory
#   In the plots directory, there are PDFs showing graphs of the quality before and after the trim
#   Finally, this script outputs a list of all trimmed FastQ files for use in the Read_Mapping.sh script
#       This is stored in ${OUTDIR}/${PROJECT}, whatever you happen to name these fields. 


#   The trimming script runs seqqs, scythe, and sickle
#   The script is heavily modified from a Vince Buffalo original
#   Most important modification is the addition of plotting of read data before &
#   after. Leave the value for TRIM_SCRIPT as is unless you are not using seqqs,
#   sickle, and scythe for quality trimming
SEQQS_DIR=${HOME}/software/seqqs
TRIM_SCRIPT=${SEQQS_DIR}/wrappers/trim_autoplot.sh

#   List of samples to be processed
#   Need to hard code the file path for qsub jobs
SAMPLE_INFO=${HOME}/Projects/Inversion_loci/Liana_Samples/Sample_List_Liana_06-09-2015.txt

#   Extension on forward and reverse read names to be trimmed by basename
#       Example:
#           _1_sequence.txt.gz  for forward
#           _2_sequence.txt.gz  for reverse
FORWARD_NAMING=_R1.fastq.gz
REVERSE_NAMING=_R2.fastq.gz

#   Project name
PROJECT=Liana_Samples

#   Output directory
OUTDIR=${HOME}/Projects/Inversion_loci/Liana_Samples

#   Directory where samples are stored
WORKING=${HOME}/Shared/Datasets/NGS/Barley_Exome/Wild

#   Load the R Module
module load R

#   Test to see if there are equal numbers of forward and reverse reads
FORWARD_COUNT="`grep -cE "$FORWARD_NAMING" $SAMPLE_INFO`"
REVERSE_COUNT="`grep -cE "$REVERSE_NAMING" $SAMPLE_INFO`"

if [ "$FORWARD_COUNT" = "$REVERSE_COUNT" ]; then
    echo Equal numbers of forward and reverse samples
else
    exit 1
fi

#   Create lists of forward and reverse samples
grep -E "$FORWARD_NAMING" $SAMPLE_INFO > ${OUTDIR}/forward.txt
FORWARD_SAMPLES=${OUTDIR}/forward.txt
grep -E "$REVERSE_NAMING" $SAMPLE_INFO > ${OUTDIR}/reverse.txt
REVERSE_SAMPLES=${OUTDIR}/reverse.txt

#   Create a list of sample names
for i in `seq $(wc -l < $FORWARD_SAMPLES)`
do
    s=`head -"$i" "$FORWARD_SAMPLES" | tail -1`
    basename $s $FORWARD_NAMING >> ${OUTDIR}/samples.txt
done

SAMPLE_NAMES=${OUTDIR}/samples.txt


#   Change to program directory
#   This is necessary to call the R script (used for plotting) from the trim_autoplot.sh script
cd ${SEQQS_DIR}/wrappers/


#   Run the job in parallel
parallel --xapply ${TRIM_SCRIPT} {1} {2} {3} ${OUTDIR}/${PROJECT}/{4} :::: $SAMPLE_NAMES :::: $FORWARD_SAMPLES :::: $REVERSE_SAMPLES :::: $SAMPLE_NAMES

#   Create a list of outfiles to be used by Read_Mapping.sh
cd ${OUTDIR}/${PROJECT}

find . -name "*.fq.gz" > "${PROJECT}"_samples_trimmed.txt
echo List for Read_Mapping.sh can be found at
echo "${OUTDIR}"/"${PROJECT}"/"${PROJECT}"_samples_trimmed.txt
