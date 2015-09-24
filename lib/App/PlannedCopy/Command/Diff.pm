package App::PlannedCopy::Command::Diff;

# ABSTRACT: Run a diff utility on the repo files and the installed versions

use 5.010001;
use utf8;
use Try::Tiny;
use IO::Prompt::Tiny qw/prompt/;
use Capture::Tiny ':all';
use MooseX::App::Command;
use namespace::autoclean;

extends qw(App::PlannedCopy);

with qw(App::PlannedCopy::Role::Printable
        App::PlannedCopy::Role::Utils);

use App::PlannedCopy::Resource;

command_long_description q[Run a diff utility.  Defaults to kompare];

parameter 'project' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    documentation => q[Project name.],
);

has 'diff_cmd' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        my $self = shift;
        my $cmd  = $self->config->diff_tool;
        my ( $stdout, $stderr, $exit ) = capture { system( $cmd, '--version' ) };
        die "Can't execute '$cmd'!\n Error: $stderr"     if $stderr;
        die "Can't execute '$cmd'! Error: exitval=$exit" if $exit != 0;
        return $cmd;
    },
);

sub execute {
    my ($self) = @_;

    my $file = $self->config->resource_file( $self->project );
    my $res  = App::PlannedCopy::Resource->new( resource_file => $file );
    my $iter = $res->resource_iter;

    say 'Job: ', $res->count, ' file', ( $res->count != 1 ? 's' : '' ),
        ' to diff', ( $self->verbose ? ' (verbose)' : '' ), ':', "\n";

    $self->no_resource_message( $self->project ) if $res->count == 0;

    while ( $iter->has_next ) {
        $self->set_error_level('info');
        my $rec = $iter->next;
        my $cont = try { $self->validate_element($rec) }
        catch {
            my $e = $self->handle_exception($_);
            $self->item_printer($rec);
            $self->exception_printer($e) if $e;
            $self->inc_count_skip;
            return undef;    # required
        };
        if ($cont) {
            try {
                $self->diff($rec);
                $self->item_printer($rec);
            }
            catch {
                my $e = $self->handle_exception($_);
                $self->exception_printer($e) if $e;
                $self->inc_count_skip;
            };
        }
        $self->inc_count_proc;
    }

    $self->print_summary;

    return;
}

sub diff {
    my ( $self, $rec ) = @_;

    # Skip archives
    if ( $rec->src->type_is('archive') ) {
        return;
    }

    my $src_path = $rec->src->_abs_path;
    my $dst_path = $rec->dst->_abs_path;
    if ( $self->is_selfsame( $src_path, $dst_path ) ) {
        $self->set_error_level('info');
    }
    else {
        $self->set_error_level('warn');
        say "# ", $self->diff_cmd, " $src_path $dst_path";
        my $answer = prompt( "Runn diff? (y/N)", "n" );
        if ( $answer =~ m{[yY]} ) {
            $self->kompare( $src_path, $dst_path );
            $self->inc_count_resu;
        }
    }
    $self->inc_count_inst;
    return;
}

sub print_summary {
    my $self = shift;
    my $cnt_proc = $self->count_proc // 0;
    say '';
    say 'Summary:';
    say ' - processed: ', $cnt_proc, ' records';
    say ' - checked  : ', $self->count_inst;
    say ' - skipped  : ', $self->count_skip;
    say ' - diff-ed  : ', $self->count_resu;
    say '';
    return;
}

__PACKAGE__->meta->make_immutable;

1;
