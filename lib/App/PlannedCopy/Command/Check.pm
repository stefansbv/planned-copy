package App::PlannedCopy::Command::Check;

# ABSTRACT: Compare the repository files with the installed versions

use 5.010001;
use utf8;
use Try::Tiny;
use Term::ExtendedColor qw(fg);
use MooseX::App::Command;
use namespace::autoclean;

extends qw(App::PlannedCopy);

with qw(App::PlannedCopy::Role::Printable
        App::PlannedCopy::Role::Utils
        App::PlannedCopy::Role::Validate::Check
       );

use App::PlannedCopy::Resource;

command_long_description q[Compare the repository files with the installed versions for the selected <project>.];

parameter 'project' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 0,
    documentation => q[Project name.],
);

parameter 'dst_name' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 0,
    cmd_flag      => 'file',
    documentation => q[Optional destination file name.],
);

has '_differences' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    traits  => ['Array'],
    lazy    => 1,
    default => sub { [] },
    handles => {
        get_differences   => 'elements',
        count_differences => 'count',
    },
);

sub run {
    my ($self) = @_;
    if ( $self->project ) {
        $self->check_project;
    }
    else {
        print "Checking " unless $self->verbose;
        foreach my $item ( $self->projects ) {
            my $path = $item->{path};
            my $resu = $item->{resource};
            next unless $resu == 1;
            $self->project($path); # set project
            $self->check_project( 'batch' );
            print "." unless $self->verbose;
        }
        print " .\n" unless $self->verbose;
        $self->print_summary( 'batch' );
    }
    return;
}

sub check_project {
    my ( $self, $batch ) = @_;

    my $file = $self->config->resource_file( $self->project );
    my $resu = App::PlannedCopy::Resource->new( resource_file => $file );
    my $iter = $resu->resource_iter;
    my $cnt  = $resu->count;

    my $name = $self->dst_name;
    if ($name) {
        say "Job: 1 file to check:";
        $self->verbose(1);
    }
    else {
        if ( $self->verbose ) {
            say '[', fg('green1', $self->project), "], Job: ", $cnt, ' file',
                ( $cnt != 1 ? 's' : '' ),
                ' to check',
                ( $batch ? '...' : ':' );
        }
    }
    print "\n" unless $batch;

    $self->no_resource_message( $self->project )
        if $cnt == 0;

    $self->reset_count_diff;

    while ( $iter->has_next ) {
        my $res = $iter->next;
        if ($name) {

            # Skip until found; not efficient but simple to implement ;)
            next unless $res->dst->_name eq $name;
        }

        $self->prevalidate_element($res);

        if ( $res->has_no_issues ) {
            $self->item_printer($res) if $self->verbose and !$batch;
            $self->inc_count_same;
        }
        else {
            if ( $res->has_action('skip') ) {
                $self->item_printer($res) unless $batch;
                $self->inc_count_skip;
            }
            else {

                # print
                $self->item_printer($res) unless $batch;
                $self->inc_count_diff;
            }
        }
        $self->inc_count_proc;
    }

    if ($batch) {
        $self->store_summary( $self->project );
    }
    else {
        $self->print_summary;
    }

    return;
}

sub store_summary {
    my ( $self, $project ) = @_;
    push @{ $self->_differences }, [ $project, $self->count_diff ]
        if $self->count_diff > 0;
    return;
}

sub print_summary {
    my ( $self, $batch ) = @_;
    my $cnt_proc = $self->count_proc // 0;
    my $count_diff = $self->count_diff;
    if ($batch) {
        $count_diff = $self->count_differences;
        $count_diff .= ' projects';
        say '';
        $self->difference_printer( $self->get_differences );
    }
    say '';
    say 'Summary:';
    say ' - processed: ', $cnt_proc, ' records';
    say ' - skipped  : ', $self->count_skip;
    say ' - same     : ', $self->count_same;
    say ' - different: ', $count_diff;
    say '';

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Description

The implementation of the C<check> command.

=head1 Interface

=head2 Attributes

=head3 project

Required parameter attribute for the install command.  The name of the
project - a directory name under C<repo_path>.

=head3 _differences

Holds an array reference of the items with different source and
destination files.

=head2 Instance Methods

=head3 run

The method to be called when the C<check> command is run.

Builds an iterator for the resource items and iterates over them.  If
the C<validate_element> method throws an exception, it is cached and
the item is skipped.  If there is no fatal exception thrown, then the
C<check> method is called on the item.

=head3 check

Check the source and destination files for differences.

TODO: Revise the counters.

=head3 check_project

Builds an iterator for the resource items and iterates over them.  If
the C<validate_element> method throws an exception, it is cached and
the item is skipped.  If there is no fatal exception thrown, then the
C<check> method is called on the item.

=head3 print_summary

Prints the summary of the command execution.  If in batch mode, prints
all project items with differences.

=head3 store_summary

=cut
