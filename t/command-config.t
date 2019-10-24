#
# Test the resource command
#
use Test::More;

use Capture::Tiny 0.12 qw(:all);
use Path::Tiny;
use App::PlannedCopy::Config;
use App::PlannedCopy::Command::Config;

my $repo_path  = path( qw( resource ) );
my $reso_file  = path( qw(t test-repo), $repo_path, 'resource.yml' );
my @test_files = ( qw{filename1 filename2 filename3 } );

if ( $^O eq 'MSWin32' ) {
    $ENV{COLUMNS} = 80;
    $ENV{LINES}   = 25;
}

local $ENV{PLCP_USR_CONFIG} = path( qw(t user.conf) );

ok my $conf = App::PlannedCopy::Config->new, 'config constructor';

ok $conf->load, 'load test config files';

ok my $cmd = App::PlannedCopy::Command::Config->new(
    action => 'dump',
    config => $conf,
), 'config command constructor';

ok !$cmd->config_dump;

done_testing;
