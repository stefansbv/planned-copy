#
# Test the resource command
#
use Test::More;

use Capture::Tiny 0.12 qw(:all);
use Path::Tiny;
use App::PlannedCopy::Config;
use App::PlannedCopy::Command::Resource;

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

subtest 'Create new resource and add 3 files' => sub {

    is $conf->resource_file('resource'), $reso_file, 'resource file path';

    ok my $reso = App::PlannedCopy::Command::Resource->new(
        project => 'resource',
        config  => $conf,
    ), 'resource command constructor';

    my @del = $reso->get_removed;
    my @upd = $reso->get_kept;
    my @add = $reso->get_added;

    my @del_files = ();
    my @upd_files = ();
    my @add_files = map { path( $repo_path, $_ )->stringify } @test_files;

    is_deeply \@del, \@del_files, 'deleted files list';
    is_deeply \@upd, \@upd_files, 'existing files list';
    is_deeply \@add, \@add_files, 'new files list';

    is capture_stdout { $reso->print_summary }, '
Summary:
 - removed: 0
 - kept   : 0
 - added  : 3

', 'print_summary should work';

};

done_testing;
