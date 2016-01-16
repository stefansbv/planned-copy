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
    qw(
       src_parentdir_readable
       src_file_readable
	   src_isfile
       src_file_writeable
       dst_file_defined
       dst_parentdir_readable
       dst_file_readable
       dst_path_writeable
       dst_path_exists
	   dst_isfile
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
            name => 'filename1',
            path => 't/test-dst/check',
            perm => '0644',
        },
        source => {
            name => 'filename1',
            path => 'check',
        },
    };
    ok my $elem = App::PlannedCopy::Resource::Element->new($args),
        'constructor';
    isa_ok $elem, 'App::PlannedCopy::Resource::Element';
    isa_ok $elem->src, 'App::PlannedCopy::Resource::Element::Source';
    isa_ok $elem->dst, 'App::PlannedCopy::Resource::Element::Destination';

    lives_ok { $instance->src_parentdir_readable($elem) } 'src path readable';
    lives_ok { $instance->src_file_readable($elem) } 'src file readable';
    lives_ok { $instance->src_isfile($elem) } 'src path is valid';
    lives_ok { $instance->src_file_writeable($elem) } 'src file writeable';

    lives_ok { $instance->dst_file_defined($elem) } 'dst file defined';
    lives_ok { $instance->dst_parentdir_readable($elem) } 'dst path readable';
    lives_ok { $instance->dst_file_readable($elem) } 'dst file readable';
    lives_ok { $instance->dst_path_writeable($elem) } 'dst path writeable';
    lives_ok { $instance->dst_path_exists($elem) } 'dst path exists';
	lives_ok { $instance->dst_isfile($elem) } 'dst file exists';
};

subtest 'nonexistent src file' => sub {
    my $args = {
        destination => {
            name => 'nonexistent.file',
            path => 't/test-dst/check',
            perm => '0644',
        },
        source => {
            name => 'nonexistent.file',
            path => 'check',
        },
    };
    ok my $elem = App::PlannedCopy::Resource::Element->new($args),
        'constructor';
    isa_ok $elem, 'App::PlannedCopy::Resource::Element';
    isa_ok $elem->src, 'App::PlannedCopy::Resource::Element::Source';
    isa_ok $elem->dst, 'App::PlannedCopy::Resource::Element::Destination';

    lives_ok { $instance->src_parentdir_readable($elem) }
		'src parent dir readable';
    throws_ok { $instance->src_file_readable($elem) }
        qr/The source file was not found/,
        'src_file_readable: src file not found caught';
    throws_ok { $instance->src_isfile($elem) }
        qr/The source file was not found/,
        'src_isfile: src file not found caught';
    throws_ok { $instance->src_file_writeable($elem) }
        qr/No such file or directory/,
        'src_file_writable: no such file or directory caught';
    lives_ok { $instance->dst_file_defined($elem) } 'dst file defined';
};

subtest 'nonexistent dst file (res not installed yet)' => sub {
    my $args = {
        destination => {
            name => 'filename2',
            path => 't/test-dst/check',
            perm => '0644',
        },
        source => {
            name => 'filename2',
            path => 'check',
        },
    };
    ok my $elem = App::PlannedCopy::Resource::Element->new($args),
        'constructor';
    isa_ok $elem, 'App::PlannedCopy::Resource::Element';
    isa_ok $elem->src, 'App::PlannedCopy::Resource::Element::Source';
    isa_ok $elem->dst, 'App::PlannedCopy::Resource::Element::Destination';

    lives_ok { $instance->src_isfile($elem) } 'src path is valid';
    lives_ok { $instance->src_parentdir_readable($elem) }
		'src parent dir readable';
    lives_ok { $instance->src_file_readable($elem) } 'src file readable';
    lives_ok { $instance->src_file_writeable($elem) } 'src file writeable';

    lives_ok { $instance->dst_file_defined($elem) } 'dst file defined';
    lives_ok { $instance->dst_path_exists($elem) } 'dst path exists';
    lives_ok { $instance->dst_parentdir_readable($elem) }
		'dst parent dir readable';
    throws_ok { $instance->dst_file_readable($elem) }
        qr/Not installed/,
        'dst_file_readable: not installed caught';
    lives_ok { $instance->dst_path_writeable($elem) } 'dst path writeable';
};

subtest 'nonexistent dst path (res not installed yet)' => sub {
    my $args = {
        destination => {
            name => 'filename2',
            path => 't/test-dst/check2',
            perm => '0644',
        },
        source => {
            name => 'filename2',
            path => 'check',
        },
    };
    ok my $elem = App::PlannedCopy::Resource::Element->new($args),
        'constructor';
    isa_ok $elem, 'App::PlannedCopy::Resource::Element';
    isa_ok $elem->src, 'App::PlannedCopy::Resource::Element::Source';
    isa_ok $elem->dst, 'App::PlannedCopy::Resource::Element::Destination';

    lives_ok { $instance->src_parentdir_readable($elem) }
		'src parent dir readable';
    lives_ok { $instance->src_file_readable($elem) } 'src file readable';
	lives_ok { $instance->src_isfile($elem) } 'src path is valid';
    lives_ok { $instance->src_file_writeable($elem) } 'src file writeable';

    lives_ok { $instance->dst_file_defined($elem) } 'dst file defined';
    throws_ok { $instance->dst_parentdir_readable($elem) }
        qr/No such file or directory/,
        'dst_parentdir_readable: no such file or directory caught';
    throws_ok { $instance->dst_file_readable($elem) }
        qr/Not installed/,
        'dst_file_readable: not installed caught';
    throws_ok { $instance->dst_path_writeable($elem) }
        qr/No such file or directory/,
        'dst_path_writeable: no such file or directory caught';
    throws_ok { $instance->dst_path_exists($elem) }
        qr/Not installed/,
        'dst_path_exists: not installed scaught';
    throws_ok { $instance->dst_isfile($elem) }
        qr/Not installed/,
        'dst_path_exists: not installed scaught';
};

done_testing();

# end
