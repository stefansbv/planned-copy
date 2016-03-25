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
        my $err = $_;
        my $logmsg = '';
        if ( $err =~ m{Permission denied}i ) {
            $logmsg = 'Permission denied';
        }
        else {
            $logmsg = $err;
        }
        Exception::IO::SystemCmd->throw(
            message => 'The copy command failed.',
            logmsg  => $logmsg,
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
            message => 'The perm command failed.',
            logmsg  => $_,
        );
    };
    return;
}

sub set_owner {
    my ( $self, $file, $user ) = @_;
    die "The 'change_owner' method works only with files.\n"
        unless $file->is_file;
    my ( $login, $pass, $uid, $gid ) = getpwnam($user)
        or die "$user not in passwd file";
    try   { chown $uid, $gid, $file->stringify }
    catch {
        Exception::IO::SystemCmd->throw(
            message => 'The chown command failed.',
            logmsg  => $_,
        );
    };
    return;
}

sub handle_exception {
    my ( $self, $exc, $res ) = @_;
    if ( my $e = Exception::Base->catch($exc) ) {
        if ( $e->isa('Exception::IO') ) {
            $self->exception_to_issue($e, $res);
        }
        else {
            die "[EE] Unhandled exception:", $exc;
        }
    }
    else {
        die "[EE] Unknown exception:", $exc;
    }
    return;
}

sub exception_to_issue {
    my ( $self, $e, $res ) = @_;
    if ( $e->isa('Exception::IO::SystemCmd') ) {
        $res->add_issue(
            App::PlannedCopy::Issue->new(
                message => $e->message,
                details => $e->logmsg,
                category => 'error',
                action   => 'skip',
            ),
        );
    }
    if ( $e->isa('Exception::IO::WrongPerms') ) {
        $res->add_issue(
            App::PlannedCopy::Issue->new(
                message => $e->message,
                details => $e->perm,
                category => 'info',
                action   => 'chmod',
            ),
        );
    }
    if ( $e->isa('Exception::IO::PathNotDefined') ) {
        $res->add_issue(
            App::PlannedCopy::Issue->new(
                message  => $e->message,
                category => 'warn',
                action   => 'skip',
            ),
        );
    }
    if ( $e->isa('Exception::IO::PermissionDenied') ) {
        $res->add_issue(
            App::PlannedCopy::Issue->new(
                message  => $e->message,
                details  => $e->pathname->stringify,
                category => 'warn',
                action   => 'skip',
            ),
        );
    }
    if ( $e->isa('Exception::IO::WrongUser') ) {
        $res->add_issue(
            App::PlannedCopy::Issue->new(
                message  => $e->message,
                details  => $e->username,
                category => 'warn',
                action   => 'skip',
            ),
        );
    }
    if ( $e->isa('Exception::IO::FileNotFound') ) {
        $res->add_issue(
            App::PlannedCopy::Issue->new(
                message  => $e->message,
                details  => $e->pathname->stringify,
                category => 'warn',
                action   => 'skip',
            ),
        );
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
    # say "# $cmd @args" if $self->verbose;
    my ( $stdout, $stderr, $exit ) = capture { system( $cmd, @args ) };
    if ($stderr) {
        Exception::IO::SystemCmd->throw(
            message => 'The diff command failed.',
            logmsg  => $stderr,
        );
    }
    say $stdout if $stdout;
    return;
}

sub get_project_files {
    my ( $self, $project ) = @_;

    die "Project name was not provided for 'get_project_files'!\n"
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
    die "The 'check_res_user' method requires a resource param.\n"
        unless ref $res;
    my $user = $self->config->current_user;
    if ( $user ne 'root' && $res->dst->_user_isnot_default ) {
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

A common role which encapsulates the attributes and methods required
by the command modules.

=head1 Interface

=head2 Instance Methods

=head3 change_owner

    $self->change_owner($file, $user);

Changes the owner of the file.

Throws an C<Exception::IO::SystemCmd> if the operation fails.

=head3 check_res_user

    $self->check_res_user( $res );

Return true if the current user is the same as the configured
destination user, else throws an C<Exception::IO::WrongUser>.

=head3 check_user

    $self->check_user;

Return true if the current user is the same as the repository owner,
else throws an C<Exception::IO::WrongUser>.

=head3 copy_file

Tries to copy the source file to the destination dir.  Throws a
C<Exception::IO::SystemCmd> if the operation fails.

=head3 get_project_files

Recursively scan the project dir and get a list of the files,
excepting the C<resource.yml> file if it exists and return the data as
an AoH.

=head3 handle_exception

TODO

=head3 is_selfsame

Uses an MD5 digest to compare the source and the destination file and
returns the result of the comparison.  Throws exceptions in
exceptional cases ;)

=head3 kompare

Runs the C<diff_tool>.

=head3 no_resource_message

Prints a message if there is no resource file in the project dir.

=head3 quote_string

=head3 set_perm

    $self->set_perm($file, $perm);

Tries to set the perms for the file.  Throws a
C<Exception::IO::SystemCmd> if the operation fails.

=cut
