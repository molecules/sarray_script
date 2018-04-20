# NAME

sbatch_script

## DESCRIPTION

SLURM helper utility for creating sbatch scripts from the command line.

# VERSION

VERSION-PLACEHOLDER

# SYNOPSIS

    # Simple quick script generation
    sbatch_script --cpu=4 --mem=10G --job=job_name --command='ls > ls.txt'

    # Simple quick script generation with immediate submission (using the --run flag)
    sbatch_script --run --cpu=4 --mem=10G --job=job_name --command='ls > ls.txt'

    # Compress all "fastq" files in the directory in parallel using a SLURM Array
    sbatch_script --cpu=32 --file-pattern='*.fastq' --job=pigz_files --command='pigz --processes 32 $FILE'

    # Get sequence headers from each FASTQ file
    sbatch_script --file-pattern='*.fastq.gz' --job=get_headers --command='zcat $FILE | awk "{if (FNR % 4 == 1) print}" > $FILE.headers'

## Processing multiple files in parallel

WARNING:  
There are quite a few assumptions when using the features described below.
Please read the following and be sure you understand it.  

Do you have multiple files which you want to process in the same way?  

If you give `sbatch_script` a file pattern using the `--file_pattern` flag,
then, it will create a script that will run a slurm array with as many tasks
as there are matching files in the directory.  

PLEASE NOTE that the generated script will only work for the files present in
the directory at the time it was created.
This is because it embeds the filenames directly into the script.
Inside the BASH script so generated, is available the variable $FILE, which
represents the file processed by a single Slrum array task.  

The following BASH environment variables are created and available inside the
sbatch script created by `sbatch_script` if the given parameters are used:  

Available with --file-pattern flag:  
`$FILE` File processed by a single Slurm array task .  

Available with --paired-file-pattern flag:  
`$PAIRED_FILE` "Paired" file processed by the same Slurm array task as the file represented by "$FILE".  
`$FILE_PREFIX` It is assumed that $FILE and $PAIRED_FILE have a common prefix that will be unique in the directory. That prefix is computed and provided as `$FILE_PREFIX`. Enforcing uniqueness of this "common prefix" has not been done. The following situation would work:  

## (Simple example, one file at a time)
Given these files:

    foo.txt
    bar.txt

The following script would calculate the md5sum of each one:

    sbatch_script --run --file-pattern='*.txt' --job=calc_md5sum --command='md5sum $FILE > $FILE.md5sum'

## Processing multiple paired files simple example  
Given these files:  

    fooA.txt
    fooB.txt
    barA.txt
    barB.txt

The following script would combine them:  

    sbatch_script --run --file-pattern='*_A.txt' --paired-file-pattern='*_B.txt' --job=combine_files --command='cat $FILE $PAIRED_FILE > $FILE_PREFIX.combined.txt'

When all of the jobs finished running, the following would be the resulting files:  
    foo.combined.txt
    bar.combined.txt

## "cutadapt" example using paired files

(Adapted from http://cutadapt.readthedocs.io/en/stable/guide.html#illumina-truseq.)

Given these files:

    sampA_for.fastq.gz
    sampA_rev.fastq.gz
    sampB_for.fastq.gz
    sampB_rev.fastq.gz

This command line will "trim" these FASTQ files (Your adapters may be
different. Please verify instead of blindly copying and pasting this
code):

    sbatch_script --file-pattern='*R1*' --paired-file-pattern='*R2*' --job=trim_files --command='cutadapt -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC -A AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGTA --output=${FILE_PREFIX}_for.fastq.gz --paired-output=${FILE_PREFIX}_rev.fastq.gz'

Or using backslashed newlines to make the command line seem more sane:

    sbatch_script \
        --file-pattern='*R1*' \
        --paired-file-pattern='*R2*' \
        --job=trim_files \
        --command='cutadapt \
                    -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC \
                    -A AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGTA \
                    --output=${FILE_PREFIX}_for.fastq.gz  \
                    --paired-output=${FILE_PREFIX}_rev.fastq.gz'

# TRICKS

Take advantage of SLURM environment variables

    # Instead of
    sbatch_script --cpu=32 --file-pattern='*.fastq' --job=pigz_files --command='pigz --processes 32 $FILE'

    # Use $SLURM_CPUS_PER_TASK. Then if you change the --cpu parameter, you don't have to change it in two places
    sbatch_script --cpu=16 --file-pattern='*.fastq' --job=pigz_files --command='pigz --processes $SLURM_CPUS_PER_TASK $FILE'


Create a dummy script with a simple command (e.g. 'ls') and then modify the
script `trim_files.sbatch` later to enter the actual commands:

    sbatch_script --file-pattern='*R1*' --paired-file-pattern='*R2*' --job=trim_files --command='ls'

Even if you don't mention `$FILE` on the command line, it will still be
available inside your script if you used the `--file-pattern` option.

Even if you don't mentioned `$PAIRED_FILE` or `$FILE_PREFIX` on the command
line, they will still be available inside your script if you used the
`--paired-file-pattern` option.

# DEPENDENCIES

Linux operating system (tested on CentOS 7)

Python 3.6 or later (https://www.python.org/)

slurm (https://slurm.schedmd.com/)

# DIAGNOSTICS

If `--file-pattern` and `--paired-file-pattern` are both used but
they generate different numbers of files, then the following error will be
seen:

    ERROR: --file-pattern and --paired-file-pattern produce
           different numbers of files. List of 'File name (paired file name)':

Followed by a list of the files that were assumed to be the pairs and which
seem to be missing.

For example, given these files:

    file_1.A.txt
    file_1.B.txt
    file_2.A.txt
    file_2.B.txt
    file_3.B.txt

With this command line:

    sbatch_script --file-pattern='*.A.txt' --paired-file-pattern='*.B.txt' --command='ls' --job='test'

Gives the following error:

    ERROR:
    --file_pattern='*.A.txt' and --paired_file_pattern='*.B.txt'
    produce  different numbers of files:'

            file_1.A.txt (file_1.B.txt)
            file_2.A.txt (file_2.B.txt)
            --not found-- (file_3.B.txt)

    Exiting ...

# AUTHOR

Christopher Bottoms

# LICENSE

`sbatch_script` by the author is licensed under the Artistic License 2.0. See
a copy of this license at http://www.perlfoundation.org/artistic_license_2_0.

# CHANGES

