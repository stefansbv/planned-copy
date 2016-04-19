#
# Test the diff command
#
use Test::More;
use Term::ExtendedColor qw(uncolor);
use Capture::Tiny 0.12 qw(capture_stdout);
use Path::Tiny;
use App::PlannedCopy::Config;
use App::PlannedCopy::Command::Diff;

my $repo1_path = path(qw(t test-repo check-no-resu));
my $repo2_path = path(qw(t test-repo check));
my $dest_path  = path(qw(t test-dst check));

local $ENV{PLCP_USR_CONFIG} = path(qw(t user.conf));

ok my $conf = App::PlannedCopy::Config->new, 'config constructor';

ok $conf->load, 'load test config files';

subtest 'No resource file' => sub {

    is $conf->resource_file('check-no-resu'),
        path( $repo1_path, 'resource.yml' ),
        'nonexistent resource file';

    ok my $diff = App::PlannedCopy::Command::Diff->new(
        project => 'check-no-resu',
        config  => $conf,
        ),
        'resource command constructor';

    is $diff->project, 'check-no-resu', 'project name';

    is capture_stdout { $diff->run }, "Job: 0 files to diff:

---
There is no resource file for the 'check-no-resu' project.
Run the 'resu' command to create it.
---

Summary:
 - processed: 0 records
 - skipped  : 0
 - same     : 0
 - different: 0

", 'run should work';

    is capture_stdout { $diff->print_summary }, '
Summary:
 - processed: 0 records
 - skipped  : 0
 - same     : 0
 - different: 0

', 'print_summary should work';

};

# Same contents, same perms - no diff
subtest 'With a resource file - filename1' => sub {
    is $conf->resource_file('check'),
        path( $repo2_path, 'resource.yml' ),
        'resource file path';

    ok my $diff = App::PlannedCopy::Command::Diff->new(
        project  => 'check',
        config   => $conf,
        verbose  => 1,
        diff_cmd => 'diff',
        dst_name => 'filename1',
        ),
        'command constructor';

    like capture_stdout { $diff->run },
        qr/Job: 1 file to diff/,
        'run should work';

    is capture_stdout { $diff->print_summary }, '
Summary:
 - processed: 1 records
 - skipped  : 0
 - same     : 1
 - different: 0

', 'print_summary should work';
};

# Different contents, same perms - diff
subtest 'With a resource file - filename2' => sub {
    is $conf->resource_file('check'),
        path( $repo2_path, 'resource.yml' ),
        'resource file path';

    ok my $diff = App::PlannedCopy::Command::Diff->new(
        project  => 'check',
        config   => $conf,
        verbose  => 1,
        diff_cmd => 'diff',
        dst_name => 'filename2',
        ),
        'command constructor';

    like capture_stdout { $diff->run },
        qr/Job: 1 file to diff/,
        'run should work';

    is capture_stdout { $diff->print_summary }, '
Summary:
 - processed: 1 records
 - skipped  : 0
 - same     : 0
 - different: 1

', 'print_summary should work';
};

# Not installed - no diff
subtest 'With a resource file - filename3' => sub {
    is $conf->resource_file('check'),
        path( $repo2_path, 'resource.yml' ),
        'resource file path';

    ok my $diff = App::PlannedCopy::Command::Diff->new(
        project  => 'check',
        config   => $conf,
        verbose  => 1,
        diff_cmd => 'diff',
        dst_name => 'filename2',
        ),
        'command constructor';

    like capture_stdout { $diff->run },
        qr/Job: 1 file to diff/,
        'run should work';

    is capture_stdout { $diff->print_summary }, '
Summary:
 - processed: 1 records
 - skipped  : 0
 - same     : 0
 - different: 1

', 'print_summary should work';
};

# Same contents, different perms - no diff
subtest 'With a resource file - filename4' => sub {
    is $conf->resource_file('check'),
        path( $repo2_path, 'resource.yml' ),
        'resource file path';

    ok my $diff = App::PlannedCopy::Command::Diff->new(
        project  => 'check',
        config   => $conf,
        verbose  => 1,
        diff_cmd => 'diff',
        dst_name => 'filename4',
        ),
        'command constructor';

    like capture_stdout { $diff->run },
        qr/Job: 1 file to diff/,
        'run should work';

    is capture_stdout { $diff->print_summary }, '
Summary:
 - processed: 1 records
 - skipped  : 0
 - same     : 0
 - different: 0

', 'print_summary should work';
};

# Not installed - no diff
subtest 'With a resource file - filename5' => sub {
    is $conf->resource_file('check'),
        path( $repo2_path, 'resource.yml' ),
        'resource file path';

    ok my $diff = App::PlannedCopy::Command::Diff->new(
        project  => 'check',
        config   => $conf,
        verbose  => 1,
        diff_cmd => 'diff',
        dst_name => 'filename5',
        ),
        'command constructor';

    like capture_stdout { $diff->run },
        qr/Job: 1 file to diff/,
        'run should work';

    is capture_stdout { $diff->print_summary }, '
Summary:
 - processed: 1 records
 - skipped  : 1
 - same     : 0
 - different: 0

', 'print_summary should work';
};

# Different contents, different perms
subtest 'With a resource file - filename6' => sub {
    is $conf->resource_file('check'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $check = App::PlannedCopy::Command::Diff->new(
        project  => 'check',
        config   => $conf,
        verbose  => 1,
        dst_name => 'filename6',
    ), 'command constructor';

    like uncolor ( capture_stdout { $check->run } ),
        qr/Job: 1 file to diff/,
        'run should work';

    is capture_stdout { $check->print_summary }, '
Summary:
 - processed: 1 records
 - skipped  : 0
 - same     : 0
 - different: 1

', 'print_summary should work';
};

# Different contents, different perms, different user
subtest 'With a resource file - filename7' => sub {
    is $conf->resource_file('check'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $check = App::PlannedCopy::Command::Diff->new(
        project  => 'check',
        config   => $conf,
        verbose  => 1,
        dst_name => 'filename7',
    ), 'command constructor';

    like uncolor ( capture_stdout { $check->run } ),
        qr/Job: 1 file to diff/,
        'run should work';

    is capture_stdout { $check->print_summary }, '
Summary:
 - processed: 1 records
 - skipped  : 1
 - same     : 0
 - different: 0

', 'print_summary should work';
};

# Different contents, different perms, filename with spaces
subtest 'With a resource file - filename8' => sub {
    is $conf->resource_file('check'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $check = App::PlannedCopy::Command::Diff->new(
        project  => 'check',
        config   => $conf,
        verbose  => 1,
        dst_name => 'filename8 with spaces',
    ), 'command constructor';

    like uncolor ( capture_stdout { $check->run } ),
        qr/Job: 1 file to diff/,
        'run should work';

    is capture_stdout { $check->print_summary }, '
Summary:
 - processed: 1 records
 - skipped  : 0
 - same     : 0
 - different: 1

', 'print_summary should work';
};

# Archive file - unpacked
subtest 'With a resource file - archive1.tar.gz' => sub {
    is $conf->resource_file('check'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $check = App::PlannedCopy::Command::Diff->new(
        project  => 'check',
        config   => $conf,
        verbose  => 1,
        diff_cmd => 'diff',
        dst_name => 'archive1.tar.gz',
        ),
        'command constructor';

    like uncolor( capture_stdout { $check->run } ),
        qr/Job: 1 file to diff/,
        'run should work';

    is capture_stdout { $check->print_summary }, '
Summary:
 - processed: 1 records
 - skipped  : 0
 - same     : 1
 - different: 0

', 'print_summary should work';
};

# Archive file - not unpacked
subtest 'With a resource file - archive2.tar.gz' => sub {
    is $conf->resource_file('check'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $check = App::PlannedCopy::Command::Diff->new(
        project  => 'check',
        config   => $conf,
        verbose  => 1,
        diff_cmd => 'diff',
        dst_name => 'archive2.tar.gz',
        ),
        'command constructor';

    like uncolor( capture_stdout { $check->run } ),
        qr/Job: 1 file to diff/,
        'run should work';

    is capture_stdout { $check->print_summary }, '
Summary:
 - processed: 1 records
 - skipped  : 1
 - same     : 0
 - different: 0

', 'print_summary should work';
};

# Archive file, impolite - status not known
subtest 'With a resource file - impolite.tar.gz' => sub {
    is $conf->resource_file('check'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $check = App::PlannedCopy::Command::Diff->new(
        project  => 'check',
        config   => $conf,
        verbose  => 1,
        diff_cmd => 'diff',
        dst_name => 'impolite.tar.gz',
        ),
        'command constructor';

    like uncolor( capture_stdout { $check->run } ),
        qr/Job: 1 file to diff/,
        'run should work';

    is capture_stdout { $check->print_summary }, '
Summary:
 - processed: 1 records
 - skipped  : 1
 - same     : 0
 - different: 0

', 'print_summary should work';
};

# Archive file, naughty - status not known
subtest 'With a resource file - naughty.tar.gz' => sub {
    is $conf->resource_file('check'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $check = App::PlannedCopy::Command::Diff->new(
        project  => 'check',
        config   => $conf,
        verbose  => 1,
        diff_cmd => 'diff',
        dst_name => 'naughty.tar.gz',
        ),
        'command constructor';

    like uncolor( capture_stdout { $check->run } ),
        qr/Job: 1 file to diff/,
        'run should work';

    is capture_stdout { $check->print_summary }, '
Summary:
 - processed: 1 records
 - skipped  : 1
 - same     : 0
 - different: 0

', 'print_summary should work';
};

# All together now...
subtest 'With a resource file - all' => sub {

    is $conf->resource_file('check'),
        path( $repo2_path, 'resource.yml' ),
        'resource file path';

    ok my $diff = App::PlannedCopy::Command::Diff->new(
        project  => 'check',
        config   => $conf,
        diff_cmd => 'diff',
        ),
        'command constructor';

    like uncolor( capture_stdout { $diff->run } ),
        qr/Job: 12 files to diff:/,
        'run should work';

    is capture_stdout { $diff->print_summary }, '
Summary:
 - processed: 12 records
 - skipped  : 6
 - same     : 2
 - different: 3

', 'print_summary should work';
};

done_testing;
