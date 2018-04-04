#!/bin/env perl6

use Test;

chdir 't';

my $test1 = start { # Check what happens with waiting on timed out job
    my $timed_out_test_dir = 'timed_out_test.dir';
    mkdir $timed_out_test_dir;

    indir( $timed_out_test_dir, {
        # Create files
        my $file1              = file_for 'file1';
        my $file2              = file_for 'file2';
        my $expected_file_name = file_for 'expected';

        my $job = 'test_job';
        my $out = 'result.out';

        my $raw_job_id = qqx{ ../../bin/sbatch_script --time=0:00:10 $job 'sleep 300; cat $file1 $file2 > $out'};
        my $job_id     = get_jobid($raw_job_id);
        my $wait_step  = qqx{ sbatch --output='wait.o_%j' --wait --dependency=$job_id --wrap='echo "Finished all jobs: ($job_id)"'};

        my $result = $out.IO.e;

        is $result, False, 'Timeout correctly killed waiting process';

        shell "rm -rf *";
    });

    rmdir $timed_out_test_dir;
};

my $test2 = start { # Test paired files
    my $paired_test_dir = 'paired_test.dir';
    mkdir $paired_test_dir;

    indir( $paired_test_dir, {

        my @files1;
        my @files2;

        for 11 .. 12 -> $i {
            @files1.append(file_for('fastq1', :filename("file_{$i}_R1_001.fastq")));
            @files2.append(file_for('fastq2', :filename("file_{$i}_R2_001.fastq")));
        }

        my $job = 'test_job';

        my $raw_job_id = qx{ ../../bin/sbatch_script --sarray-file-pattern='_R1_001.fastq$' --sarray-paired-file-pattern='_R2_001.fastq$' get_seqs 'awk "\{if (FNR % 4 == 2) print\}" $FILE > forward.$SLURM_ARRAY_TASK_ID.seqs; awk "\{if (FNR % 4 == 2) print\}" $PAIRED_FILE > reverse.$SLURM_ARRAY_TASK_ID.seqs; '};
        my $job_id     = get_jobid($raw_job_id);
        my $wait_step  = qqx{ sbatch --output='wait.o_%j' --wait --dependency=$job_id --wrap='echo "Finished all jobs: ($job_id)"'};

        for 0 .. 1 -> $i {
            my $result1   = slurp "forward.$i.seqs";
            my $result2   = slurp "reverse.$i.seqs";
            my $expected1 = text_for('expected_seq1');
            my $expected2 = text_for('expected_seq2');
            is $result1, $expected1, 'Good results for ' ~   '$FILE when SLURM_ARRAY_TASK_ID=' ~ $i;
            is $result2, $expected2, 'Good results for $PAIRED-FILE when SLURM_ARRAY_TASK_ID=' ~ $i;
        }

        shell 'rm -rf *';
    });
    rmdir $paired_test_dir;
};

my $test3 = start { # Test basic

    my $basic_test_dir = 'basic_test.dir';
    mkdir $basic_test_dir;

    indir( $basic_test_dir, {
        # Create files
        my $file1              = file_for 'file1';
        my $file2              = file_for 'file2';

        my $job = 'test_job';
        my $out = 'result.out';

        my $raw_job_id = qqx{ ../../bin/sbatch_script $job 'cat $file1 $file2 > $out'};
        my $job_id     = get_jobid($raw_job_id);
        my $wait_step  = qqx{ sbatch --output='wait.o_%j' --wait --dependency=$job_id --wrap='echo "Finished all jobs: ($job_id)"'};

        my $result   = slurp $out;

        is $result, text_for('expected'), 'basic use works';

        unlink $file1, $file2, $out;
        shell "rm -rf wait* job_files.dir $job.*";
    });

    rmdir $basic_test_dir;
};

my $test4 = start { # Test prefix extraction
    my $prefix_test_dir = 'prefix_test.dir';
    mkdir $prefix_test_dir;

    indir( $prefix_test_dir, {

        my @files1;
        my @files2;

        for 11 .. 12 -> $i {
            @files1.append(file_for('fastq1', :filename("file_{$i}_R1_001.fastq")));
            @files2.append(file_for('fastq2', :filename("file_{$i}_R2_001.fastq")));
        }

        my $job = 'test4';

        my $raw_job_id = qx{ ../../bin/sbatch_script --sarray-file-pattern='_R1_001.fastq$' --sarray-paired-file-pattern='_R2_001.fastq$' check_prefixes 'echo "$FILENAME_PREFIX" > temp_prefix_$FILENAME_PREFIX.txt'};
        my $job_id     = get_jobid($raw_job_id);
        my $wait_step  = qqx{ sbatch --output='wait.o_%j' --wait --dependency=$job_id --wrap='echo "Finished all jobs: ($job_id)"'};

        my $result   = qqx{ cat temp_prefix_*.txt | sort };
        my $expected = "file_11_R\nfile_12_R\n";

        is $result, $expected, "Found file name prefixes for paired files";

        shell 'rm -rf *';
    });
    rmdir $prefix_test_dir;
};

await($test1, $test2, $test3, $test4);

done-testing;

sub text_for ($section) {
    my %text_for = %(
        file1 => q:to/END/,
                 TATGACCTTC
                 TCACCAATCC
                 GTAAGCACTG
                 END

        file2 => q:to/END/,
                 CCATTGGAAA
                 TAGCACGTTA
                 TATAAATAAG
                 END

        expected => q:to/END/,
                    TATGACCTTC
                    TCACCAATCC
                    GTAAGCACTG
                    CCATTGGAAA
                    TAGCACGTTA
                    TATAAATAAG
                    END

        fastq1 => q:to/END/,
                  @0
                  GAGGCCGGAG
                  +
                  EJEGJEIIJF
                  @1
                  GCGTTCCTTA
                  +
                  IJFEEIJEGJ
                  END

        fastq2 => q:to/END/,
                  @0
                  CAGTATTCGAGCG
                  +
                  GIEIFHGFHEFFH
                  @1
                  CCGGAAGAAGGTC
                  +
                  HHFJJGIJJJJFE
                  END
        expected_seq1 => q:to/END/,
                  GAGGCCGGAG
                  GCGTTCCTTA
                  END
        expected_seq2 => q:to/END/,
                  CAGTATTCGAGCG
                  CCGGAAGAAGGTC
                  END
    );

    my $text = %text_for{$section};

    return $text;
}

sub file_for ($section, :$filename="$section.txt") {
    my $text = text_for($section);
    spurt $filename, $text;
    return $filename;
}

sub get_jobid ($string) {

    die 'Cannot get job ID from Empty String' if $string eq '';

    # remove newline character (if any)
    chomp $string;

    # Extract jobid
    if $string ~~ /^ .* \s (\d+) \s* $ / {
        my $jobid = $0;
        return $jobid;
    }
    else {
        die "Could not identify jobid in '$string'";
    }
    return;
}
# vim:set filetype=perl6:
