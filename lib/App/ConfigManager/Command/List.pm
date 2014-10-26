package App::ConfigManager::Command::List;

# ABSTRACT: Print a list of the projects in the repository

use 5.010001;
use utf8;
use Path::Tiny;
use Path::Iterator::Rule;
use MooseX::App::Command;
use namespace::autoclean;

extends qw(App::ConfigManager);

with qw(App::ConfigManager::Role::Utils);

sub execute {
    my ( $self ) = @_;

    say "Projects:";
    foreach my $file ( @{ $self->get_projects } ) {
        say " > ", $file->basename;
    }

    return;
}

sub get_projects {
    my $self = shift;

    die "EE Not configured!\n" unless defined $self->config->repo_path;

    my $rule = Path::Iterator::Rule->new;
    $rule->skip_vcs;
    $rule->file->name( 'resource.yml' );

    my $next = $rule->iter( $self->config->repo_path );
    my @dirs;
    while ( defined( my $file = $next->() ) ) {
        push @dirs, path($file)->parent;
    }
    return \@dirs;
}

__PACKAGE__->meta->make_immutable;

1;

=head2 get_projects

Returns an array reference of the names of the subdirectories of
L<repo_path> that contains a resource file (L<resource.yml>).

=cut
