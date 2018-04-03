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
        
        my $raw_job_id = qqx{ ../../sbatch_script --time=0:00:10 $job 'sleep 300; cat $file1 $file2 > $out'};
        my $job_id     = get_jobid($raw_job_id);
        my $wait_step  = qqx{ sbatch --output='wait.o_%j' --wait --dependency=$job_id --wrap='echo "Finished all jobs: ($job_id)"'};
        
        my $result = $out.IO.e;
        
        is $result, False, 'Timeout kills waiting process';

        shell "rm -rf *";
    });

    rmdir $timed_out_test_dir; 
};

# { # Test sarray
# 
#     shell 'for i in `seq 1 100`; do touch file_${i}_R1_001.fastq; touch file_${i}_R2_001.fastq; done';
# 
#     # Create files
#     my $file1              = file_for 'file1';
#     my $file2              = file_for 'file2';
#     my $expected_file_name = file_for 'expected';
#     
#     my $job = 'test_job';
#     my $out = 'result.out';
#     
#     my $raw_job_id = qqx{ ../sbatch_script $job 'cat $file1 $file2 > $out'};
#     my $job_id     = get_jobid($raw_job_id);
#     my $wait_step  = qqx{ sbatch --output='wait.o_%j' --wait --dependency=$job_id --wrap='echo "Finished all jobs: ($job_id)"'};
#     
#     my $result   = slurp $out;
#     my $expected = slurp $expected_file_name;
#     
#     is $result, $expected, 'Yes, it worked!'; 
# 
#     unlink $file1, $file2, $expected_file_name, $out; 
#     shell "rm -rf wait* job_files.dir $job.*";
# }

my $test2 = start { # Test basic 

    my $basic_test_dir = 'basic_test.dir';
    mkdir $basic_test_dir;

    indir( $basic_test_dir, {
        # Create files
        my $file1              = file_for 'file1';
        my $file2              = file_for 'file2';
        my $expected_file_name = file_for 'expected';
        
        my $job = 'test_job';
        my $out = 'result.out';
        
        my $raw_job_id = qqx{ ../../sbatch_script $job 'cat $file1 $file2 > $out'};
        my $job_id     = get_jobid($raw_job_id);
        my $wait_step  = qqx{ sbatch --output='wait.o_%j' --wait --dependency=$job_id --wrap='echo "Finished all jobs: ($job_id)"'};
        
        my $result   = slurp $out;
        my $expected = slurp $expected_file_name;
        
        is $result, $expected, 'Yes, it worked!'; 
    
        unlink $file1, $file2, $expected_file_name, $out; 
        shell "rm -rf wait* job_files.dir $job.*";
    });

    rmdir $basic_test_dir; 
};

await($test1, $test2);

done-testing;

sub file_for ($section) {
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
    );

    my $filename = "$section.txt";
    my $text = %text_for{$section};

    spurt $filename, %text_for{$section};
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
