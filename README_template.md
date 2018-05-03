# NAME

sarray_script

## DESCRIPTION

Create shell scripts that process whole directories of files using SLURM
arrays. Also works for paired files (like paired-end FASTQ files). 

# VERSION

VERSION-PLACEHOLDER

# SYNOPSIS

    # Compress all ".txt" files in the directory using a SLURM Array
    sarray_script --cpu=32 --file-pattern='*.txt' --job=pigz_files --command='pigz --processes 32 $FILE'

    # Given A_header.txt, A_body.txt, B_header.txt, and B_body.text, you could do the following  
    sarray_script --run --file-pattern='*_header.txt' --paired-pattern='*_body.txt' --job=combine_files --command='cat $FILE $PAIRED_FILE > $FILE_PREFIX.doc.txt'

    # Then for the bioinformaticians out there, work on those paired-end sequences:
    sarray_script --file-pattern='*R1*' --paired-pattern='*R2*' --job=trim_files --command='cutadapt -a AGAT... -A AGAT... --output=${FILE_PREFIX}_for.fastq.gz --paired-output=${FILE_PREFIX}_rev.fastq.gz'

    # Or, if you needed to do a little fancy coding as well (e.g. print "Hello world" before running cutadapt):
    sarray_script --exe=perl --file-pattern='*R1*' --paired-pattern='*R2*' --job=trim_files --command='print "Hello World\n"; system("cutadapt -a AGAT... -A AGAT... --output=${FILE_PREFIX}_for.fastq.gz --paired-output=${FILE_PREFIX}_rev.fastq.gz");'


## Processing multiple files in parallel

WARNING:  
There are quite a few assumptions when using the features described below.
Please read the following and be sure you understand it.  

Do you have multiple files which you want to process in the same way?  

If you give `sarray_script` a file pattern using the `--file_pattern` flag,
then, it will create a script that will run a slurm array with as many tasks
as there are matching files in the directory.  

PLEASE NOTE that the generated script will only work for the files present in
the directory at the time it was created.
This is because it embeds the filenames directly into the script.
Inside the BASH script so generated, is available the variable $FILE, which
represents the file processed by a single Slrum array task.  

The following BASH environment variables are created and available inside the
sbatch script created by `sarray_script` if the given parameters are used:  

Available with --file-pattern flag:  
`$FILE` File processed by a single Slurm array task .  

Available with --paired-pattern flag:  
`$PAIRED_FILE` "Paired" file processed by the same Slurm array task as the file represented by "$FILE".  
`$FILE_PREFIX` It is assumed that $FILE and $PAIRED_FILE have a common prefix that will be unique in the directory. That prefix is computed and provided as `$FILE_PREFIX`. Enforcing uniqueness of this "common prefix" has not been done. The following situation would work:  

## (Simple example, one file at a time)
Given these files:

    foo.txt
    bar.txt

The following script would calculate the md5sum of each one:

    sarray_script --run --file-pattern='*.txt' --job=calc_md5sum --command='md5sum $FILE > $FILE.md5sum'

## Processing multiple paired files simple example  
Given these files:  

    fooA.txt
    fooB.txt
    barA.txt
    barB.txt

The following script would combine them:  

    sarray_script --run --file-pattern='*_A.txt' --paired-pattern='*_B.txt' --job=combine_files --command='cat $FILE $PAIRED_FILE > $FILE_PREFIX.combined.txt'

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

    sarray_script --file-pattern='*R1*' --paired-pattern='*R2*' --job=trim_files --command='cutadapt -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC -A AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGTA --output=${FILE_PREFIX}_for.fastq.gz --paired-output=${FILE_PREFIX}_rev.fastq.gz'

Or using backslashed newlines to make the command line seem more sane:

    sarray_script \
        --file-pattern='*R1*' \
        --paired-pattern='*R2*' \
        --job=trim_files \
        --command='cutadapt \
                    -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC \
                    -A AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGTA \
                    --output=${FILE_PREFIX}_for.fastq.gz  \
                    --paired-output=${FILE_PREFIX}_rev.fastq.gz'

# TRICKS

Take advantage of SLURM environment variables

    # Instead of
    sarray_script --cpu=32 --file-pattern='*.fastq' --job=pigz_files --command='pigz --processes 32 $FILE'

    # Use $SLURM_CPUS_PER_TASK. Then if you change the --cpu parameter, you don't have to change it in two places
    sarray_script --cpu=16 --file-pattern='*.fastq' --job=pigz_files --command='pigz --processes $SLURM_CPUS_PER_TASK $FILE'


Create a dummy script with a simple command (e.g. 'ls') and then modify the
script `trim_files.sbatch` later to enter the actual commands:

    sarray_script --file-pattern='*R1*' --paired-pattern='*R2*' --job=trim_files --command='ls'

Even if you have not mentioned `$FILE` on the command line, it will still be
available inside your script if you used the `--file-pattern` option.

Even if you have not mentioned `$PAIRED_FILE` or `$FILE_PREFIX` on the command
line, they will still be available inside your script if you used the
`--paired-pattern` option.

# DEPENDENCIES

Linux operating system (tested on CentOS 7)

Python 3.6 or later (https://www.python.org/)

slurm (https://slurm.schedmd.com/)

# DIAGNOSTICS

If `--file-pattern` and `--paired-pattern` are both used but
they generate different numbers of files, then the following error will be
seen:

    ERROR: --file-pattern and --paired-pattern produce
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

    sarray_script --file-pattern='*.A.txt' --paired-pattern='*.B.txt' --command='ls' --job='test'

Gives the following error:

    ERROR:
    --file-pattern='*.A.txt' and --paired-pattern='*.B.txt'
    produce  different numbers of files:'

            file_1.A.txt (file_1.B.txt)
            file_2.A.txt (file_2.B.txt)
            --not found-- (file_3.B.txt)

    Exiting ...

# AUTHOR

Christopher Bottoms

# LICENSE

`sarray_script` by the author is licensed under the Artistic License 2.0. See
a copy of this license at http://www.perlfoundation.org/artistic_license_2_0.

# CHANGES

