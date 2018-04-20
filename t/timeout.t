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

        my $raw_job_id = qqx{ ../../bin/sarray_script --run --time=0:00:10 --job=$job --command='sleep 300; cat $file1 $file2 > $out'};
        my $job_id     = get_jobid($raw_job_id);
        my $wait_step  = qqx{ sbatch --partition=BioCompute,Lewis --output='wait.o_%j' --wait --dependency=$job_id --wrap='echo "Finished all jobs: ($job_id)"'};

        my $result = $out.IO.e;

        is $result, False, 'Timeout correctly killed waiting process';

        shell "rm -rf *";
    });

    rmdir $timed_out_test_dir;
};

await($test1);

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

    my $text = %text_for{$section};

    return $text;
}

sub file_for ($section, :$filename="$section.txt") {
    my $text = text_for($section);
    spurt $filename, $text;
    return $filename;
}

sub get_jobid ($string is copy) {

    die 'Cannot get job ID from Empty String' if $string eq '';

    # remove newline character (if any)
    $string.=chomp;

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
