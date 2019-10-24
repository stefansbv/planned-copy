#
# Test the Utils role
#
use Test::Most;
use Test::Moose;
use Path::Tiny;
use lib 't/lib';
use TestCmd;

if ( $^O eq 'MSWin32' ) {
    $ENV{COLUMNS} = 80;
    $ENV{LINES}   = 25;
}

local $ENV{PLCP_USR_CONFIG} = path( qw(t user.conf) );

my @attributes = ( qw(
    destination_path
    resource_old
    resource_new
    _compare
    _kept
    _removed
    _added
));
my @methods    = ( qw(
    _build_old_resource
    _build_new_resource
    _build_compare
    write_resource
    get_all_files
    update_resource
));

my $project = 'check';
my $cmd = TestCmd->new( project => $project );
map has_attribute_ok( $cmd, $_ ), @attributes;
map can_ok( $cmd, $_ ), @methods;

my $repo_path = path( qw(t test-repo) );
my $dest_path = path( qw(t test-dst) );

ok my $files = $cmd->get_all_files($project), 'resource files';
is ref $files, 'ARRAY', 'array of files';

ok my $data = $cmd->_build_old_resource, 'old resource';
is ref $data, 'HASH', 'resource';
ok !$cmd->has_no_old_res, 'project has resource file';
ok my @k = $cmd->old_res_keys, 'get resource keys';
foreach my $x (@k) {
    like $x, qr/^check/, "$x starts with project name";
}
is $cmd->resource_scope, 'system', 'scope is system';
is $cmd->resource_host, 'localhost', 'host is hostname';

done_testing();
