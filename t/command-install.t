#
# Test the install command
#
use Test::Most;
use Term::ExtendedColor qw(uncolor);
use Capture::Tiny 0.12 qw(capture_stdout);
use Path::Tiny;
use File::Copy::Recursive qw(dircopy);
use App::PlannedCopy::Config;
use App::PlannedCopy::Command::Install;

my $repo_path  = path( qw(t test-repo) );
my $repo1_path = path(qw(t test-repo install-no-resu));
my $repo2_path = path(qw(t test-repo install));
my $dest_path  = path(qw(t test-dst install));
my $dest_path_orig = path(qw(t test-dst install-orig));

local $ENV{PLCP_USR_CONFIG} = path( qw(t user.conf) );

# Cleanup
path($dest_path)->remove_tree( { safe => 0 } ); # force remove
dircopy($dest_path_orig, $dest_path);

ok my $conf = App::PlannedCopy::Config->new, 'config constructor';

ok $conf->load, 'load test config files';

is $conf->repo_path, $repo_path, 'test repo path from t/user.conf';

subtest 'No resource file' => sub {

    is $conf->resource_file('install-no-resu'),
        path( $repo1_path, 'resource.yml' ), 'nonexistent resource file';

    ok my $inst = App::PlannedCopy::Command::Install->new(
        project => 'install-no-resu',
        config  => $conf,
    ), 'command constructor';

    is $inst->project, 'install-no-resu', 'project name';

    throws_ok { $inst->run } qr/No project named/,
        'Should get an exception for unknown project';
};

# Same contents, same perms - installed
subtest 'With a resource file - filename1' => sub {
    is $conf->resource_file('install'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $inst = App::PlannedCopy::Command::Install->new(
        project  => 'install',
        config   => $conf,
        verbose  => 1,
        dst_name => 'filename1',
    ), 'command constructor';

    like uncolor ( capture_stdout { $inst->run } ),
        qr/Job: 1 file to check and install/,
        'run should work';

    is capture_stdout { $inst->print_summary }, '
Summary:
 - processed: 1 records
 - skipped  : 1
 - installed: 0

', 'print_summary should work';
};

# Different contents, same perms - update
subtest 'With a resource file - filename2' => sub {
    is $conf->resource_file('install'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $inst = App::PlannedCopy::Command::Install->new(
        project  => 'install',
        config   => $conf,
        verbose  => 1,
        dst_name => 'filename2',
    ), 'command constructor';

    like uncolor ( capture_stdout { $inst->run } ),
        qr/Job: 1 file to check and install/,
        'run should work';

    is capture_stdout { $inst->print_summary }, '
Summary:
 - processed: 1 records
 - skipped  : 0
 - installed: 1

', 'print_summary should work';
};

# Not installed - install
subtest 'With a resource file - filename3' => sub {
    is $conf->resource_file('install'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $inst = App::PlannedCopy::Command::Install->new(
        project  => 'install',
        config   => $conf,
        verbose  => 1,
        dst_name => 'filename3',
    ), 'command constructor';

    like uncolor ( capture_stdout { $inst->run } ),
        qr/Job: 1 file to check and install/,
        'run should work';

    is capture_stdout { $inst->print_summary }, '
Summary:
 - processed: 1 records
 - skipped  : 0
 - installed: 1

', 'print_summary should work';
};

# Same contents, different perms
subtest 'With a resource file - filename4' => sub {
    is $conf->resource_file('install'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $inst = App::PlannedCopy::Command::Install->new(
        project  => 'install',
        config   => $conf,
        verbose  => 1,
        dst_name => 'filename4',
    ), 'command constructor';

    like uncolor ( capture_stdout { $inst->run } ),
        qr/Job: 1 file to check and install/,
        'run should work';

    is capture_stdout { $inst->print_summary }, '
Summary:
 - processed: 1 records
 - skipped  : 0
 - installed: 0

', 'print_summary should work';
};

# Not installed - skip
subtest 'With a resource file - filename5' => sub {
    is $conf->resource_file('install'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $inst = App::PlannedCopy::Command::Install->new(
        project  => 'install',
        config   => $conf,
        verbose  => 1,
        dst_name => 'filename5',
    ), 'command constructor';

    like uncolor ( capture_stdout { $inst->run } ),
        qr/Job: 1 file to check and install/,
        'run should work';

    is capture_stdout { $inst->print_summary }, '
Summary:
 - processed: 1 records
 - skipped  : 1
 - installed: 0

', 'print_summary should work';
};

# Different contents, different perms - install
subtest 'With a resource file - filename9' => sub {
    is $conf->resource_file('install'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $inst = App::PlannedCopy::Command::Install->new(
        project  => 'install',
        config   => $conf,
        verbose  => 1,
        dst_name => 'filename9',
    ), 'command constructor';

    like uncolor ( capture_stdout { $inst->run } ),
        qr/Job: 1 file to check and install/,
        'run should work';

    is capture_stdout { $inst->print_summary }, '
Summary:
 - processed: 1 records
 - skipped  : 0
 - installed: 1

', 'print_summary should work';
};

# Different contents, different perms, different user - skip
subtest 'With a resource file - filename10' => sub {
    is $conf->resource_file('install'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $inst = App::PlannedCopy::Command::Install->new(
        project  => 'install',
        config   => $conf,
        verbose  => 1,
        dst_name => 'filename10',
    ), 'command constructor';

    like uncolor ( capture_stdout { $inst->run } ),
        qr/Job: 1 file to check and install/,
        'run should work';

    is capture_stdout { $inst->print_summary }, '
Summary:
 - processed: 1 records
 - skipped  : 1
 - installed: 0

', 'print_summary should work';
};

# Different contents, different perms, filename with spaces - install
subtest 'With a resource file - filename11' => sub {
    is $conf->resource_file('install'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $inst = App::PlannedCopy::Command::Install->new(
        project  => 'install',
        config   => $conf,
        verbose  => 1,
        dst_name => 'filename11 with spaces',
    ), 'command constructor';

    like uncolor ( capture_stdout { $inst->run } ),
        qr/Job: 1 file to check and install/,
        'run should work';

    is capture_stdout { $inst->print_summary }, '
Summary:
 - processed: 1 records
 - skipped  : 0
 - installed: 1

', 'print_summary should work';
};

# Archive file - unpacked - skip
subtest 'With a resource file - archive1.tar.gz' => sub {
    is $conf->resource_file('install'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $inst = App::PlannedCopy::Command::Install->new(
        project  => 'install',
        config   => $conf,
        verbose  => 1,
        dst_name => 'archive1.tar.gz',
    ), 'command constructor';

    like uncolor ( capture_stdout { $inst->run } ),
        qr/Job: 1 file to check and install/,
        'run should work';

    is capture_stdout { $inst->print_summary }, '
Summary:
 - processed: 1 records
 - skipped  : 1
 - installed: 0

', 'print_summary should work';
};

# Archive file - not unpacked
subtest 'With a resource file - archive2.tar.gz' => sub {
    is $conf->resource_file('install'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $inst = App::PlannedCopy::Command::Install->new(
        project  => 'install',
        config   => $conf,
        verbose  => 1,
        dst_name => 'archive2.tar.gz',
    ), 'command constructor';

    like uncolor ( capture_stdout { $inst->run } ),
        qr/Job: 1 file to check and install/,
        'run should work';

    is capture_stdout { $inst->print_summary }, '
Summary:
 - processed: 1 records
 - skipped  : 0
 - installed: 1

', 'print_summary should work';
};

# Archive file, impolite - status not known - overwrite
subtest 'With a resource file - impolite.tar.gz' => sub {
    is $conf->resource_file('install'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $inst = App::PlannedCopy::Command::Install->new(
        project  => 'install',
        config   => $conf,
        verbose  => 1,
        dst_name => 'impolite.tar.gz',
    ), 'command constructor';

    like uncolor ( capture_stdout { $inst->run } ),
        qr/Job: 1 file to check and install/,
        'run should work';

    is capture_stdout { $inst->print_summary }, '
Summary:
 - processed: 1 records
 - skipped  : 0
 - installed: 1

', 'print_summary should work';
};

# Archive file, naughty - status not known - overwrite
subtest 'With a resource file - naughty.tar.gz' => sub {
    is $conf->resource_file('install'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $inst = App::PlannedCopy::Command::Install->new(
        project  => 'install',
        config   => $conf,
        verbose  => 1,
        dst_name => 'naughty.tar.gz',
    ), 'command constructor';

    like uncolor ( capture_stdout { $inst->run } ),
        qr/Job: 1 file to check and install/,
        'run should work';

    is capture_stdout { $inst->print_summary }, '
Summary:
 - processed: 1 records
 - skipped  : 0
 - installed: 1

', 'print_summary should work';
};


# Cleanup
path($dest_path)->remove_tree( { safe => 0 } ); # force remove
dircopy($dest_path_orig, $dest_path);


# All together now...
subtest 'With a resource file - all' => sub {
    is $conf->resource_file('install'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $inst = App::PlannedCopy::Command::Install->new(
        project => 'install',
        config  => $conf,
        verbose => 1,
    ), 'command constructor';

    like uncolor ( capture_stdout { $inst->run } ),
        qr/Job: 12 files to check and install/,
        'run should work';

    is capture_stdout { $inst->print_summary }, '
Summary:
 - processed: 12 records
 - skipped  : 4
 - installed: 7

', 'print_summary should work';
};


# Cleanup
path($dest_path)->remove_tree( { safe => 0 } ); # force remove
dircopy($dest_path_orig, $dest_path);


# Again, all together now, verbose...
subtest 'With a resource file - all verbose' => sub {
    is $conf->resource_file('install'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $inst = App::PlannedCopy::Command::Install->new(
        project => 'install',
        config  => $conf,
        verbose => 1,
    ), 'command constructor';

    like uncolor ( capture_stdout { $inst->run } ),
        qr/Job: 12 files to check and install/,
        'run should work';
    is capture_stdout { $inst->print_summary }, '
Summary:
 - processed: 12 records
 - skipped  : 4
 - installed: 7

', 'print_summary should work';
};

done_testing;
