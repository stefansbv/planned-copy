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
local $ENV{APP_CM_SYS_CONFIG} = path( qw(t system.conf) );
local $ENV{APP_CM_USR_CONFIG} = path( qw(t user.conf) );

my @attributes = ( qw() );

my @methods = (
    qw(
       src_file_readable
       src_file_writeable
       dst_file_defined
       dst_file_readable
       dst_path_exists
       dst_file_mode
       get_perms
  ));

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
    isa_ok $elem, 'App::PlannedCopy::Resource::Element';
    isa_ok $elem->src, 'App::PlannedCopy::Resource::Element::Source';
    isa_ok $elem->dst, 'App::PlannedCopy::Resource::Element::Destination';

    lives_ok { $instance->src_file_readable($elem) } 'src file readable';
    lives_ok { $instance->src_file_writeable($elem) } 'src file writeable';
    lives_ok { $instance->dst_file_defined($elem) } 'dst file defined';
    lives_ok { $instance->dst_file_readable($elem) } 'dst file readable';
    lives_ok { $instance->dst_path_exists($elem) } 'dst path exists';
    lives_ok { $instance->dst_file_mode($elem) } 'dst file mode ok';
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
    isa_ok $elem, 'App::PlannedCopy::Resource::Element';
    isa_ok $elem->src, 'App::PlannedCopy::Resource::Element::Source';
    isa_ok $elem->dst, 'App::PlannedCopy::Resource::Element::Destination';

    throws_ok { $instance->src_file_readable($elem) }
        qr/Exception::IO::FileNotFound/,
        'src_file_readable: src file not found caught';
    throws_ok { $instance->src_file_writeable($elem) }
        qr/Exception::IO::FileNotFound/,
        'src_file_writable: no such file or directory caught';
    lives_ok { $instance->dst_file_defined($elem) } 'dst file defined';

    # If command is 'install', adds an issue, doesn't throw an exception
    lives_ok { $instance->dst_file_readable($elem) } 'dst_file_readable';
    is $elem->count_issues, 1, 'has an issue';
    like $elem->get_issue(0)->message, qr/Not installed/, 'has a "Not installed" issue';

    lives_ok { $instance->dst_path_exists($elem) } 'dst path exists';
    throws_ok { $instance->dst_file_mode($elem) }
        qr/Exception::IO::FileNotFound/,
        'dst file mode: No such file or directory';
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
    isa_ok $elem, 'App::PlannedCopy::Resource::Element';
    isa_ok $elem->src, 'App::PlannedCopy::Resource::Element::Source';
    isa_ok $elem->dst, 'App::PlannedCopy::Resource::Element::Destination';

    lives_ok { $instance->src_file_readable($elem) } 'src_file_readable';
    lives_ok { $instance->src_file_writeable($elem) } 'src_file_writable';
    lives_ok { $instance->dst_file_defined($elem) } 'dst file defined';

    # If command is 'install', adds an issue, doesn't throw an exception
    lives_ok { $instance->dst_file_readable($elem) } 'dst_file_readable';
    is $elem->count_issues, 1, 'has an issue';
    like $elem->get_issue(0)->message, qr/Not installed/, 'has a "Not installed" issue';

    lives_ok { $instance->dst_path_exists($elem) } 'dst path exists';
    throws_ok { $instance->dst_file_mode($elem) }
        qr/Exception::IO::FileNotFound/,
        'dst file mode: No such file or directory caught';
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
    isa_ok $elem, 'App::PlannedCopy::Resource::Element';
    isa_ok $elem->src, 'App::PlannedCopy::Resource::Element::Source';
    isa_ok $elem->dst, 'App::PlannedCopy::Resource::Element::Destination';

    lives_ok { $instance->src_file_readable($elem) } 'src file readable';
    lives_ok { $instance->src_file_writeable($elem) } 'src file writeable';
    lives_ok { $instance->dst_file_defined($elem) } 'dst file defined';

    # If command is 'install', adds an issue, doesn't throw an exception
    lives_ok { $instance->dst_file_readable($elem) } 'dst_file_readable';
    is $elem->count_issues, 1, 'has an issue';
    like $elem->get_issue(0)->message, qr/Not installed/, 'has a "Not installed" issue';

    throws_ok { $instance->dst_path_exists($elem) }
        qr/Exception::IO::PathNotFound/,
        'dst path exists';
    throws_ok { $instance->dst_file_mode($elem) }
        qr/Exception::IO::FileNotFound/,
        'dst file mode: No such file or directory caught';
};

done_testing();
