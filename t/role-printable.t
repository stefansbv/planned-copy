#
# Test the Printable role
#
use Test::Most;
use Test::Moose;
use Path::Tiny;
use lib 't/lib';
use TestCmd;

BEGIN {
    delete $ENV{PLCP_REPO_PATH};
    delete $ENV{PLCP_SYS_CONFIG};
    delete $ENV{PLCP_USR_CONFIG};
}

if ( $^O eq 'MSWin32' ) {
    $ENV{COLUMNS} = 80;
    $ENV{LINES}   = 25;
}

local $ENV{PLCP_REPO_PATH}  = path(qw(t test-repo));
local $ENV{PLCP_SYS_CONFIG} = path(qw(t system.conf));
local $ENV{PLCP_USR_CONFIG} = path(qw(t user.conf));

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

my $project = 'resource';
my $class = TestCmd->new( project => $project );
map has_attribute_ok( $class, $_ ), @attributes;
map can_ok( $class, $_ ), @methods;

done_testing;
