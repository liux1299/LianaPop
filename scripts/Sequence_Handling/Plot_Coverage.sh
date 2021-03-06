#!/bin/bash

#PBS -l mem=8gb,nodes=1:ppn=8,walltime=8:00:00
#PBS -m abe
#PBS -M liux1299@umn.edu
#PBS -q small

set -e
set -u
set -o pipefail

module load parallel
module load R

#   This script is a QSub submission script for generating plots based off coverage maps
#   To use, on line 5, change the 'user@example.com' to your own email address
#       to get notifications on start and completion for this script
#   Add the full file path to list of samples on the 'SAMPLE_INFO' field on line 36
#       This should look like:
#           SAMPLE_INFO=${HOME}/Directory/list.txt
#   Name the project in the 'PROJECT' field on line 39
#       This should look lke:
#           PROJECT=Genetics
#   Put the full directory path for the output in the 'SCRATCH' field on line 42
#       This should look like:
#           SCRATCH="${HOME}/Out_Directory"
#       Adjust for your own out directory.
#   Define the directory where the sequence_handling scripts were downloaded on line 45
#       This is to find the 'plot_cov.R' script for making the plots
#       This should look like:
#           SEQ_HANDLING_DIR=
#   Run this script using the qsub command
#       qsub Plot_Coverage.sh
#   This script outputs three plots in PDF format for each sample

#   List of text files for plotting
SAMPLE_INFO=${HOME}/Projects/Inversion_loci/Liana_Samples/Liana_Samples/Liana_Samples_read_mapping/Liana_samples_BAM/finished//Liana_samples_finishedBAM_coverage_map/Coverage_Map/Liana_samples_finishedBAM_coverage_map_samples_coverage.txt

#   Name of Project
PROJECT=Liana_samples_BAM_coverage_map_plots

#   Scratch directory for output, 'scratch' is a symlink to individual user scratch at /scratch*
SCRATCH=${HOME}/Projects/Inversion_loci/Liana_Samples/Liana_Samples/Liana_Samples_read_mapping/Liana_samples_BAM/finished

#   Directory for sequence handling, needed to call the R script
SEQ_HANDLING_DIR=${HOME}/sequence_handling
PLOT_COV=${SEQ_HANDLING_DIR}/plot_cov.R

#   Other variables, don't need to be user-specified
DATE=`date +%Y-%m-%d`
OUT=${SCRATCH}/${PROJECT}/Plot_Coverage
mkdir -p ${OUT}

#   Check if R is installed and in the path
if `command -v Rscript > /dev/null 2> /dev/null`
then
    echo "R is installed, OK"
else
    echo "You need R (Rscript) to be installed and in your \$PATH"
    exit 1
fi

#   Check to see if the path to the 'plot_cov.R' script is defined properly
if [[ -f "${PLOT_COV}" ]]
then
    echo "Found the 'plot_cov.R' script!"
else
    echo "Failed to find the 'plot_cov.R' script, please redefine"
    exit 1
fi

#   A function to split the coverage map into a map for:
#       the whole genome
#       exons
#       and genes
function splitMaps() {
    #   Figure out what this sample is
    sample="$1"
    out="$2"
    name="`basename $sample .coverage.hist.txt`"
    echo "${name}" >> "${out}"/sample_names.txt
    #   Make a map for the genome
    grep 'all' "$sample" > "${out}"/"${name}"_genome.txt
    #   Make a map for exons
    grep 'exon' "$sample" > "${out}"/"${name}"_exon.txt
    #   Make a map for genes
    grep 'gene' "$sample" > "${out}"/"${name}"_gene.txt
}

#   Export the function so parallel can see it
export -f splitMaps

#   Split the maps in parallel
cat ${SAMPLE_INFO} | parallel "splitMaps {} ${OUT}"

#   Create lists of all split maps
find "${OUT}" -name "*_genome.txt" | sort >> "${OUT}"/all_genomes.txt
ALL_GENOMES="${OUT}"/all_genomes.txt
find "${OUT}" -name "*_exon.txt" | sort >> "${OUT}"/all_exons.txt
ALL_EXONS="${OUT}"/all_exons.txt
find "${OUT}" -name "*_gene.txt" | sort >> "${OUT}"/all_genes.txt
ALL_GENES="${OUT}"/all_genes.txt

#   Final variable definitions
SAMPLE_NAMES="${OUT}"/sample_names.txt

#   Create the coverage plots in parallel
parallel --xapply "Rscript ${PLOT_COV} {1} {2} {3} {4} {5}" :::: ${ALL_GENOMES} :::: ${ALL_EXONS} :::: ${ALL_GENES} ::: ${OUT} :::: ${SAMPLE_NAMES}
