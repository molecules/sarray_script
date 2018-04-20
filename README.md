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

0.0.22

# Dependencies:  

Linux operating system (tested on CentOS 7)  

Python 3.6 or later (https://www.python.org/)

slurm (https://slurm.schedmd.com/)  

# DIAGNOSTICS

If --sarray-file-pattern and --sarray-paired-file-pattern are both used but
they generate different numbers of files, then the following error will be
seen:

    ERROR: --sarray-file-pattern and --sarray-paired-file-pattern produce 
           different numbers of files. List of 'File name (paired file name)':

Followed by a list of the files showing what it thinks the pairs are and which
seem to be missing.

# CHANGES

0.0.22: The executable in /bin is now just Python (for this branch)  
0.0.21: Updated to be almost the same  
0.0.20: Script no longer runs by default (use "--run" flag if desired). Also, improved parameter names. (Thanks for the feedback Nick, Tendai, and Jenny)  
0.0.19: Completed renaming. Also added default partition.  
0.0.18: Renaming Perl 6 script so that the Python version can take its name  
0.0.17: Documented diagnostic info expected in case paired files do not match up  
0.0.16: Fixed job test  
0.0.15: Almost working. Still need to improve output so it does not come out as bytestring  
0.0.14: Continuing to build up functionality in Python version sbatch_script.py  
0.0.13: Now extracting common prefixes of paired file names.  
0.0.12: updated tests to use new bin/ location for sbatch_script  
0.0.11: moved script to bin/ directory so that it will be installed properly  
0.0.10: added link to slurm in README  
0.0.9: no longer has hard coded default partition  
0.0.8: Now testing use of paired files  
0.0.7: file names are sorted before creating sbatch script  
0.0.6: test tweaks  
0.0.5: removed cruft  
0.0.4: Adding repository management tools .add and .commit (optional)  
0.0.3: Now creating README from template  
0.0.2: Parallel tests!  
