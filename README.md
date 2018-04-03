# sbatch_script

## Description

SLURM helper utility for creating sbatch scripts from the command line.

## Synopsis

    sbatch_script --cpu=4 --mem=10G job_name 'ls > ls.txt'

    # Gzip all files in the directory using a SLURM Array
    sbatch_script --sarray-file-pattern='fastq$' gzip_files 'gzip $FILE'

    # Get sequence headers from each FASTQ file
    sbatch_script --sarray-file-pattern='.fastq.gz$' get_headers 'zcat $FILE | awk "{if (FNR % 4 == 1) print}" > $FILE.headers'

# Version

0.0.5

# Dependencies:  

Linux operating system (tested on CentOS 7)  

Rakudo Star 2017.10 or later (https://perl6.org/downloads/)  

SLURM 

# CHANGES

0.0.5: removed cruft
0.0.4: Adding repository management tools .add and .commit (optional)
0.0.3: Now creating README from template
0.0.2: Parallel tests!
