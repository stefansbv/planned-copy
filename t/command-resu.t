#
# Test the resource command
#
use Test::More;

use Capture::Tiny 0.12 qw(:all);
use Path::Tiny;
use App::PlannedCopy::Config;
use App::PlannedCopy::Command::Resu;

my $repo_path  = path( qw( resu ) );
my $resu_file  = path( qw(t test-repo), $repo_path, 'resource.yml' );
my @test_files = ( qw{filename1 filename2 filename3 } );

local $ENV{PLCP_USR_CONFIG} = path( qw(t user.conf) );

ok my $conf = App::PlannedCopy::Config->new, 'config constructor';

ok $conf->load, 'load test config files';

subtest 'Create new resourec and add 3 files' => sub {

    is $conf->resource_file('resu'), $resu_file, 'resource file path';

    ok my $resu = App::PlannedCopy::Command::Resu->new(
        project => 'resu',
        config  => $conf,
        ),
        'resource command constructor';

    my @del = $resu->get_removed;
    my @upd = $resu->get_kept;
    my @add = $resu->get_added;

    my @del_files = ();
    my @upd_files = ();
    my @add_files = map { path( $repo_path, $_ )->stringify } @test_files;

    is_deeply \@del, \@del_files, 'deleted files list';
    is_deeply \@upd, \@upd_files, 'existing files list';
    is_deeply \@add, \@add_files, 'new files list';

    is capture_stdout { $resu->print_summary }, '
Summary:
 - removed: 0
 - kept   : 0
 - added  : 3

', 'print_summary should work';

    is capture_stdout { $resu->note }, "---
 Remember to EDIT the destination paths
  in '$resu_file'.
---
", 'note should work';

};

done_testing;
