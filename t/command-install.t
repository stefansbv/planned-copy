#
# Test the install command
#
use Test::More;

use Capture::Tiny 0.12 qw(:all);
use Path::Tiny;
use App::PlannedCopy::Config;
use App::PlannedCopy::Command::Install;

my $repo1_path = path( qw(t test-repo install-no-resu) );
my $repo2_path = path( qw(t test-repo install) );
my $dest_path  = path( qw(t test-dst install) );
my @test_files = ( qw{filename1 filename2 filename3 } );

local $ENV{APP_CM_USR_CONFIG} = path( qw(t user.conf) );

ok my $conf = App::PlannedCopy::Config->new, 'config constructor';

ok $conf->load, 'load test config files';

subtest 'No resource file' => sub {

    is $conf->resource_file('install-no-resu'),
        path( $repo1_path, 'resource.yml' ), 'nonexistent resource file';

    ok my $inst = App::PlannedCopy::Command::Install->new(
        project => 'install-no-resu',
        config  => $conf,
    ), 'command constructor';

    is $inst->project, 'install-no-resu', 'project name';

    is capture_stdout { $inst->run },
        "Job: 0 files to check and install:

---
There is no resource file for the 'install-no-resu' project.
Run the 'resu' command to create it.
---

Summary:
 - processed: 0 records
 - skipped  : 0
 - installed: 0

", 'run should work';

    is capture_stdout { $inst->print_summary }, '
Summary:
 - processed: 0 records
 - skipped  : 0
 - installed: 0

', 'print_summary should work';

};

subtest 'With a resource file' => sub {

    is $conf->resource_file('install'), path( $repo2_path, 'resource.yml' ),
        'resource file path';

    ok my $inst = App::PlannedCopy::Command::Install->new(
        project => 'install',
        config  => $conf,
    ), 'command constructor';
#BAIL_OUT('message');
    like capture_stdout { $inst->run }, qr/Job: 3 files to check and install:/,
        'run should work';

    is capture_stdout { $inst->print_summary }, '
Summary:
 - processed: 3 records
 - skipped  : 0
 - installed: 3

', 'print_summary should work';
};

# Cleanup

foreach my $name (@test_files) {
    my $file = path($dest_path, $name);
    unlink $file or warn "Could not unlink $file: $!";
}

rmdir $dest_path or warn "Could not rmdir $dest_path: $!";;

done_testing;
