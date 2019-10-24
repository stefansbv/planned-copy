#
# Test the Resource::Element object container
#
use Test::More;
use Path::Tiny;

use App::PlannedCopy::Resource::Element;
use App::PlannedCopy::Issue;

BEGIN {
    delete $ENV{PLCP_REPO_PATH};
}

subtest 'Minimum configuration - common file' => sub {
    local $ENV{PLCP_REPO_PATH} = path(qw(t test-repo));

    my $args = {
        destination => {
            name => 'lircd.conf',
            path => '/etc/lirc',
            perm => '0644',
        },
        source => {
            name => 'lircd.conf',
            path => 'lirc',
        },
    };

    ok my $elem = App::PlannedCopy::Resource::Element->new($args),
        'constructor';
    isa_ok $elem, 'App::PlannedCopy::Resource::Element';
    isa_ok $elem->src, 'App::PlannedCopy::Resource::Element::Source';
    isa_ok $elem->dst, 'App::PlannedCopy::Resource::Element::Destination';

    ok my $issue_1 = App::PlannedCopy::Issue->new(
        message => 'message',
        details => 'logmsg',
        category => 'warn',
    ), 'new issue 1';
    ok $elem->add_issue( $issue_1), 'add issue 1';
    is $elem->issues_category, 'warn', "the issue 1 category should be 'warn'";

    ok my $issue_2 = App::PlannedCopy::Issue->new(
        message => 'message 2',
        details => 'logmsg 2',
        category => 'error',
    ), 'new issue 2';
    ok $elem->add_issue( $issue_2), 'add issue 2';
    is $elem->issues_category, 'error', "the issue 2 category should now be 'error'";

    ok my $issue_3 = App::PlannedCopy::Issue->new(
        message => 'message 3',
        details => 'logmsg 3',
        category => 'info',
    ), 'new issue 3';
    ok $elem->add_issue( $issue_3), 'add issue 3';
    is $elem->issues_category, 'error', "the issue 3 category should now be still 'error'";


    # get_categ_weight
};

subtest 'Maximum configuration - archive file' => sub {
    local $ENV{PLCP_REPO_PATH} = path(qw(t test-repo));

    my $args = {
        destination => {
            name => 'icons.tar.gz',
            path => '~/',
            perm => '0644',
            verb => 'unpack',
        },
        source => {
            name => 'icons.tar.gz',
            path => 'linux',
            type => 'archive',
        },
    };

    ok my $elem = App::PlannedCopy::Resource::Element->new($args),
        'constructor';
    isa_ok $elem, 'App::PlannedCopy::Resource::Element';
    isa_ok $elem->src, 'App::PlannedCopy::Resource::Element::Source';
    isa_ok $elem->dst, 'App::PlannedCopy::Resource::Element::Destination';

    ok my $issue_1 = App::PlannedCopy::Issue->new(
        message => 'message',
        details => 'logmsg',
        category => 'warn',
    ), 'new issue 1';
    ok $elem->add_issue( $issue_1), 'add issue 1';
    is $elem->issues_category, 'warn', "the issue 1 category should be 'warn'";

    ok my $issue_2 = App::PlannedCopy::Issue->new(
        message => 'message 2',
        details => 'logmsg 2',
        category => 'error',
    ), 'new issue 2';
    ok $elem->add_issue( $issue_2), 'add issue 2';
    is $elem->issues_category, 'error', "the issue 2 category should now be 'error'";

    ok my $issue_3 = App::PlannedCopy::Issue->new(
        message => 'message 3',
        details => 'logmsg 3',
        category => 'info',
    ), 'new issue 3';
    ok $elem->add_issue( $issue_3), 'add issue 3';
    is $elem->issues_category, 'error', "the issue 3 category should now be still 'error'";

};

done_testing;
