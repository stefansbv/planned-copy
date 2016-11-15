#
# Test the Config module
#
use Test::More;
use Test::Exception;

use Path::Tiny;
use File::HomeDir;

use App::PlannedCopy::Config;

subtest 'Test with no config files' => sub {

    local $ENV{PLCP_SYS_CONFIG} = path(qw(t nonexistent.conf));
    local $ENV{PLCP_USR_CONFIG} = path(qw(t nonexistent.conf));

    ok my $conf = App::PlannedCopy::Config->new, 'constructor';

    throws_ok { $conf->repo_path } 'Exception::Config::Error',
        'config error thrown';
    throws_ok { $conf->repo_path }
    qr/No local.path is set/,
        'no local.path set in config caught okay';

    throws_ok { $conf->repo_url } 'Exception::Config::Error',
        'config error thrown';
    throws_ok { $conf->repo_url }
    qr/No remote.url is set/,
        'no remote.url set in config caught okay';

};

subtest 'Test with config files and minimum options' => sub {

    my $repo_path = path(qw(t configs));

    local $ENV{PLCP_SYS_CONFIG} = path(qw(t system0.conf));
    local $ENV{PLCP_USR_CONFIG} = path(qw(t user0.conf));

    ok $conf = App::PlannedCopy::Config->new, 'constructor';

    ok $conf->load, 'load test config files';
    is scalar @{ $conf->config_files }, 2, '2 config files loaded';

    is $conf->repo_path, $repo_path, 'test repo path';
    is $conf->repo_url, 'sys@host:/git-repos/configs.git',
        'configs repo url';
    is $conf->uri, 'sys@host:/git-repos/configs.git', 'configs repo uri';
    is $conf->resource_file('check'),
        path( $repo_path, qw(check resource.yml) ),
        'resource file path';

    is_deeply $conf->get_section( section => 'color' ), {},
        'color scheme is empty';
};

subtest 'Test with config files' => sub {

    my $repo_path = path(qw(t test-repo));

    local $ENV{PLCP_SYS_CONFIG} = path(qw(t system.conf));
    local $ENV{PLCP_USR_CONFIG} = path(qw(t user.conf));

    ok $conf = App::PlannedCopy::Config->new, 'constructor';

    ok $conf->load, 'load test config files';
    is scalar @{ $conf->config_files }, 2, '2 config files loaded';

    is $conf->repo_path, $repo_path, 'test repo path';
    is $conf->repo_url, 'user@host:/git-repos/configs.git',
        'configs repo url';
    is $conf->uri, 'user@host:/git-repos/configs.git', 'configs repo uri';
    is $conf->resource_file('check'),
        path( $repo_path, qw(check resource.yml) ),
        'resource file path';

    my $scheme_default = {
        info  => 'yellow2',
        warn  => 'blue2',
        error => 'red2',
        done  => 'green2',
    };

    is_deeply $conf->get_section( section => 'color' ), $scheme_default,
        'color scheme is from config';
};

subtest 'Test with config files - renamed resource file' => sub {

    my $repo_path = path(qw(t test-repo));

    local $ENV{PLCP_SYS_CONFIG} = path(qw(t system.conf));
    local $ENV{PLCP_USR_CONFIG} = path(qw(t user2.conf));

    ok $conf = App::PlannedCopy::Config->new, 'constructor';

    ok $conf->load, 'load test config files';
    is scalar @{ $conf->config_files }, 2, '2 config files loaded';

    is $conf->repo_path, $repo_path, 'test repo path';
    is $conf->repo_url, 'user@host:/git-repos/configs.git',
        'configs repo url';
    is $conf->uri, 'user@host:/git-repos/configs.git', 'configs repo uri';
    is $conf->resource_file('conf'),
        path( $repo_path, qw(conf resource-file.yml) ),
        'resource file path';

    my $scheme_default = {
        info  => 'yellow2',
        warn  => 'blue2',
        error => 'red2',
        done  => 'green2',
    };

    is_deeply $conf->get_section( section => 'color' ), $scheme_default,
        'color scheme is from config';
};

done_testing;
