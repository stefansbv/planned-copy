#!/usr/bin/env perl
#
# Test the Config module
#
use Test::More tests => 12;
use Test::Exception;

use Path::Tiny;
use File::HomeDir;

use App::PlannedCopy::Config;

# Test with no config files

local $ENV{APP_CM_SYS_CONFIG} = path( qw(t nonexistent.conf) );
local $ENV{APP_CM_USR_CONFIG} = path( qw(t nonexistent.conf) );

ok my $conf = App::PlannedCopy::Config->new, 'constructor';

throws_ok { $conf->repo_path }
    'Exception::Config::Error', 'config error thrown';
throws_ok { $conf->repo_path }
    qr/No local.path is set/,
    'no local.path set in config caught okay';

throws_ok { $conf->repo_url }
    'Exception::Config::Error', 'config error thrown';
throws_ok { $conf->repo_url }
    qr/No remote.url is set/,
    'no remote.url set in config caught okay';

# throws_ok { App::PlannedCopy::Config->new }
#     qr/No configuration files loaded/,
#     'no config files loaded caught okay';

# throws_ok { my $conf = App::PlannedCopy::Config->new }
#     'Exception::Config::NoConfig', 'no config error thrown';

# Test with the test config files

local $ENV{APP_CM_SYS_CONFIG} = path( qw(t system.conf) );
local $ENV{APP_CM_USR_CONFIG} = path( qw(t user.conf) );

ok $conf = App::PlannedCopy::Config->new, 'other constructor';

ok $conf->load, 'load test config files';
is scalar @{$conf->config_files}, 2, '2 config files loaded';

is $conf->repo_path, 't/repo', 'test repo path';
is $conf->repo_url, 'user@host:/git-repos/configs.git', 'configs repo url';
is $conf->uri, 'user@host:/git-repos/configs.git', 'configs repo uri';
is $conf->resource_file('other'), 't/repo/other/resource.yml',
    'resource file path';

# end
