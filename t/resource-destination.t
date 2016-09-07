#
# Test the Resource::Element::Destination object independently
#
use Test::Most;
use Path::Tiny;

use App::PlannedCopy::Resource::Element::Destination;

my $repo_path = path( qw(t test-repo check) );
my $dest_path = path( qw(t test-dst check) );

subtest 'minimum valid config' => sub {
    my $args = {
        destination => {
            name => 'filename1',
            path => 't/test-dst/check',
            perm => '0644',
        },
    };

    ok my $dst = App::PlannedCopy::Resource::Element::Destination->new(
        $args->{destination} ), 'constructor';

    isa_ok $dst, 'App::PlannedCopy::Resource::Element::Destination';

    is $dst->_name, 'filename1', 'destination name';
    is $dst->_name_bak, 'filename1.bak', 'destination bakup name';
    is $dst->_path, $dest_path, 'destination path';
    is $dst->_perm, '0644', 'destination perm';
    is $dst->_full_path, path( $dest_path, qw(filename1) ),
        'destination path';
    is $dst->_full_path_bak, path( $dest_path, qw(filename1.bak) ),
        'destination backup path';
    is $dst->_abs_path, path( $dest_path, qw(filename1) )->absolute,
        'destination absolute path';
    is $dst->_abs_path_bak, path( $dest_path, qw(filename1.bak) )->absolute,
        'destination backup absolute path';
    is $dst->_parent_dir, $dest_path->absolute,
        'destination absolute path parent';
};

subtest 'maximum valid config' => sub {
    my $args = {
        destination => {
            name => 'filename3',
            path => 't/test-dst/check',
            perm => '0644',
            verb => 'unpack',
            user => 'someuser',
        },
    };

    ok my $dst = App::PlannedCopy::Resource::Element::Destination->new(
        $args->{destination} ), 'constructor';

    isa_ok $dst, 'App::PlannedCopy::Resource::Element::Destination';

    is $dst->_name, 'filename3', 'destination name';
    is $dst->_name_bak, 'filename3.bak', 'destination bakup name';
    is $dst->_path, $dest_path,  'destination path';
    is $dst->_perm, '0644',      'destination perm';
    is $dst->_verb, 'unpack',    'destination verb';
    is $dst->_user, 'someuser',  'destination user';
    is $dst->_abs_path, path( $dest_path, qw(filename3) )->absolute,
        'destination absolute path';
    is $dst->_abs_path_bak, path( $dest_path, qw(filename3.bak) )->absolute,
        'destination backup absolute path';
    is $dst->_parent_dir, $dest_path->absolute,
        'destination absolute path parent';
};

done_testing;
