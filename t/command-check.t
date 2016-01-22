#
# Test the check command
#
use Test::More;
use Term::ExtendedColor qw(uncolor);
use Capture::Tiny 0.12 qw(capture_stdout);
use Path::Tiny;
use App::PlannedCopy::Config;
use App::PlannedCopy::Command::Check;

my $repo1_path = path( qw(t test-repo check-no-resu) );
my $repo2_path = path( qw(t test-repo check) );
my $dest_path  = path( qw(t test-dst check) );

local $ENV{APP_CM_USR_CONFIG} = path( qw(t user.conf) );

ok my $conf = App::PlannedCopy::Config->new, 'config constructor';

ok $conf->load, 'load test config files';

subtest 'No resource file' => sub {

    is $conf->resource_file('check-no-resu'),
        path( $repo1_path, qw(resource.yml) ),
        'nonexistent resource file';

    ok my $check = App::PlannedCopy::Command::Check->new(
        project => 'check-no-resu',
        config  => $conf,
        verbose => 1,
    ), 'resource command constructor';

    is $check->project, 'check-no-resu', 'project name';

    is uncolor ( capture_stdout { $check->execute } ),
        " check-no-resu, job: 0 files to check (verbose):

---
There is no resource file for the 'check-no-resu' project.
Run the 'resu' command to create it.
---

Summary:
 - processed: 0 records
 - checked  : 0
 - skipped  : 0
 - different: 0

", 'execute should work';

    is capture_stdout { $check->print_project_summary }, '
Summary:
 - processed: 0 records
 - checked  : 0
 - skipped  : 0
 - different: 0

', 'print_summary should work';

};

subtest 'With a resource file' => sub {

    is $conf->resource_file('check'),
        path( $repo2_path, qw(resource.yml) ),
        'resource file path';

    ok my $check = App::PlannedCopy::Command::Check->new(
        project => 'check',
        config  => $conf,
        verbose => 1,
    ), 'command constructor';

    like uncolor ( capture_stdout { $check->execute } ),
        qr/check, job: 3 files to check/,
        'execute should work';

    is capture_stdout { $check->print_project_summary }, '
Summary:
 - processed: 3 records
 - checked  : 2
 - skipped  : 1
 - different: 1

', 'print_summary should work';
};

done_testing;
