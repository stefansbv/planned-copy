#
# Test the ::Validate::Install role
#
use Test::Most;
use Test::Moose;
use Path::Tiny;
use MooseX::ClassCompositor;

use App::PlannedCopy::Role::Validate::Install;
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
        is_src_file_readable
        is_src_file_writable
        is_dst_file_defined
        is_dst_file_readable
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
    ->class_for( 'App::PlannedCopy::Role::Validate::Install', );
map has_attribute_ok( $class, $_ ), @attributes;
map can_ok( $class, $_ ), @methods;
lives_ok{ $instance = $class->new(
    project => 'test',
)} 'Test creation of an instance';

subtest 'source and destination ok - instaled' => sub {
    my $args = {
        destination => {
            name => 'filename1',
            path => 't/test-dst/role/install',
            perm => '0644',
        },
        source => {
            name => 'filename1',
            path => 'install',
        },
    };
    ok my $elem = App::PlannedCopy::Resource::Element->new($args),
        'constructor';
    isa_ok $elem, 'App::PlannedCopy::Resource::Element', 'element';
    isa_ok $elem->src, 'App::PlannedCopy::Resource::Element::Source', 'src';
    isa_ok $elem->dst, 'App::PlannedCopy::Resource::Element::Destination', 'dst';

    lives_ok { $instance->validate_element($elem) } 'validate element';

    ok $elem->has_no_issues, 'has no issues';
};

subtest 'nonexistent src file - not installed' => sub {
    my $args = {
        destination => {
            name => 'nonexistent.file',
            path => 't/test-dst/role/install',
            perm => '0644',
        },
        source => {
            name => 'nonexistent.file',
            path => 'install',
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
            path => 't/test-dst/role/install',
            perm => '0644',
        },
        source => {
            name => 'filename2',
            path => 'install',
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
            path => 't/test-dst/role/install2',
            perm => '0644',
        },
        source => {
            name => 'filename3',
            path => 'install',
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

subtest 'source and destination ok - instaled - archive1' => sub {
    my $args = {
        destination => {
            name => 'archive1.tar.gz',
            path => 't/test-dst/role/install',
            perm => '0644',
            verb => 'unpack',
        },
        source => {
            name => 'archive1.tar.gz',
            path => 'install',
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
    like $elem->get_issue(0)->message, qr/Not installed/, 'has a "Not installed" issue';
};

subtest 'nonexistent dst path - not installed - archive2' => sub {
    my $args = {
        destination => {
            name => 'archive2.tar.gz',
            path => 't/test-dst/role/install2',
            perm => '0644',
            verb => 'unpack',
        },
        source => {
            name => 'archive2.tar.gz',
            path => 'install',
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
    like $elem->get_issue(0)->message, qr/Not installed/, 'has a "Not installed" issue';
};

subtest 'nonexistent dst path - not installed - impolite archive' => sub {
    my $args = {
        destination => {
            name => 'impolite.tar.gz',
            path => 't/test-dst/role/install2',
            perm => '0644',
            verb => 'unpack',
        },
        source => {
            name => 'impolite.tar.gz',
            path => 'install',
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
    like $elem->get_issue(0)->message, qr/The archive is impolite/,
        'has a "The archive is impolite" issue';
};

subtest 'nonexistent dst path - not installed - naughty archive' => sub {
    my $args = {
        destination => {
            name => 'naughty.tar.gz',
            path => 't/test-dst/role/install2',
            perm => '0644',
            verb => 'unpack',
        },
        source => {
            name => 'naughty.tar.gz',
            path => 'install',
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
    like $elem->get_issue(0)->message, qr/The archive is naughty/,
        'has a "The archive is naughty" issue';
};

subtest 'nonexistent dst path - not installed - fake archive' => sub {
    my $args = {
        destination => {
            name => 'filename3',
            path => 't/test-dst/role/install2',
            perm => '0644',
            verb => 'unpack',
        },
        source => {
            name => 'filename3',
            path => 'install',
            type => 'archive',
        },
    };
    ok my $elem = App::PlannedCopy::Resource::Element->new($args),
        'constructor';

    isa_ok $elem, 'App::PlannedCopy::Resource::Element', 'element';
    isa_ok $elem->src, 'App::PlannedCopy::Resource::Element::Source', 'src';
    isa_ok $elem->dst, 'App::PlannedCopy::Resource::Element::Destination', 'dst';

    throws_ok { $instance->validate_element($elem) }
        qr/Exception::IO::FileNotArchive/,
        'validate_element: The file is not an archive caught';
    is $elem->count_issues, 0, 'has no issue';
};

done_testing();
