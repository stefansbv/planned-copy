package App::PlannedCopy::Role::Utils;

# ABSTRACT: Role for utility functions

use 5.0100;
use utf8;
use Moose::Role;
use Path::Tiny;
use Path::Iterator::Rule;
use Try::Tiny;
use Capture::Tiny ':all';

use App::PlannedCopy::Exceptions;

sub is_selfsame {
    my ( $self, $src, $dst ) = @_;

    if ( $dst =~ m{undef}i ) {
        Exception::IO::PathNotDefined->throw(
            message  => 'The destination path is not defined.',
            pathname => '',
        );
    }
    if ( !$dst->is_file ) {
        return 0;
    }
    my $digest_src;
    try   { $digest_src = $src->digest('MD5') }
    catch {
        my $err = $_;
        if ( $err =~ m{permission}i ) {
            Exception::IO::PermissionDenied->throw(
                message  => 'Permision denied for src path:',
                pathname => $src,
            );
        }
        else { die "Unknown error: $err" }
    };
    my $digest_dst;
    try   { $digest_dst = $dst->digest('MD5') }
    catch {
        my $err = $_;
        if ( $err =~ m{permission}i ) {
            Exception::IO::PermissionDenied->throw(
                message  => 'Permision denied for dst path:',
                pathname => $src,
            );
        }
        else { die "Unknown error: $err" }
    };
    return ( $digest_src eq $digest_dst ) ? 1 : 0;
}

sub copy_file {
    my ($self, $src, $dst) = @_;
    try   { $src->copy($dst) }
    catch {
        Exception::IO::SystemCmd->throw(
            usermsg => 'The copy command failed.',
            logmsg  => $_,
        );
    };
    return;
}

sub set_perm {
    my ($self, $file, $perm) = @_;
    die "The 'set_perm' method works only with files.\n" unless $file->is_file;
    try   { $file->chmod($perm) }
    catch {
        Exception::IO::SystemCmd->throw(
            usermsg => 'The perm command failed.',
            logmsg  => $_,
        );
    };
    return;
}

sub change_owner {
    my ( $self, $file, $user ) = @_;
    die "The 'change_owner' method works only with files.\n"
        unless $file->is_file;
    my ( $login, $pass, $uid, $gid ) = getpwnam($user)
        or die "$user not in passwd file";
    try   { chown $uid, $gid, $file->stringify }
    catch {
        Exception::IO::SystemCmd->throw(
            usermsg => 'The chown command failed.',
            logmsg  => $_,
        );
    };
    return;
}

sub handle_exception {
    my ($self, $ex) = @_;
    if ( my $e = Exception::Base->catch($ex) ) {
        if ( $e->isa('Exception::IO::PathNotFound') ) {
            $self->set_error_level('reset');
        }
        elsif ( $e->isa('Exception::IO::PathNotDefined') ) {
            $self->set_error_level('info');
        }
        elsif ( $e->isa('Exception::IO::FileNotFound') ) {
            $self->set_error_level('info');
        }
        elsif ( $e->isa('Exception::IO::PermissionDenied') ) {
            $self->set_error_level('info');
        }
        else {
            $self->set_error_level('error');
        }
        return $e;
    }
    else {
        say "Unhandled exception:", $ex;
    }
    return;
}

sub no_resource_message {
    my ($self, $proj) = @_;
    say "---";
    say "There is no resource file for the '$proj' project.\nRun the 'resu' command to create it.";
    say "---";
    return
}

sub quote_string {
    my $str = shift;
    return unless $str;
    $str    = qq{$str} if $str =~ m{\s};
    return $str;
}

sub kompare {
    my ($self, $src_path, $dst_path) = @_;
    my $cmd = $self->diff_cmd;
    my @args;
    push @args, quote_string($src_path);
    push @args, quote_string($dst_path);
    say "# $cmd @args" if $self->verbose;
    my ( $stdout, $stderr, $exit ) = capture { system( $cmd, @args ) };
    if ($stderr) {
        Exception::IO::SystemCmd->throw(
            usermsg => 'The diff command failed.',
            logmsg  => $stderr,
        );
    }
    say $stdout if $stdout;
    return;
}

sub get_project_files {
    my ( $self, $project ) = @_;

    die "EE Project name was not provided for 'get_project_files'!\n"
        unless $project;

    my $proj = $self->find_project( sub { $_->{path} eq $project } );
    unless ($proj) {
        Exception::IO::PathNotFound->throw(
            message  => 'The project was not found:',
            pathname => $project,
        );
    }

    my $path = path( $self->config->repo_path, $project );
    my $rule = Path::Iterator::Rule->new;
    $rule->skip_vcs;
    $rule->skip(
        $rule->new->file->empty,
        $rule->new->file->name('resource.yml'),
    );
    $rule->min_depth(1);

    my $next = $rule->iter( $path,
        { relative => 0, sorted => 1, follow_symlinks => 0 } );
    my $dirs = [];
    while ( defined( my $item = $next->() ) ) {
        my $path = path($item);
        push @{$dirs}, $path->basename,
    }
    return $dirs;
}

sub check_res_user {
    my ( $self, $res ) = @_;
    if ( $self->config->current_user ne $res->dst->_user ) {
        Exception::IO::WrongUser->throw(
            message  => "Skipping, you're not",
            username => $res->dst->_user,
        );
    }
    return 1;
}

sub check_user {
    my $self = shift;
    return 1 if $self->repo_owner eq 'plcp-test-user'; # Ugly workaround for tests :(
    if ( $self->config->current_user ne $self->repo_owner ) {
        Exception::IO::WrongUser->throw(
            message  => "Skipping, you're not the repo ownwer ",
            username => $self->repo_owner,
        );
    }
    return 1;
}

no Moose::Role;

1;

__END__

=encoding utf8

=head1 Synopsis

=head1 Description

=head1 Interface

=head2 change_owner

=head2 check_res_user

=head2 check_user

=head2 copy_file

=head2 get_project_files

=head2 handle_exception

=head2 is_selfsame

=head2 kompare

=head2 no_resource_message

=head2 quote_string

=head2 set_perm

=cut

TODO: POD
