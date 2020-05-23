#
# Test the Config module
#
use Test::More;
use Test::Exception;

use Path::Tiny;

use App::PlannedCopy::Config;

BEGIN {
    delete $ENV{PLCP_REPO_PATH};
    delete $ENV{PLCP_SYS_CONFIG};
    delete $ENV{PLCP_USR_CONFIG};
}

subtest 'Test with default config files and paths' => sub {
    ok my $conf = App::PlannedCopy::Config->new, 'constructor';

    like $conf->system_dir, qr{etc}, 'default system dir';
    like $conf->system_file, qr{etc/plannedcopy.conf},
      'default system file';
    is $conf->global_file, $conf->system_file, 'global_file is system_file';
    like $conf->user_file, qr{plannedcopy.conf$}, 'default user file';
};

subtest 'Test with no config files' => sub {

    local $ENV{PLCP_SYS_CONFIG} = path(qw(t nonexistent.conf));
    local $ENV{PLCP_USR_CONFIG} = path(qw(t nonexistent.conf));

    ok my $conf = App::PlannedCopy::Config->new, 'constructor';

    throws_ok { $conf->repo_path } 'Exception::Config::Error',
        'config error thrown';
    throws_ok { $conf->repo_path }
    qr/No 'local.path' is set/,
        'no local.path set in config caught okay';

    throws_ok { $conf->repo_url } 'Exception::Config::Error',
        'config error thrown';
    throws_ok { $conf->repo_url }
    qr/No remote.url is set/,
        'no remote.url set in config caught okay';

    like $conf->current_user, qr/\w+/, 'current user';
    is $conf->resource_file_name, 'resource.yml', 'resource file name';
    is $conf->resource_file_name_disabled, 'resource.yml.off',
        'disabled resource file name';

    like $conf->user_dir, qr/\//, 'user dir';
};

subtest 'Test with empty config files' => sub {

    local $ENV{PLCP_SYS_CONFIG} = path(qw(t system0.conf));
    local $ENV{PLCP_USR_CONFIG} = path(qw(t user0.conf));

    ok $conf = App::PlannedCopy::Config->new, 'constructor';

    ok $conf->load, 'load test config files';
    is scalar @{ $conf->config_files }, 2, '2 config files loaded';

    throws_ok { $conf->repo_path } 'Exception::Config::Error',
        'config error thrown';

    like $conf->current_user, qr/\w+/, 'current user';
    is $conf->resource_file_name, 'resource.yml', 'resource file name';
    is $conf->resource_file_name_disabled, 'resource.yml.off',
        'disabled resource file name';
};

subtest 'Test with minimum system config and empty user config' => sub {

    local $ENV{PLCP_REPO_PATH}  = path(qw(t configs));
    local $ENV{PLCP_SYS_CONFIG} = path(qw(t system1.conf));
    local $ENV{PLCP_USR_CONFIG} = path(qw(t user0.conf));

    my $repo_path = $ENV{PLCP_REPO_PATH};

    ok $conf = App::PlannedCopy::Config->new, 'constructor';

    ok $conf->load, 'load test config files';
    is scalar @{ $conf->config_files }, 2, '2 config files loaded';
    is $conf->repo_path, $repo_path, 'test repo path';
    throws_ok { $conf->repo_url }
    qr/No remote.url is set/,
        'no remote.url set in config caught okay';
    is $conf->resource_file('check'),
        path( $repo_path, qw(check resource.yml) ),
        'resource file path';
    is_deeply $conf->get_section( section => 'color' ), {},
        'color scheme is empty';
};

subtest 'Test with config files' => sub {

    local $ENV{PLCP_REPO_PATH}  = path(qw(t test-repo));
    local $ENV{PLCP_SYS_CONFIG} = path(qw(t system.conf));
    local $ENV{PLCP_USR_CONFIG} = path(qw(t user.conf));

    my $repo_path = $ENV{PLCP_REPO_PATH};

    ok $conf = App::PlannedCopy::Config->new, 'constructor';

    ok $conf->load, 'load test config files';
    is scalar @{ $conf->config_files }, 2, '2 config files loaded';

    is $conf->repo_path, $repo_path, 'test repo path';
    is $conf->repo_url, 'user@host:/git-repos/configs.git',
        'configs remote URL';
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

    local $ENV{PLCP_REPO_PATH}  = path(qw(t test-repo));
    local $ENV{PLCP_SYS_CONFIG} = path(qw(t system.conf));
    local $ENV{PLCP_USR_CONFIG} = path(qw(t user2.conf));

    my $repo_path = $ENV{PLCP_REPO_PATH};

    ok $conf = App::PlannedCopy::Config->new, 'constructor';

    ok $conf->load, 'load test config files';
    is scalar @{ $conf->config_files }, 2, '2 config files loaded';

    is $conf->repo_path, $repo_path, 'test repo path';
    is $conf->repo_url, 'user@host:/git-repos/configs.git',
        'configs remote URL';
    is $conf->uri, 'user@host:/git-repos/configs.git', 'configs repo uri';
    is $conf->resource_file('conf'),
        path( $repo_path, qw(conf resource-file.yml) ),
        'resource file path';
    like $conf->current_user, qr/\w+/, 'current user';
    is $conf->resource_file_name, 'resource-file.yml', 'resource file name';
    is $conf->resource_file_name_disabled, 'resource-file.yml.off',
        'disabled resource file name';

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
