# NAME

sarray_script

## DESCRIPTION

Create shell scripts that process whole directories of files using SLURM
arrays. Also works for paired files (like paired-end FASTQ files). 

# VERSION

0.0.30

# SYNOPSIS

    # Compress all ".txt" files in the directory using a SLURM Array
    sarray_script --cpu=32 --file-pattern='*.txt' --job=pigz_files --command='pigz --processes 32 $FILE'

    # Given A_header.txt, A_body.txt, B_header.txt, and B_body.text, you could do the following  
    sarray_script --run --file-pattern='*_header.txt' --paired-pattern='*_body.txt' --job=combine_files --command='cat $FILE $PAIRED_FILE > $FILE_PREFIX.doc.txt'

    # Then for the bioinformaticians out there, work on those paired-end sequences:
    sarray_script --file-pattern='*R1*' --paired-pattern='*R2*' --job=trim_files --command='cutadapt -a AGAT... -A AGAT... --output=${FILE_PREFIX}_for.fastq.gz --paired-output=${FILE_PREFIX}_rev.fastq.gz'


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

Even if you don't mention `$FILE` on the command line, it will still be
available inside your script if you used the `--file-pattern` option.

Even if you don't mentioned `$PAIRED_FILE` or `$FILE_PREFIX` on the command
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

0.0.30: changed long name of paired option from --paired-file-pattern to --paired-pattern  
0.0.29: Internal refactor  
0.0.28: Renamed sbatch_script to sarray_script. Split off timeout test. Other minor tweaks.  
0.0.27: Added real adapters instead of "AGAT", because you know people really will copy and paste this code, despite the warning.  
0.0.26: cleaned up README a little  
0.0.25: Added Disclaimer and slight formatting improvements to README  
0.0.24: Improved documentation  
0.0.23: Long option names use dash instead of underscore (like Linux utilities). Also added more documentation and examples in README.  
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

# DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
