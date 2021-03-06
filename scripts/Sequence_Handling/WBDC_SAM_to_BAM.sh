#!/bin/bash

#PBS -l mem=8gb,nodes=1:ppn=8,walltime=8:00:00
#PBS -m abe
#PBS -M liux1299@umn.edu
#PBS -q lab

set -e
set -u
set -o pipefail

module load parallel

#   This script is a QSub submission script for converting a batch of SAM files to BAM files
#   To use, on line 5, change the 'user@example.com' to your own email address
#       to get notificaitons on start and completion of this script
#   Define a path to the bedtools in the 'SAMTOOLS' field on line 38
#       If using MSI, leave the definition as is to use their installation of bedtools
#       Otherwise, it should look like this:
#           SAMTOOLS=${HOME}/software/samtools
#       Please be sure to comment out (put a '#' symbol in front of) the 'module load samtools' on line 37
#       And to uncomment (remove the '#' symbol) from the 'SAMTOOLS=' line 38
#   Add the full file path to list of samples on the 'SAMPLE_INFO' field on line 41
#       This should look like:
#           SAMPLE_INFO=${HOME}/Directory/list.txt
#       Use ${HOME}, as it is a link that the shell understands as your home directory
#           and the rest is the full path to the actual list of samples
#   Put the full directory path for the output in the 'SCRATCH' field on line 44
#       This should look like:
#           SCRATCH="${HOME}/Out_Directory"
#       Adjust for your own out directory.
#   Name the project in the 'PROJECT' field on line 47
#       This should look lke:
#           PROJECT=Genetics

#   Load the SAMTools module
module load samtools
#SAMTOOLS=

#   List of SAM files for conversion
SAMPLE_INFO=${HOME}/Projects/Inversion_loci/Liana_Samples/Liana_Samples/Liana_samples_trimmed_list_sam_1-5.txt

#   Scratch directory, for output
SCRATCH=${HOME}/Projects/Inversion_loci/Liana_Samples/Liana_Samples

#   Name of project
PROJECT=Liana_Samples_read_mapping

#   Make the outdirectory
mkdir -p ${SCRATCH}/${PROJECT}

#   Generate a list of sample names
for i in `seq $(wc -l < "${SAMPLE_INFO}")`
do
    s=`head -"$i" "${SAMPLE_INFO}" | tail -1`
    basename "$s" .sam >> "${SCRATCH}"/"${PROJECT}"/sample_names.txt
done

SAMPLE_NAMES="${SCRATCH}"/"${PROJECT}"/sample_names.txt

DATE=`date +%Y-%m-%d`

#   Create a sorted BAM file for each input SAM file in parallel
parallel --xapply "samtools view -bS {1} | samtools sort - ${SCRATCH}/${PROJECT}/{2}_${DATE}.bam" :::: ${SAMPLE_INFO} :::: ${SAMPLE_NAMES}

#   Make a list of BAM files
find ${SCRATCH}/${PROJECT} -name "*.bam" | sort > ${SCRATCH}/${PROJECT}/${PROJECT}_bam_files.txt
echo "List of BAM files can be found at"
echo "${SCRATCH}/${PROJECT}/${PROJECT}_bam_files.txt"
