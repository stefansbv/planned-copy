#!/usr/bin/env perl
#
# Test the resource command
#
use Test::More tests => 9;

use Capture::Tiny 0.12 qw(:all);
use Path::Tiny;
use App::ConfigManager::Config;
use App::ConfigManager::Command::Resu;

local $ENV{APP_CM_USR_CONFIG} = path( qw(t user.conf) );

ok my $conf = App::ConfigManager::Config->new, 'config constructor';

ok $conf->load, 'load test config files';

is $conf->resource_file('odbc'), 't/repo/odbc/resource.yml',
    'resource file path';

ok my $resu = App::ConfigManager::Command::Resu->new(
    project => 'odbc',
    config  => $conf,
    ), 'resource command constructor';

my @del = $resu->get_removed;
my @upd = $resu->get_kept;
my @add = $resu->get_added;

my @del_files = ();
my @upd_files = ();
my @add_files = (
  "odbc/config1",
  "odbc/config3",
  "odbc/etc/odbc.ini",
  "odbc/etc/odbcinst.ini",
  "odbc/user/odbc.ini",
);

is_deeply \@del, \@del_files, 'deleted files list';
is_deeply \@upd, \@upd_files, 'existing files list';
is_deeply \@add, \@add_files, 'new files list';

is capture_stdout { $resu->print_summary }, '
Summary:
 - removed: 0
 - kept   : 0
 - added  : 5

', 'print_summary should work';

is capture_stdout { $resu->note }, "---
 Remember to EDIT the destination paths
  in 't/repo/odbc/resource.yml'.
---
", 'note should work';

# end
