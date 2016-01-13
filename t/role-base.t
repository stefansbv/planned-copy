#
# Test the Base role
#
use Test::Most;
use Test::Moose;
use MooseX::ClassCompositor;

use Path::Tiny;
use File::HomeDir;

use App::PlannedCopy::Role::Base;

my @attributes = ( qw(count_proc count_inst count_skip error_level) );
my @methods    = ( qw(is_error_level is_not_error_level) );

my $instance;
my $class = MooseX::ClassCompositor->new( { class_basename => 'Test', } )
    ->class_for( 'App::PlannedCopy::Role::Base', );
map has_attribute_ok( $class, $_ ), @attributes;
map can_ok( $class, $_ ), @methods;
lives_ok{ $instance = $class->new(
    first_attribute => 'cool',
)} 'Test creation of an instance';

is $instance->is_error_level('info'), 1, 'error level is info';
is $instance->is_not_error_level('test'), 1, 'error level is not test';

done_testing();

# end
