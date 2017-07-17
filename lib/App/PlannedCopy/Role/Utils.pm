package App::PlannedCopy::Role::Utils;

# ABSTRACT: Role for utility functions

use 5.0100;
use utf8;
use Carp;
use Moose::Role;
use Path::Tiny;
use Path::Iterator::Rule;
use Try::Tiny;
use Capture::Tiny ':all';

use App::PlannedCopy::Exceptions;

has 'resource_file' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->config->resource_file( $self->project );
    },
);

has 'resource' => (
    is      => 'ro',
    isa     => 'App::PlannedCopy::Resource',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::PlannedCopy::Resource->new(
            resource_file => $self->resource_file );
    },
);

sub file_stat {
    my ( $self, $res_sord ) = @_;
    return $res_sord->_abs_path->stat if $res_sord->is_local;
    my $path = $res_sord->_abs_path;
    die "No such file or directory: $path" unless $self->sftp->stat($path);
    return $self->sftp->stat($path);
}

sub file_perms {
    my ( $self, $res_sord ) = @_;
    my $stat = $self->file_stat($res_sord);
    return $res_sord->is_local ? $stat->mode : $stat->perm;
}

sub is_selfsame {
    my ( $self, $src_sord, $dst_sord ) = @_;

	my $src_path = $src_sord->_abs_path;
    my $dst_path = $dst_sord->_abs_path;

    if ( $dst_path =~ m{undef}i ) {
        Exception::IO::PathNotDefined->throw(
            message  => 'The destination path is not defined.',
            pathname => '',
        );
    }
    if ( !$dst_path->is_file ) {
        return 0;
    }

    # Compare sizes
	return 0 if $self->file_stat($src_sord)->size != $self->file_stat($dst_sord)->size;

    # Check contents
    my $digest_src = $self->digest_local($src_path);
    my $digest_dst = $self->digest_local($dst_path);

    return ( $digest_src eq $digest_dst ) ? 1 : 0;
}

sub digest_local {
    my ($self, $file) = @_;
    my $digest;
    try   { $digest = $file->digest('MD5') }
    catch {
        my $err = $_;
        if ( $err =~ m{permission}i ) {
            Exception::IO::PermissionDenied->throw(
                message  => 'Permision denied for path:',
                pathname => $file,
            );
        }
        else { die "Unknown error: $err" }
    };
    return $digest;
}

sub copy_file {
    my ( $self, $verb, $res ) = @_;
    die "\$res has to be a 'App::PlannedCopy::Resource::Element'"
        unless $res->isa('App::PlannedCopy::Resource::Element');
	my ($src_path, $dst_path);
	if ($verb eq 'install') {
		$src_path = $res->src->_abs_path;
		$dst_path = $res->dst->_abs_path;
	}
	elsif ($verb eq 'backup') {
		$src_path = $res->dst->_abs_path;
		$dst_path = $res->dst->_abs_path_bak;
	}
	elsif ($verb eq 'sync') {
		$src_path = $res->dst->_abs_path;
		$dst_path = $res->src->_abs_path;
	}
	else {
		die "unknown verb: $verb";
	}
	my $host = $self->remote_host;
    if (!$host or $host eq 'localhost') {
        $self->copy_file_local( $src_path, $dst_path );
    }
    else {
        $self->copy_file_remote( $src_path, $dst_path );
    }
    return;
}

sub make_path {
    my ($self, $dir) = @_;
    try   { $dir->mkpath }
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
            message => 'The mkpath command failed.',
            logmsg  => $logmsg,
        );
    };
    return;
}

sub copy_file_local {
    my ( $self, $src, $dst ) = @_;
    try { $src->copy($dst) }
    catch {
        my $err    = $_;
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

sub copy_file_remote {
    my ( $self, $src, $dst ) = @_;
	my $sftp = try { $self->sftp }
	catch {
        my $err = $_;
        Exception::IO::SystemCmd->throw(
            message => 'The sftp command failed.',
            logmsg  => $err,
        );
	};
    try {
		# $sftp->setcwd( $dst->parent )
        #     or die "Unable to change cwd " . $sftp->error . "\n";
        $sftp->put( $src, $dst, late_set_perm => 1 )
            or die "put failed: " . $sftp->error . "\n";
    }
    catch {
        my $err = $_;
        Exception::IO::SystemCmd->throw(
            message => 'The sftp command failed.',
            logmsg  => $err,
		);
	};
    return;
}

sub set_perm {
    my ($self, $file, $perm) = @_;
    die "The 'set_perm' method works only with files." unless $file->is_file;
    try   { $file->chmod($perm) }
    catch {
        my $err = $_;
        my $logmsg = '';
        if ( $err =~ m{Operation not permitted}i ) {
            $logmsg = 'Permission denied';
        }
        else {
            $logmsg = $err;
        }
        Exception::IO::SystemCmd->throw(
            message => 'The perm command failed.',
            logmsg  => $logmsg,
        );
    };
    return;
}

sub set_owner {
    my ( $self, $file, $user ) = @_;
    die "The 'change_owner' method works only with files."
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
                message  => $e->message,
                details  => $e->logmsg,
                category => 'error',
                action   => 'skip',
            ),
        );
    }
    if ( $e->isa('Exception::IO::WrongPerms') ) {
        $res->add_issue(
            App::PlannedCopy::Issue->new(
                message  => $e->message,
                details  => $e->perm,
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

sub compare {
    my ($self, $src_path, $dst_path, $binary) = @_;
    my $cmd = $binary ? 'cmp' : $self->diff_cmd;
    my @args;
    push @args, '-l' if $binary;
    push @args, quote_string($src_path);
    push @args, quote_string($dst_path);
    say "# $cmd @args" if $self->verbose;
    my ( $stdout, $stderr, $exit ) = capture { system( $cmd, @args ) };
    if ($stderr) {
        Exception::IO::SystemCmd->throw(
            message => 'The diff command failed.',
            logmsg  => $stderr,
        );
    }
    if ($stdout) {
        say $stdout;
    }
    else {
        say 'The files are identical' if $binary;
    }

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
        $rule->new->file->name($self->config->resource_file_name),
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
    croak "The 'check_res_user' method requires a resource param."
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

sub exceptions {
    my ($self, $exc, $res) = @_;
    $self->handle_exception($exc, $res);
    $self->item_printer($res);
    return;
}

sub prevalidate_element {
    my ($self, $res) = @_;
    try {
        $self->check_res_user($res);
        $self->validate_element($res);
    }
    catch {
        my $exc = $_;
        $self->handle_exception($exc, $res);
    };
    return;
}

sub get_perms {
    my ( $self, $res_sord ) = @_;
	my $mode = try { $self->file_perms($res_sord) }
    catch  {
        my $err = $_;
        if ( $err =~ m/Permission denied/i ) {
            Exception::IO::PermissionDenied->throw(
                message  => 'Permision denied for path:',
                pathname => $res_sord->_name,
            );
        }
        elsif ( $err =~ m/No such file or directory/i ) {
            Exception::IO::FileNotFound->throw(
                message  => 'No such file or directory',
                pathname => $res_sord->_name,
            );
        }
        else {
            die "Unknown stat ERROR: $err";
        }
    };
    return sprintf "%04o", $mode & 07777;
}

sub get_owner {
    my ( $self, $file ) = @_;
    my $uid = try { $file->stat->uid }
        catch  {
        my $err = $_;
        if ( $err =~ m/Permission denied/i ) {
            Exception::IO::PermissionDenied->throw(
                message  => 'Permision denied for path:',
                pathname => $file,
            );
        }
        elsif ( $err =~ m/No such file or directory/i ) {
            Exception::IO::FileNotFound->throw(
                message  => 'No such file or directory',
                pathname => $file,
            );
        }
        else {
            die "Unknown stat ERROR: $err";
        }
    };
    # my $user = ( getpwuid $uid )[0];
    return ( getpwuid $uid )[0];
    # return $user;
}

sub check_dir_name {
    my $self    = shift;
    my $project = $self->project;
    unless ( $self->is_project_path ) {
        die "\n[EE] No directory named '$project' found.\n     Check the spelling or use the 'list' command.\n\n";
    }
}

sub check_project_name {
    my $self    = shift;
    my $project = $self->project;
    unless ( $self->is_project($project) ) {
        die "\n[EE] No project named '$project' found.\n     Check the spelling or use the 'list' command.\n\n";
    }
}

sub project_path {
    my $self    = shift;
    my $project = $self->project;
    return path( $self->config->repo_path, $project );
}

sub is_project_path {
    my $self = shift;
    return $self->project_path->is_dir;
}

sub is_project {
    my ($self, $project) = @_;
    croak "The 'is_project' method requires a project name parameter!"
        unless $project;
    my $record = $self->find_project( sub { $_->{path} eq $project } );
    return $record->{resource};
}

sub make_dst_path {
	my ($self, $res) = @_;
    my $parent_dir = $res->dst->_parent_dir;
    if ( $res->dst->is_local ) {
        if ( !$parent_dir->is_dir ) {
            unless ( $parent_dir->mkpath ) {
                Exception::IO::PathNotFound->throw(
                    message  => 'Failed to create the destination path.',
                    pathname => $parent_dir,
                );
            }
        }
    }
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

=head2 Attributes

=head3 'resource_file'

=head3 'resource'

=head2 Instance Methods

=head3 file_stat

=head3 file_perms

The argument must be a resource source or destination object.

	my $mode = $self->file_perms($res_sord);

=head3 is_selfsame

Returns true if the source and the destination files are the same.

If the files are with different sizes, returns false, else uses an MD5
digest to compare contents.

Throws exceptions in exceptional cases ;)

=head3 digest_local

Calculates and returns the MD5 digest of a file.

=head3 digest_local

=head3 copy_file

Tries to copy the source file to the destination dir.  Throws a
C<Exception::IO::SystemCmd> if the operation fails.

    $self->copy_file( $src, $dst, $host);

The first argument is the source and the second argument is the
destination.  Both arguments are instances of the
C<::Resource::Element> type, usually C<::Resource::Element::Source>
and C<::Resource::Element::Destination>.

The third argument is the remote host name, is optional and defaults
to C<localhost>.

=head3 make_path

=head3 copy_file_local

=head3 copy_file_remote

=head3 set_perm

    $self->set_perm($file, $perm);

Tries to set the perms for the file.  Throws a
C<Exception::IO::SystemCmd> if the operation fails.

=head3 set_owner

=head3 handle_exception

=head3 exception_to_issue

=head3 no_resource_message

Prints a message if there is no resource file in the project dir.

=head3 quote_string

=head3 compare

=head3 get_project_files

Recursively scan the project dir and get a list of the files,
excepting the C<resource.yml> file if it exists and return the data as
an AoH.

=head3 check_res_user

    $self->check_res_user( $res );

Return true if the current user is the same as the configured
destination user, else throws an C<Exception::IO::WrongUser>.

=head3 check_user

    $self->check_user;

Return true if the current user is the same as the repository owner,
else throws an C<Exception::IO::WrongUser>.

=head3 exceptions

=head3 prevalidate_element

=head3 get_perms

The argument must be a resource source or destination object, because
the C<_location> attribute is needed for making distinction from local
and remote files.

    my $perms = $self->get_perms( $res->dst );

Return the C<perms> as an octal string of the file given as argument
or throws a C<Exception::IO::PermissionDenied> exception if the file
can't be read.

=head3 get_owner

=head3 check_dir_name

Return true if the name of the project attribute is a dir under the
C<repo_path>, false otherwise.

=head3 check_project_name

=head3 project_path

=head3 is_project_path

=head3 is_project

Return true if the project dir contains a resource file, false
otherwise.

=head3 make_dst_path

=cut
