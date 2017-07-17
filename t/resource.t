#
# Test the Resource object container
#
use Test::Most;

use App::PlannedCopy::Resource;

subtest 'Read resource' => sub {
    ok my $res = App::PlannedCopy::Resource->new(
        resource_file => 't/resource.yml' ), 'read a test resource file';

    isa_ok $res->reader, 'App::PlannedCopy::Resource::Read', 'resource read';

    is $res->get_resource_section('scope'), 'user',  'get section scope';
    is $res->get_resource_section('host'),  'host1', 'get section host';
    is ref $res->get_resource_section('resources'), 'ARRAY',
        'get section resources';

    is $res->resource_scope, 'user',  'resource scope';
    is $res->resource_host,  'host1', 'resource host';
    is ref $res->_resource, 'ARRAY', 'resources array';
    is $res->count, 5, 'resources count';
};

subtest 'Read resource - default scope, default host' => sub {
    ok my $res
        = App::PlannedCopy::Resource->new(
        resource_file => 't/resource-min.yml' ),
        'read another test resource file';

    isa_ok $res->reader, 'App::PlannedCopy::Resource::Read', 'resource read';

    is $res->get_resource_section('scope'), undef, 'get section scope';
    is $res->get_resource_section('host'),  undef, 'get section host';
    is ref $res->get_resource_section('resources'), 'ARRAY',
        'get section resources';

    is $res->resource_scope, 'user',      'default resource scope';
    is $res->resource_host,  'localhost', 'default resource host';
    is ref $res->_resource, 'ARRAY', 'resources array';
    is $res->count, 5, 'resources count';
};

subtest 'Read resource - no file' => sub {
    ok my $res
        = App::PlannedCopy::Resource->new(
        resource_file => 't/nonexistent-resource.yml' ),
        'read another test resource file';

    isa_ok $res->reader, 'App::PlannedCopy::Resource::Read', 'resource read';

    throws_ok { $res->get_resource_section('scope') }
    qr/Failed to find the resource/,
        'Should get an exception for missing resource file';
};

done_testing;
