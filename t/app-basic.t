#
# Test the application commands, parameters and options
#
use Test::Most tests => 12+1;                # don't remove the tests setting!
use Test::NoWarnings;
use Path::Tiny;

use App::PlannedCopy;

BEGIN {
    delete $ENV{PLCP_REPO_PATH};
    delete $ENV{PLCP_SYS_CONFIG};
    delete $ENV{PLCP_USR_CONFIG};
}

if ( $^O eq 'MSWin32' ) {
    $ENV{COLUMNS} = 80;
    $ENV{LINES}   = 25;
}

local $ENV{PLCP_REPO_PATH}  = path(qw(t test-repo));
local $ENV{PLCP_SYS_CONFIG} = path(qw(t system.conf));
local $ENV{PLCP_USR_CONFIG} = path(qw(t user.conf));

# Command: check

subtest 'Command "check" with full options' => sub {
    MooseX::App::ParsedArgv->new( argv => [qw(check test --dryrun --verbose)] );
    my $chk_01 = App::PlannedCopy->new_with_command();
    isa_ok( $chk_01, 'App::PlannedCopy::Command::Check' );
    is( $chk_01->dryrun, 1, 'Option "dryrun" is set' );
    is( $chk_01->verbose, 1, 'Option "verbose" is set' );
};

subtest 'Command "check" without options' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(check test)]);
    my $chk_02 = App::PlannedCopy->new_with_command();
    isa_ok($chk_02, 'App::PlannedCopy::Command::Check');
    is($chk_02->project, 'test', 'Param is set');
};

# Command: config

subtest 'Command "config" with full options' => sub {
    MooseX::App::ParsedArgv->new( argv => [qw(config set --dryrun --verbose --url user@host:/git-repos/configs.git --path repo/path)] );
    my $cfg_01 = App::PlannedCopy->new_with_command();
    isa_ok( $cfg_01, 'App::PlannedCopy::Command::Config' );
    is( $cfg_01->dryrun, 1, 'Option "dryrun" is set' );
    is( $cfg_01->verbose, 1, 'Option "verbose" is set' );
    is( $cfg_01->remote_url, 'user@host:/git-repos/configs.git', 'Option "remote_url" is set' );
    is( $cfg_01->local_path, 'repo/path', 'Option "local_path" is set' );
};

subtest 'Command "config" without options' => sub {
    MooseX::App::ParsedArgv->new( argv => [qw(config set)] );
    my $cfg_02 = App::PlannedCopy->new_with_command();
    isa_ok( $cfg_02, 'App::PlannedCopy::Command::Config' );
    is( $cfg_02->dryrun, undef, 'Option "dryrun" is not set' );
    is( $cfg_02->verbose, undef, 'Option "verbose" is not set' );
    is( $cfg_02->remote_url, undef, 'Option "remote_url" is not set' );
    is( $cfg_02->local_path, undef, 'Option "local_path" is not set' );
};

# Command: install

subtest 'Command "install" with full options' => sub {
    MooseX::App::ParsedArgv->new( argv => [qw(install test --dryrun --verbose)] );
    my $ins_01 = App::PlannedCopy->new_with_command();
    isa_ok( $ins_01, 'App::PlannedCopy::Command::Install' );
    is( $ins_01->dryrun, 1, 'Option "dryrun" is set' );
    is( $ins_01->verbose, 1, 'Option "verbose" is set' );
};

subtest 'Command "install" without options' => sub {
    MooseX::App::ParsedArgv->new( argv => [qw(install test)] );
    my $ins_01 = App::PlannedCopy->new_with_command();
    isa_ok( $ins_01, 'App::PlannedCopy::Command::Install' );
    is( $ins_01->dryrun, undef, 'Option "dryrun" is not set' );
    is( $ins_01->verbose, undef, 'Option "verbose" is not set' );
};

# Command: list

subtest 'Command "list" with parameter' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(list)]);
    my $res_01 = App::PlannedCopy->new_with_command();
    isa_ok($res_01, 'App::PlannedCopy::Command::List');
};

# Command: repo

subtest 'Command "repo" with parameter' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(repo clone)]);
    my $res_01 = App::PlannedCopy->new_with_command();
    isa_ok($res_01, 'App::PlannedCopy::Command::Repo');
    is($res_01->action, 'clone', 'Action is set');
};

# Command: resource

subtest 'Command "resource" with parameter' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(reso test)]);
    my $res_01 = App::PlannedCopy->new_with_command();
    isa_ok($res_01, 'App::PlannedCopy::Command::Resource');
    is($res_01->project, 'test', 'Param is set');
};

# Command: sync

subtest 'Command "sync" with full options' => sub {
    MooseX::App::ParsedArgv->new( argv => [qw(sync test --dryrun --verbose)] );
    my $ins_01 = App::PlannedCopy->new_with_command();
    isa_ok( $ins_01, 'App::PlannedCopy::Command::Sync' );
    is( $ins_01->dryrun, 1, 'Option "dryrun" is set' );
    is( $ins_01->verbose, 1, 'Option "verbose" is set' );
};

subtest 'Command "sync" without options' => sub {
    MooseX::App::ParsedArgv->new( argv => [qw(sync test)] );
    my $ins_01 = App::PlannedCopy->new_with_command();
    isa_ok( $ins_01, 'App::PlannedCopy::Command::Sync' );
    is( $ins_01->dryrun, undef, 'Option "dryrun" is not set' );
    is( $ins_01->verbose, undef, 'Option "verbose" is not set' );
};

subtest 'Command "sync" with all params' => sub {
    MooseX::App::ParsedArgv->new( argv => [qw(sync test somefile)] );
    my $ins_01 = App::PlannedCopy->new_with_command();
    isa_ok( $ins_01, 'App::PlannedCopy::Command::Sync' );
    is( $ins_01->dryrun, undef, 'Option "dryrun" is not set' );
    is( $ins_01->verbose, undef, 'Option "verbose" is not set' );
    is( $ins_01->dst_name, 'somefile', 'Param "somefile" is set');
};

# end
