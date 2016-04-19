#
# Test the sync command
#
use Test::More;
use Term::ExtendedColor qw(uncolor);
use Capture::Tiny 0.12 qw(capture_stdout);
use Path::Tiny;
use File::Copy::Recursive qw(dircopy);
use App::PlannedCopy::Config;
use App::PlannedCopy::Command::Sync;

my $repo1_path = path(qw(t test-repo sync-no-resu));
my $repo2_path = path(qw(t test-repo sync));
my $dest_path  = path(qw(t test-dst sync));
my $repo2_path_orig = path(qw(t test-repo sync-orig));

local $ENV{PLCP_USR_CONFIG} = path( qw(t user.conf) );

# Cleanup
path($repo2_path)->remove_tree( { safe => 0 } ); # force remove
dircopy($repo2_path_orig, $repo2_path);

ok my $conf = App::PlannedCopy::Config->new, 'config constructor';

ok $conf->load, 'load test config files';

subtest 'No resource file' => sub {

    is $conf->resource_file('sync-no-resu'),
        path( $repo1_path, 'resource.yml' ), 'nonexistent resource file';

    ok my $sync = App::PlannedCopy::Command::Sync->new(
        project => 'sync-no-resu',
        config  => $conf,
    ), 'command constructor';

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

# Same contents, same perms - synced
subtest 'With a resource file - filename1' => sub {
    is $conf->resource_file('sync'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $sync = App::PlannedCopy::Command::Sync->new(
        project  => 'sync',
        config   => $conf,
        verbose  => 1,
        dst_name => 'filename1',
    ), 'command constructor';

    like uncolor ( capture_stdout { $sync->run } ),
        qr/Job: 1 file to check and sync/,
        'run should work';

    is capture_stdout { $sync->print_summary }, '
Summary:
 - processed   : 1 records
 - skipped     : 1
 - synchronized: 0

', 'print_summary should work';
};

# Different contents, same perms - update
subtest 'With a resource file - filename2' => sub {
    is $conf->resource_file('sync'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $sync = App::PlannedCopy::Command::Sync->new(
        project  => 'sync',
        config   => $conf,
        verbose  => 1,
        dst_name => 'filename2',
    ), 'command constructor';

    like uncolor ( capture_stdout { $sync->run } ),
        qr/Job: 1 file to check and sync/,
        'run should work';

    is capture_stdout { $sync->print_summary }, '
Summary:
 - processed   : 1 records
 - skipped     : 0
 - synchronized: 1

', 'print_summary should work';
};

# Not installed
subtest 'With a resource file - filename3' => sub {
    is $conf->resource_file('sync'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $sync = App::PlannedCopy::Command::Sync->new(
        project  => 'sync',
        config   => $conf,
        verbose  => 1,
        dst_name => 'filename3',
    ), 'command constructor';

    like uncolor ( capture_stdout { $sync->run } ),
        qr/Job: 1 file to check and sync/,
        'run should work';

    is capture_stdout { $sync->print_summary }, '
Summary:
 - processed   : 1 records
 - skipped     : 1
 - synchronized: 0

', 'print_summary should work';
};

# Same contents, different perms
subtest 'With a resource file - filename4' => sub {
    is $conf->resource_file('sync'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $sync = App::PlannedCopy::Command::Sync->new(
        project  => 'sync',
        config   => $conf,
        verbose  => 1,
        dst_name => 'filename4',
    ), 'command constructor';

    like uncolor ( capture_stdout { $sync->run } ),
        qr/Job: 1 file to check and sync/,
        'run should work';

    is capture_stdout { $sync->print_summary }, '
Summary:
 - processed   : 1 records
 - skipped     : 1
 - synchronized: 0

', 'print_summary should work';
};

# Not installed - skip
subtest 'With a resource file - filename5' => sub {
    is $conf->resource_file('sync'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $sync = App::PlannedCopy::Command::Sync->new(
        project  => 'sync',
        config   => $conf,
        verbose  => 1,
        dst_name => 'filename5',
    ), 'command constructor';

    like uncolor ( capture_stdout { $sync->run } ),
        qr/Job: 1 file to check and sync/,
        'run should work';

    is capture_stdout { $sync->print_summary }, '
Summary:
 - processed   : 1 records
 - skipped     : 1
 - synchronized: 0

', 'print_summary should work';
};

# Different contents, different perms - sync
subtest 'With a resource file - filename9' => sub {
    is $conf->resource_file('sync'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $sync = App::PlannedCopy::Command::Sync->new(
        project  => 'sync',
        config   => $conf,
        verbose  => 1,
        dst_name => 'filename9',
    ), 'command constructor';

    like uncolor ( capture_stdout { $sync->run } ),
        qr/Job: 1 file to check and sync/,
        'run should work';

    is capture_stdout { $sync->print_summary }, '
Summary:
 - processed   : 1 records
 - skipped     : 0
 - synchronized: 1

', 'print_summary should work';
};

# Different contents, different perms, different user - skip
subtest 'With a resource file - filename10' => sub {
    is $conf->resource_file('sync'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $sync = App::PlannedCopy::Command::Sync->new(
        project  => 'sync',
        config   => $conf,
        verbose  => 1,
        dst_name => 'filename10',
    ), 'command constructor';

    like uncolor ( capture_stdout { $sync->run } ),
        qr/Job: 1 file to check and sync/,
        'run should work';

    is capture_stdout { $sync->print_summary }, '
Summary:
 - processed   : 1 records
 - skipped     : 1
 - synchronized: 0

', 'print_summary should work';
};

# Different contents, different perms, filename with spaces - sync
subtest 'With a resource file - filename11' => sub {
    is $conf->resource_file('sync'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $sync = App::PlannedCopy::Command::Sync->new(
        project  => 'sync',
        config   => $conf,
        verbose  => 1,
        dst_name => 'filename11 with spaces',
    ), 'command constructor';

    like uncolor ( capture_stdout { $sync->run } ),
        qr/Job: 1 file to check and sync/,
        'run should work';

    is capture_stdout { $sync->print_summary }, '
Summary:
 - processed   : 1 records
 - skipped     : 0
 - synchronized: 1

', 'print_summary should work';
};

# Archive file - unpacked - skip
subtest 'With a resource file - archive1.tar.gz' => sub {
    is $conf->resource_file('sync'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $sync = App::PlannedCopy::Command::Sync->new(
        project  => 'sync',
        config   => $conf,
        verbose  => 1,
        dst_name => 'archive1.tar.gz',
    ), 'command constructor';

    like uncolor ( capture_stdout { $sync->run } ),
        qr/Job: 1 file to check and sync/,
        'run should work';

    is capture_stdout { $sync->print_summary }, '
Summary:
 - processed   : 1 records
 - skipped     : 1
 - synchronized: 0

', 'print_summary should work';
};

# Archive file - not unpacked
subtest 'With a resource file - archive2.tar.gz' => sub {
    is $conf->resource_file('sync'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $sync = App::PlannedCopy::Command::Sync->new(
        project  => 'sync',
        config   => $conf,
        verbose  => 1,
        dst_name => 'archive2.tar.gz',
    ), 'command constructor';

    like uncolor ( capture_stdout { $sync->run } ),
        qr/Job: 1 file to check and sync/,
        'run should work';

    is capture_stdout { $sync->print_summary }, '
Summary:
 - processed   : 1 records
 - skipped     : 1
 - synchronized: 0

', 'print_summary should work';
};

# Archive file, impolite - status not known - overwrite
subtest 'With a resource file - impolite.tar.gz' => sub {
    is $conf->resource_file('sync'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $sync = App::PlannedCopy::Command::Sync->new(
        project  => 'sync',
        config   => $conf,
        verbose  => 1,
        dst_name => 'impolite.tar.gz',
    ), 'command constructor';

    like uncolor ( capture_stdout { $sync->run } ),
        qr/Job: 1 file to check and sync/,
        'run should work';

    is capture_stdout { $sync->print_summary }, '
Summary:
 - processed   : 1 records
 - skipped     : 1
 - synchronized: 0

', 'print_summary should work';
};

# Archive file, naughty - status not known - overwrite
subtest 'With a resource file - naughty.tar.gz' => sub {
    is $conf->resource_file('sync'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $sync = App::PlannedCopy::Command::Sync->new(
        project  => 'sync',
        config   => $conf,
        verbose  => 1,
        dst_name => 'naughty.tar.gz',
    ), 'command constructor';

    like uncolor ( capture_stdout { $sync->run } ),
        qr/Job: 1 file to check and sync/,
        'run should work';

    is capture_stdout { $sync->print_summary }, '
Summary:
 - processed   : 1 records
 - skipped     : 1
 - synchronized: 0

', 'print_summary should work';
};


# Cleanup
path($repo2_path)->remove_tree( { safe => 0 } ); # force remove
dircopy($repo2_path_orig, $repo2_path);


# All together now...
subtest 'With a resource file - all' => sub {
    is $conf->resource_file('sync'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $sync = App::PlannedCopy::Command::Sync->new(
        project => 'sync',
        config  => $conf,
        verbose => 1,
    ), 'command constructor';

    like uncolor ( capture_stdout { $sync->run } ),
        qr/Job: 12 files to check and sync/,
        'run should work';

    is capture_stdout { $sync->print_summary }, '
Summary:
 - processed   : 12 records
 - skipped     : 9
 - synchronized: 3

', 'print_summary should work';
};


# Cleanup
path($repo2_path)->remove_tree( { safe => 0 } ); # force remove
dircopy($repo2_path_orig, $repo2_path);


# Again, all together now, verbose...
subtest 'With a resource file - all verbose' => sub {
    is $conf->resource_file('sync'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $sync = App::PlannedCopy::Command::Sync->new(
        project => 'sync',
        config  => $conf,
        verbose => 1,
    ), 'command constructor';

    like uncolor ( capture_stdout { $sync->run } ),
        qr/Job: 12 files to check and sync/,
        'run should work';
    is capture_stdout { $sync->print_summary }, '
Summary:
 - processed   : 12 records
 - skipped     : 9
 - synchronized: 3

', 'print_summary should work';
};

done_testing;
