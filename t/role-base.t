#
# Test the Base role
#
use Test::Most;
use Test::Moose;
use MooseX::ClassCompositor;

use Path::Tiny;
use File::HomeDir;

use App::PlannedCopy::Role::Base;

my @attributes = ( qw(count_proc count_inst count_skip) );
my @methods    = ();

my $instance;
my $class = MooseX::ClassCompositor->new( { class_basename => 'Test', } )
    ->class_for( 'App::PlannedCopy::Role::Base', );
map has_attribute_ok( $class, $_ ), @attributes;
map can_ok( $class, $_ ), @methods;
lives_ok{ $instance = $class->new(
    project => 'test',
)} 'Test creation of an instance';

done_testing();
