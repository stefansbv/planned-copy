#
# Test the install command
#
use Test::More;

use Capture::Tiny 0.12 qw(:all);
use Path::Tiny;
use Try::Tiny;
use App::PlannedCopy::Config;
use App::PlannedCopy::Command::Install;

local $ENV{APP_CM_USR_CONFIG} = path( qw(t user.conf) );

ok my $conf = App::PlannedCopy::Config->new, 'config constructor';

ok $conf->load, 'load test config files';

ok $file = $conf->resource_file('other'), 'get resurce file';
is $file, 't/repo/other/resource.yml', 'resource file path';

ok my $cmd = App::PlannedCopy::Command::Install->new(
    project => 'other',
    config  => $conf,
    ), 'install command constructor';

ok my $res = App::PlannedCopy::Resource->new( resource_file => $file),
    'res instance';

ok my $iter = $res->resource_iter, 'iterator';
while ( $iter->has_next ) {
    ok my $rec  = $iter->next, 'get next item';
    try {
        ok $cmd->install_file($rec), "install " . $rec->src->_name;
    };
}

done_testing;
