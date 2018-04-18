#!/cluster/rcss-spack/opt/spack/linux-centos7-x86_64/gcc-4.8.5/python-3.6.0-m4jxztdzl45jsmtsx3vmlag5rcs4tm74/bin/python3
#sbatch_script.py

#NOTE:This requires python 3.6 an later (for use of f-strings)

import argparse
import sys
import pathlib
import re
import os
import glob
import subprocess

def common_prefix_for (a, b):
    end_idx=1
    current_substring = a[0:end_idx]
    longest_substring = ''
    while b.startswith(current_substring):
        longest_substring=current_substring
        end_idx += 1
        current_substring = a[0:end_idx]
    return longest_substring

def replace_nonword_characters (name):

    name = re.sub(r'\W','_',name)
    return name

# Create script name based on the job name
# If needed, make the scriptname versioned to avoid overwriting previous batch files
def job_script_name_for (job):
    job_name    = replace_nonword_characters(job)
    version     = 0
    script_name = f"{job_name}.sbatch"


    # Increment the version number until a unique script name is created
    while pathlib.Path(script_name).is_file():
        version += 1
        script_name = f"{job_name}.sbatch.{version}"

    return script_name

def sorted_filenames_matching (pattern):
    files = sorted(glob.glob(pattern))
    return files

def batch_header(args):

    header = f'''\
#!/bin/env bash
#SBATCH --job-name {args.job}
#SBATCH --mem {args.mem}
#SBATCH --cpus-per-task {args.cpu}
#SBATCH --ntasks 1
#SBATCH --nodes 1
#SBATCH --time {args.time}
'''

    if args.partition:
        header += f"#SBATCH --partition {args.partition}\n"

    if args.dependency:
        header += f"#SBATCH --dependency {args.dependency}\n"

    # Job file names
    if args.sarray_file_pattern:
        header += f"#SBATCH -o {args.job_files_dir}/job.oe_%A_%a\n"

    else:
        header += f"#SBATCH -o {job_files_dir}/job.oe_%j\n"

    if args.sarray_file_pattern:

        filenames = sorted_filenames_matching(args.sarray_file_pattern)

        header += f"#SBATCH --array=0-{len(filenames) - 1}"

        if args.sarray_limit:
            header += f"%{args.sarray_limit}"

        # Add newline (didn't put it on earlier in case we needed to wait for sarray_limit
        header += "\n" 

        #WARNING: Below is actually body, not header
        header += f"FILES=({' '.join(filenames)})\n\n"
        header += 'FILE=${FILES[$SLURM_ARRAY_TASK_ID]}' + "\n"

        # If paired, check that there are equal numbers of paired files
        if args.sarray_paired_file_pattern:
            paired_filenames = sorted_filenames_matching(args.sarray_paired_file_pattern)

            if len(paired_filenames) != len(filenames):
                print("Number of paired filenames is not equal to number of regular filenames")
                max_index = max(len(filenames), len(paired_filenames))

                print("File name (paired file name):")
                for index in range(0,max_index):
                    # first-filename  =        filenames[index] ? filenames[index] : ''
                    # paired_filename = paired_filenames[index] ? paired_filenames[infex] : ''
                    # print "{first-filename} ({paired_filename})"
                    print(index)


                print("Exiting ...")
                exit()
#
#
#             #WARNING: Below is actually body, not header
#             header += 'PAIRED_FILES=('
#                      + paired_filenames.join(' ')
#                      + ')'
#                      + "\n\n"
#             header += 'PAIRED_FILE={PAIRED_FILES[SLURM_ARRAY_TASK_ID]}' + "\n"
#
#             filename-prefixes
#
#             for (filenames Z paired_filenames).flat -> file, paired_file
#                 my prefix = common-prefix-for(file, paired_file)
#                 filename-prefixes.append(prefix)
#
#
#             #WARNING: Below is actually body, not header
#             header += 'FILENAME_PREFIXES=('
#                      + filename-prefixes.join(' ')
#                      + ')'
#                      + "\n\n"
#             header += 'FILENAME_PREFIX={FILENAME_PREFIXES[SLURM_ARRAY_TASK_ID]}' + "\n"

    return header





#     #WARNING: Below is actually body, not header
#     header +=  f'''\
#
#     # list all loaded modules
#     module list
#     '''
#
#     return header

# Create the text for a batch script
def batch_code (args):
    # Create batch header
    header = batch_header(args)

    # Add body to code
    code = f"{header}\n"

    # separate statements into separate lines
    lines = re.sub(r'\s*;\s*',"\n",args.wrap)

    code += lines

    return code



if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Create and run an sbatch script')
    parser.add_argument('job',              type=str, help='Job name (only alphanumeric, dash, or underscore allowed)')
    parser.add_argument('wrap',             type=str, help='Command to execute')
    parser.add_argument('--cpu',            type=int, help='Number of CPU cores to use (default: 1)', default=1)
    parser.add_argument('--mem',            type=str, help='Total RAM to allocate (default: "10G")', default='10G')
    parser.add_argument('--time',           type=str, help='Time limit (default: "1-00:00:00", meaning 1 day, 0 hours, 00 minutes, 00 seconds)', default='1-00:00:00')
    parser.add_argument('--partition',      type=str, help='partition to use')
    parser.add_argument('--job_files_dir',  type=str, help='job log directory (default: "job_files.dir")', default='job_files.dir')

    parser.add_argument('--dependency',     type=str, help='list of jobs that must finish before this one starts')
    parser.add_argument('--sarray_file_pattern', type=str,
            help='Pattern of files to include in sarray. With this option, you can $FILE in your script to refer to a file. (Required if --sarray_paired_file_pattern is used)',
            required=any(re.search('sarray_paired_file_pattern',argument) for argument in sys.argv)
    )
    parser.add_argument('--sarray_paired_file_pattern', type=str, help='Pattern of paired files to include in sarray (use $PAIRED_FILE in your script to refer to a paired file')
    parser.add_argument('--script_only',    type=bool, help="Create the script, but don't run it", default=False)
    parser.add_argument('--sarray_limit',   type=int, help='Number of simultaneous jobs to allow to run at the same time')

    args = parser.parse_args()

    pathlib.Path(args.job_files_dir).mkdir(parents=True, exist_ok=True)

    job_script_name = job_script_name_for(args.job)

    my_batch_code = batch_code(args)

    with open(job_script_name, "w") as fh:
        fh.write(my_batch_code)

    if args.script_only is not None:

        # Run batch file
        subprocess.run(['sbatch', job_script_name])







# sub common-prefix-for ($a, $b) {
#     my $current-substring = $a.substr(0,1);
#     my $longest-substring;
#
#     while $b.starts-with($current-substring) {
#         $longest-substring = $current-substring;
#         $current-substring = $a.substr(0,$++);
#     }
#
#     return $longest-substring;
# }
