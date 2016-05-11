#
# Test the ::Validate::Sync role
#
use Test::Most;
use Test::Moose;
use Path::Tiny;
use MooseX::ClassCompositor;

use App::PlannedCopy::Role::Validate::Sync;
use App::PlannedCopy::Resource::Element;

# Test with the test config files
local $ENV{PLCP_SYS_CONFIG} = path( qw(t system.conf) );
local $ENV{PLCP_USR_CONFIG} = path( qw(t user.conf) );

my @attributes = ( qw() );

my @methods = (
    qw(
        is_selfsame
        copy_file
        set_perm
        set_owner
        handle_exception
        exception_to_issue
        no_resource_message
        quote_string
        compare
        get_project_files
        check_res_user
        check_user
        src_file_readable
        src_file_writeable
        dst_file_defined
        dst_file_readable
        dst_path_exists
        is_mode_default
        get_perms
        archive_is_unpacked
        is_src_and_dst_different
        is_owner_default
        is_mode_different
        )
);

my $instance;
my $class = MooseX::ClassCompositor->new( { class_basename => 'Test', } )
    ->class_for( 'App::PlannedCopy::Role::Validate::Sync', );
map has_attribute_ok( $class, $_ ), @attributes;
map can_ok( $class, $_ ), @methods;
lives_ok{ $instance = $class->new(
    project => 'test',
)} 'Test creation of an instance';

subtest 'source and destination ok - instaled' => sub {
    my $args = {
        destination => {
            name => 'filename1',
            path => 't/test-dst/role/sync',
            perm => '0644',
        },
        source => {
            name => 'filename1',
            path => 'sync',
        },
    };
    ok my $elem = App::PlannedCopy::Resource::Element->new($args),
        'constructor';
    isa_ok $elem, 'App::PlannedCopy::Resource::Element', 'element';
    isa_ok $elem->src, 'App::PlannedCopy::Resource::Element::Source', 'src';
    isa_ok $elem->dst, 'App::PlannedCopy::Resource::Element::Destination', 'dst';

    lives_ok { $instance->validate_element($elem) } 'validate element';
};

subtest 'nonexistent src file - not synced' => sub {
    my $args = {
        destination => {
            name => 'nonexistent.file',
            path => 't/test-dst/role/sync',
            perm => '0644',
        },
        source => {
            name => 'nonexistent.file',
            path => 'sync',
        },
    };
    ok my $elem = App::PlannedCopy::Resource::Element->new($args),
        'constructor';
    isa_ok $elem, 'App::PlannedCopy::Resource::Element', 'element';
    isa_ok $elem->src, 'App::PlannedCopy::Resource::Element::Source', 'src';
    isa_ok $elem->dst, 'App::PlannedCopy::Resource::Element::Destination', 'dst';

    throws_ok { $instance->validate_element($elem) }
        qr/The source file was not found/, 'validate element';
};

subtest 'nonexistent dst file - not installed' => sub {
    my $args = {
        destination => {
            name => 'filename2',
            path => 't/test-dst/role/sync',
            perm => '0644',
        },
        source => {
            name => 'filename2',
            path => 'sync',
        },
    };

    ok my $elem = App::PlannedCopy::Resource::Element->new($args),
        'constructor';
    isa_ok $elem, 'App::PlannedCopy::Resource::Element', 'element';
    isa_ok $elem->src, 'App::PlannedCopy::Resource::Element::Source', 'src';
    isa_ok $elem->dst, 'App::PlannedCopy::Resource::Element::Destination', 'dst';

    lives_ok { $instance->validate_element($elem) } 'validate element';
    is $elem->count_issues, 1, 'has an issue';
    like $elem->get_issue(0)->message, qr/Not installed/, 'has a "Not installed" issue';

};

subtest 'nonexistent dst path - not installed' => sub {
    my $args = {
        destination => {
            name => 'filename3',
            path => 't/test-dst/role/sync2',
            perm => '0644',
        },
        source => {
            name => 'filename3',
            path => 'sync',
        },
    };
    ok my $elem = App::PlannedCopy::Resource::Element->new($args),
        'constructor';
    isa_ok $elem, 'App::PlannedCopy::Resource::Element', 'element';
    isa_ok $elem->src, 'App::PlannedCopy::Resource::Element::Source', 'src';
    isa_ok $elem->dst, 'App::PlannedCopy::Resource::Element::Destination', 'dst';

    lives_ok { $instance->validate_element($elem) } 'validate element';

    is $elem->count_issues, 1, 'has an issue';
    like $elem->get_issue(0)->message, qr/Not installed/, 'has a "Not installed" issue';
};

# Archive files

subtest 'archive source file' => sub {
    my $args = {
        destination => {
            name => 'archive1.tar.gz',
            path => 't/test-dst/role/sync',
            perm => '0644',
            verb => 'unpack',
        },
        source => {
            name => 'archive1.tar.gz',
            path => 'sync',
            type => 'archive',
        },
    };
    ok my $elem = App::PlannedCopy::Resource::Element->new($args),
        'constructor';

    isa_ok $elem, 'App::PlannedCopy::Resource::Element', 'element';
    isa_ok $elem->src, 'App::PlannedCopy::Resource::Element::Source', 'src';
    isa_ok $elem->dst, 'App::PlannedCopy::Resource::Element::Destination', 'dst';

    lives_ok { $instance->validate_element($elem) } 'validate element';

    is $elem->count_issues, 1, 'has an issue';
    like $elem->get_issue(0)->message, qr/source is an archive/,
        'has a "The source is an archive" issue';
};

done_testing();
