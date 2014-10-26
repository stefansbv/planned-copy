# -*- cperl -*-
#
# Test the Utils role
#

use Test::Most;
use Test::Moose;

use Path::Tiny;
use MooseX::ClassCompositor;

use App::ConfigManager::Role::Utils;

my @attributes = ( qw() );
my @methods    = ( qw(is_selfsame copy_file set_perm) );

my $instance;
my $class = MooseX::ClassCompositor->new( { class_basename => 'Test', } )
    ->class_for( 'App::ConfigManager::Role::Utils', );
map has_attribute_ok( $class, $_ ), @attributes;
map can_ok( $class, $_ ), @methods;
lives_ok{ $instance = $class->new(
    project => 'test',
)}                           'Test creation of an instance';

# Copy
throws_ok { $instance->copy_file( path('file1'), path('file2') ) }
    qr/No such file or directory/, 'no such file or directory caught okay';
ok my $src = path('t/repo/other/config.pro'), 'source file path';
ok my $dst = path('t/etc/'), 'destination dir';
is $src->is_file, 1, 'src is file';
is $dst->is_dir, 1, 'dst is dir';
lives_ok { $instance->copy_file($src, $dst) } 'file copy';

# Set perm
throws_ok { $instance->set_perm( path('file2'), 0644 ) }
    qr/No such file or directory/, 'no such file or directory caught okay';
lives_ok { $instance->set_perm( path('t/etc'), 0644 ) } 'file set perm';

done_testing();

# end
