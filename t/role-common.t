#
# Test the ::Validate::Common role
#
use Test::Most;
use Test::Moose;
use Path::Tiny;
use MooseX::ClassCompositor;

use App::PlannedCopy::Role::Validate::Common;
use App::PlannedCopy::Resource::Element;

# Test with the test config files
local $ENV{APP_CM_SYS_CONFIG} = path( qw(t system.conf) );
local $ENV{APP_CM_USR_CONFIG} = path( qw(t user.conf) );

my @attributes = ( qw() );

my @methods = (
    qw(src_isfile
       src_file_writeable
       src_dir_readable
       src_file_readable
       src_file_writable
       dst_file_defined
       dst_file_readable
       dst_dir_readable
       dst_path_writeable
       dst_path_exists
  ));

my $instance;
my $class = MooseX::ClassCompositor->new( { class_basename => 'Test', } )
    ->class_for( 'App::PlannedCopy::Role::Validate::Common', );
map has_attribute_ok( $class, $_ ), @attributes;
map can_ok( $class, $_ ), @methods;
lives_ok{ $instance = $class->new(
    project => 'test',
)} 'Test creation of an instance';

subtest 'src and dst ok' => sub {
    my $args = {
        destination => {
            name => 'system.conf',
            path => 't/test-dst/etc',
            perm => '0644',
        },
        source => {
            name => 'system.conf',
            path => 'check',
        },
    };
    ok my $elem = App::PlannedCopy::Resource::Element->new($args),
        'constructor';
    isa_ok $elem, 'App::PlannedCopy::Resource::Element';
    isa_ok $elem->src, 'App::PlannedCopy::Resource::Element::Source';
    isa_ok $elem->dst, 'App::PlannedCopy::Resource::Element::Destination';

    lives_ok { $instance->src_isfile($elem) } 'src path is valid';
    lives_ok { $instance->src_dir_readable($elem) } 'src path readable';
    lives_ok { $instance->src_file_readable($elem) } 'src file readable';
    lives_ok { $instance->src_file_writable($elem) } 'src file writeable';

    lives_ok { $instance->dst_file_defined($elem) } 'dst file defined';
    lives_ok { $instance->dst_path_exists($elem) } 'dst path exists';
    lives_ok { $instance->dst_dir_readable($elem) } 'dst path readable';
    lives_ok { $instance->dst_file_readable($elem) } 'dst file readable';
    lives_ok { $instance->dst_path_writeable($elem) } 'dst path writeable';
};

subtest 'nonexistent src file' => sub {
    my $args = {
        destination => {
            name => 'nonexistent.file',
            path => 't/test-dst/etc',
            perm => '0644',
        },
        source => {
            name => 'nonexistent.file',
            path => 'other',
        },
    };
    ok my $elem = App::PlannedCopy::Resource::Element->new($args),
        'constructor';
    isa_ok $elem, 'App::PlannedCopy::Resource::Element';
    isa_ok $elem->src, 'App::PlannedCopy::Resource::Element::Source';
    isa_ok $elem->dst, 'App::PlannedCopy::Resource::Element::Destination';

    throws_ok { $instance->src_isfile($elem) }
        qr/The source file was not found/,
        'src_isfile: src file not found caught';
    lives_ok { $instance->src_dir_readable($elem) } 'src path readable';
    throws_ok { $instance->src_file_readable($elem) }
        qr/No such file or directory/,
        'src_file_readable: src file not found caught';
    throws_ok { $instance->src_file_writable($elem) }
        qr/No such file or directory/,
        'src_file_writable: src file writeable caught';
    lives_ok { $instance->dst_file_defined($elem) } 'dst file defined';
};

subtest 'nonexistent dst file (res not installed yet)' => sub {
    my $args = {
        destination => {
            name => 'odbc.ini',
            path => 't/test-dst/etc',
            perm => '0644',
        },
        source => {
            name => 'odbc.ini',
            path => 'odbc/etc',
        },
    };
    ok my $elem = App::PlannedCopy::Resource::Element->new($args),
        'constructor';
    isa_ok $elem, 'App::PlannedCopy::Resource::Element';
    isa_ok $elem->src, 'App::PlannedCopy::Resource::Element::Source';
    isa_ok $elem->dst, 'App::PlannedCopy::Resource::Element::Destination';

    lives_ok { $instance->src_isfile($elem) } 'src path is valid';
    lives_ok { $instance->src_dir_readable($elem) } 'src path readable';
    lives_ok { $instance->src_file_readable($elem) } 'src file readable';
    lives_ok { $instance->src_file_writable($elem) } 'src file writeable';

    lives_ok { $instance->dst_file_defined($elem) } 'dst file defined';
    lives_ok { $instance->dst_path_exists($elem) } 'dst path exists';
    lives_ok { $instance->dst_dir_readable($elem) } 'dst path readable';
    throws_ok { $instance->dst_file_readable($elem) }
        qr/No such file or directory/,
        'dst_file_readable: no such file or directory caught';
    lives_ok { $instance->dst_path_writeable($elem) } 'dst path writeable';
};

subtest 'nonexistent dst path (res not installed yet)' => sub {
    my $args = {
        destination => {
            name => 'odbc.ini',
            path => 't/home/user',
            perm => '0644',
        },
        source => {
            name => 'odbc.ini',
            path => 'odbc/user',
        },
    };
    ok my $elem = App::PlannedCopy::Resource::Element->new($args),
        'constructor';
    isa_ok $elem, 'App::PlannedCopy::Resource::Element';
    isa_ok $elem->src, 'App::PlannedCopy::Resource::Element::Source';
    isa_ok $elem->dst, 'App::PlannedCopy::Resource::Element::Destination';

    lives_ok { $instance->src_isfile($elem) } 'src path is valid';
    lives_ok { $instance->src_dir_readable($elem) } 'src path readable';
    lives_ok { $instance->src_file_readable($elem) } 'src file readable';
    lives_ok { $instance->src_file_writable($elem) } 'src file writeable';

    lives_ok { $instance->dst_file_defined($elem) } 'dst file defined';
    throws_ok { $instance->dst_path_exists($elem) }
        qr/Not installed/,
        'dst_path_exists: not installed scaught';
    throws_ok { $instance->dst_dir_readable($elem) }
        qr/No such file or directory/,
        'dst_dir_readable: no such file or directory caught';
    throws_ok { $instance->dst_file_readable($elem) }
        qr/No such file or directory/,
        'dst_file_readable: no such file or directory caught';
    throws_ok { $instance->dst_path_writeable($elem) }
        qr/No such file or directory/,
        'dst_path_writeable: no such file or directory caught';
};

done_testing();

# end
