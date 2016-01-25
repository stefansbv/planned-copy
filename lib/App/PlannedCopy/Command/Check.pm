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
        get_diff   => 'elements',
        count_diff => 'count',
    },
);

sub execute {
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
        print "\n" unless $self->verbose;
        $self->set_error_level('warn');
        $self->print_summary;
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
        say " ", fg('green1', $self->project), ", job: ", $cnt, ' file',
            ( $cnt != 1 ? 's' : '' ),
            ' to check', ( $self->verbose ? ' (verbose)' : '' ),
            ( $batch ? '...' : ':' ),
            ( $batch ? '' : "\n" );
    }

    $self->no_resource_message( $self->project )
        if $cnt == 0;

    $self->reset_count_resu;

    while ( $iter->has_next ) {
        $self->set_error_level('info');
        my $res = $iter->next;
        my $cont = try { $self->validate_element($res) }
        catch {
            my $e = $self->handle_exception($_);
            $self->item_printer($res) unless $batch;
            $self->exception_printer($e) if $e and not $batch;
            $self->inc_count_skip;
            return undef;    # required
        };
        if ($cont) {
            try {
                $self->check($res);
                $self->item_printer($res) unless $batch;
            }
            catch {
                my $e = $self->handle_exception($_);
                $self->exception_printer($e) if $e and not $batch;
                $self->inc_count_skip;
            };
        }
        $self->inc_count_proc;
    }

    if ($batch) {
        $self->store_summary( $self->project );
    }
    else {
        $self->print_project_summary;
    }

    return;
}

sub check {
    my ( $self, $res ) = @_;

    my $src_path = $res->src->_abs_path;
    my $dst_path = $res->dst->_abs_path;
    if ( $self->is_selfsame( $src_path, $dst_path ) ) {
        $self->set_error_level('done');
    }
    else {
        $self->inc_count_resu;
        $self->set_error_level('warn');
    }
    $self->inc_count_inst;
    return;
}

sub store_summary {
    my ( $self, $project ) = @_;
    push @{ $self->_differences }, [ $project, $self->count_resu ]
        if $self->count_resu > 0;
    return;
}

sub print_project_summary {
    my $self = shift;
    my $cnt_proc = $self->count_proc // 0;
    say '';
    say 'Summary:';
    say ' - processed: ', $cnt_proc, ' records';
    say ' - checked  : ', $self->count_inst;
    say ' - skipped  : ', $self->count_skip;
    say ' - different: ', $self->count_resu;
    say '';
    return;
}

sub print_summary {
    my $self = shift;
    my $cnt_proc = $self->count_proc // 0;

    say '';
    $self->difference_printer( $self->get_diff );

    say '';
    say 'Summary:';
    say ' - processed: ', $cnt_proc, ' records';
    say ' - checked  : ', $self->count_inst;
    say ' - skipped  : ', $self->count_skip;
    say ' - different: ', $self->count_diff;
    say '';

    return;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 Synopsis

    use App::PlannedCopy;

    App::PlannedCopy->new_with_command->run;
