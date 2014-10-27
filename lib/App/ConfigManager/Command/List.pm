package App::ConfigManager::Command::List;

# ABSTRACT: Print a list of the projects in the repository

use 5.010001;
use utf8;
use Path::Tiny;
use Path::Iterator::Rule;
use MooseX::App::Command;
use namespace::autoclean;

extends qw(App::ConfigManager);

with qw(App::ConfigManager::Role::Utils
        App::ConfigManager::Role::Printable);

sub execute {
    my ( $self ) = @_;

    say "Job: list projects:\n";
    $self->project_list_printer( @{ $self->get_projects } );

    $self->print_summary;

    return;
}

sub get_projects {
    my $self = shift;

    die "EE Not configured!\n" unless defined $self->config->repo_path;

    my $rule = Path::Iterator::Rule->new;
    $rule->skip_vcs;
    # $rule->file->name( 'resource.yml' );
    $rule->min_depth(1);
    $rule->max_depth(1);

    my $next = $rule->iter( $self->config->repo_path );
    my @dirs;
    while ( defined( my $item = $next->() ) ) {
        # push @dirs, path($file)->parent;
        my $path = path($item);
        if ( $path->is_dir ) {
            my $has_resu = path( $path, 'resource.yml')->is_file ? 1 : 0;
            $self->inc_count_inst if $has_resu;
            $self->inc_count_proc;
            push @dirs, { path => $path->basename, resource => $has_resu };
        }
    }
    return \@dirs;
}

sub print_summary {
    my $self = shift;
    say '';
    say 'Summary:';
    say ' - directories: ', $self->count_proc;
    say ' - projects   : ', $self->count_inst;
    say '';
    return;
}

__PACKAGE__->meta->make_immutable;

1;

=head2 get_projects

Returns an array reference of the names of the subdirectories of
L<repo_path> that contains a resource file (L<resource.yml>).

=cut
