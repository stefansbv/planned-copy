#
# Test the Printable role
#
use Test::Most;
use Test::Moose;
use Path::Tiny;
use lib 't/lib';
use TestCmd;

my @attributes = (qw( term_size _issue_category_color_map ));
my @methods    = (
    qw(
        points
        printer
        get_issue_header
        item_printer
        issue_printer
        print_exeception_message
        project_changes_list_printer
        project_list_printer
        difference_printer
        )
);

my $class = TestCmd->new;
map has_attribute_ok( $class, $_ ), @attributes;
map can_ok( $class, $_ ), @methods;

local $ENV{PLCP_SYS_CONFIG} = path(qw(t system.conf));
local $ENV{PLCP_USR_CONFIG} = path(qw(t user.conf));

# ok my $conf = App::PlannedCopy::Config->new, 'constructor';

# lives_ok{ $instance = $class->new(
#     project => 'test',
#     config  => $conf,
# )}                           'Test creation of an instance';

done_testing();
