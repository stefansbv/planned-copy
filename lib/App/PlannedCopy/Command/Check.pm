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

    if ( $self->verbose ) {
        say ' ', fg('green1', $self->project), ", job: ", $cnt, ' file',
            ( $cnt != 1 ? 's' : '' ),
            ' to check', ( $self->verbose ? ' (verbose)' : '' ),
            ( $batch ? '...' : ':' ),
            ( $batch ? '' : "\n" );
    }
    print "\n" unless $batch;

    $self->no_resource_message( $self->project )
        if $cnt == 0;

    $self->reset_count_diff;

    while ( $iter->has_next ) {
        my $res = $iter->next;
        my $cont = try { $self->validate_element($res); 1; }
        catch {
            my $exc = $_;
            $self->handle_exception($exc, $res);
            $self->item_printer($res) unless $batch;
            $self->inc_count_skip;
            return undef;    # required
        };
        if ($cont) {
            $self->item_printer($res) unless $batch;
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

sub check_for_differences {
    my ( $self, $res ) = @_;
    my $src_path = $res->src->_abs_path;
    my $dst_path = $res->dst->_abs_path;
    unless ( $self->is_selfsame( $src_path, $dst_path ) ) {
        my $issue = App::PlannedCopy::Issue->new(
            message  => 'The source and destination are different',
            category => 'info',
        );
        $res->add_issue($issue);
        $self->inc_count_diff;
    }
    $self->inc_count_inst;
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
        say '';
        $self->difference_printer( $self->get_differences );
    }
    say '';
    say 'Summary:';
    say ' - processed: ', $cnt_proc, ' records';
    say ' - checked  : ', $self->count_inst;
    say ' - skipped  : ', $self->count_skip;
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
