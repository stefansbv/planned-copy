#!/usr/bin/env perl
#
# Test the resource command
#
use Test::More tests => 9;

use Capture::Tiny 0.12 qw(:all);
use Path::Tiny;
use App::ConfigManager::Config;
use App::ConfigManager::Command::Check;

local $ENV{APP_CM_USR_CONFIG} = path( qw(t user.conf) );

ok my $conf = App::ConfigManager::Config->new, 'config constructor';

ok $conf->load, 'load test config files';

is $conf->resource_file('odbc'), 't/repo/odbc/resource.yml',
    'resource file path';

#-- No resource file

ok my $check = App::ConfigManager::Command::Check->new(
    project => 'odbc',
    config  => $conf,
    ), 'resource command constructor';

is capture_stdout { $check->execute }, "Job: 0 files to check:

---
There is no resource file for the 'odbc' project.
Run the 'resu' command to create it.
---

Summary:
 - processed: 0
 - checked  : 0
 - skipped  : 0

", 'execute should work';

is capture_stdout { $check->print_summary }, '
Summary:
 - processed: 0
 - checked  : 0
 - skipped  : 0

', 'print_summary should work';

#-- With a resource file

ok $check = App::ConfigManager::Command::Check->new(
    project => 'other',
    config  => $conf,
    ), 'other resource command constructor';

like capture_stdout { $check->execute }, qr/Job: 5 files to check:/,
    'execute should work';

is capture_stdout { $check->print_summary }, '
Summary:
 - processed: 5
 - checked  : 0
 - skipped  : 5

', 'print_summary should work';

# end