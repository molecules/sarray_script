# sbatch_script

## Description

SLURM helper utility for creating sbatch scripts from the command line.  

## Synopsis

    sbatch_script --cpu=4 --mem=10G job_name 'ls > ls.txt'

    # Gzip all files in the directory using a SLURM Array
    sbatch_script --sarray-file-pattern='fastq$' gzip_files 'gzip $FILE'

    # Get sequence headers from each FASTQ file
    sbatch_script --sarray-file-pattern='.fastq.gz$' get_headers 'zcat $FILE | awk "{if (FNR % 4 == 1) print}" > $FILE.headers'

## Details

    $FILE            (available if using --sarray-file-pattern)
    $PAIRED_FILE     (available if using --sarray-paired-file-pattern)
    $FILENAME_PREFIX (available if using --sarray-paired-file-pattern)

# Version

VERSION-PLACEHOLDER

# Dependencies:  

Linux operating system (tested on CentOS 7)  

For sbatch_script:    Rakudo Star 2017.10 or later (https://perl6.org/downloads/)  
For sbatch_script.py: Python 3.6 or later (https://www.python.org/)

slurm (https://slurm.schedmd.com/)  

# CHANGES

