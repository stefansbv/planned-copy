#
# Test the sync command
#
use Test::More;

use Capture::Tiny 0.12 qw(:all);
use Path::Tiny;
use App::PlannedCopy::Config;
use App::PlannedCopy::Command::Sync;

my $repo1_path = path( qw(t test-repo sync-no-resu) );
my $repo2_path = path( qw(t test-repo sync) );
my $dest_path  = path( qw(t test-dst sync) );

local $ENV{PLCP_USR_CONFIG} = path( qw(t user.conf) );

ok my $conf = App::PlannedCopy::Config->new, 'config constructor';

ok $conf->load, 'load test config files';

subtest 'No resource file' => sub {

    is $conf->resource_file('sync-no-resu'),
        path( $repo1_path, 'resource.yml' ),
        'nonexistent resource file';

    ok my $sync = App::PlannedCopy::Command::Sync->new(
        project => 'sync-no-resu',
        config  => $conf,
    ), 'resource command constructor';

    is $sync->project, 'sync-no-resu', 'project name';

    is capture_stdout { $sync->run },
        "Job: 0 files to check and synchronize:

---
There is no resource file for the 'sync-no-resu' project.
Run the 'resu' command to create it.
---

Summary:
 - processed   : 0 records
 - skipped     : 0
 - synchronized: 0

", 'run should work';

    is capture_stdout { $sync->print_summary }, '
Summary:
 - processed   : 0 records
 - skipped     : 0
 - synchronized: 0

', 'print_summary should work';

};

subtest 'With a resource file' => sub {

    is $conf->resource_file('sync'),
        path( $repo2_path, 'resource.yml' ),
        'resource file path';

    ok my $sync = App::PlannedCopy::Command::Sync->new(
        project => 'sync',
        config  => $conf,
    ), 'command constructor';

    like capture_stdout { $sync->run },
        qr/Job: 3 files to check and synchronize:/,
        'run should work';

    is capture_stdout { $sync->print_summary }, '
Summary:
 - processed   : 3 records
 - skipped     : 2
 - synchronized: 1

', 'print_summary should work';
};

# Rewind
my $dst_file3 = path( $repo2_path, 'filename3' );
my @lines = $dst_file3->lines;
splice @lines, 3, 0, "Line 2 (new)\n";
$dst_file3->spew(@lines);

done_testing;
