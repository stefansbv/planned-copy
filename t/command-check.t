#
# Test the check command
#
use Test::More;

use Capture::Tiny 0.12 qw(:all);
use Path::Tiny;
use App::PlannedCopy::Config;
use App::PlannedCopy::Command::Check;

local $ENV{APP_CM_USR_CONFIG} = path( qw(t user.conf) );

ok my $conf = App::PlannedCopy::Config->new, 'config constructor';

ok $conf->load, 'load test config files';

subtest 'No resource file' => sub {

    is $conf->resource_file('check-no-resu'),
        't/test-repo/check-no-resu/resource.yml', 'nonexistent resource file';

    ok my $check = App::PlannedCopy::Command::Check->new(
        project => 'check-no-resu',
        config  => $conf,
    ), 'resource command constructor';

    is $check->project, 'check-no-resu', 'project name';

    is capture_stdout { $check->execute },
        " check-no-resu, job: 0 files to check:

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

    is $conf->resource_file('check'), 't/test-repo/check/resource.yml',
        'resource file path';

    ok my $check = App::PlannedCopy::Command::Check->new(
        project => 'check',
        config  => $conf,
    ), 'other resource command constructor';

    like capture_stdout { $check->execute }, qr/job: 3 files to check:/,
        'execute should work';

    is capture_stdout { $check->print_project_summary }, '
Summary:
 - processed: 3 records
 - checked  : 3
 - skipped  : 0
 - different: 1

', 'print_summary should work';
};

done_testing();

