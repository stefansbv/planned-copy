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
    try {
        $digest_src = $src->digest('MD5');
    }
    catch {
        my $err = $_;
        if ( $err =~ m{permission}i ) {
            Exception::IO::PermissionDenied->throw(
                message  => 'Permision denied for source path:',
                pathname => $src,
            );
        }
        else {
           die "Unknown error: $err";
        }
    };
    my $digest_dst;
    try {
        $digest_dst = $dst->digest('MD5');
    }
    catch {
        my $err = $_;
        if ( $err =~ m{permission}i ) {
            Exception::IO::PermissionDenied->throw(
                message  => 'Permision denied for destination path:',
                pathname => $src,
            );
        }
        else {
           die "Unknown error: $err";
        }
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

sub validate_element {
    my ($self, $res) = @_;

    # Check the source file
    my $src_path = $res->src->_abs_path;
    unless ( $src_path->is_file ) {
        Exception::IO::FileNotFound->throw(
            message  => 'The source file was not found.',
            pathname => $res->src->short_path,
        );
    }

    # Check the destination file.
    if ( $res->dst->_path =~ m/^{\s?undef\s?}/ ) {
        Exception::IO::PathNotDefined->throw(
            message  => 'The destination path is not defined.',
            pathname => '',
        );
    }

    return 1;
}

sub handle_exception {
    my ($self, $ex) = @_;

    if ( my $e = Exception::Base->catch($ex) ) {
        $e->isa('Exception::IO::PathNotFound')
            ? $self->set_error_level('reset')
            : $self->set_error_level('error');
        return $e;
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

sub get_projects {
    my $self = shift;

    die "EE Not configured!\n" unless defined $self->config->repo_path;

    my $rule = Path::Iterator::Rule->new;
    $rule->skip_vcs;
    $rule->min_depth(1);
    $rule->max_depth(1);

    my $next = $rule->iter( $self->config->repo_path );
    my @dirs;
    while ( defined( my $item = $next->() ) ) {
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

sub get_files {
    my ( $self, $project ) = @_;

    die "EE Project name not provided!\n" unless $project;

    my $path = path( $self->config->repo_path, $project );
    unless ( $path->is_dir ) {
        Exception::IO::PathNotFound->throw(
            message  => 'The project path was not found.',
            pathname => $path,
        );
    }
    my $rule = Path::Iterator::Rule->new;
    $rule->skip_vcs;
    $rule->min_depth(1);

    my $next = $rule->iter($path);
    my $dirs_aref = [];
    while ( defined( my $item = $next->() ) ) {
        my $path = path($item);
        if ( !$path->is_dir ) {
            $self->inc_count_inst;
            $self->inc_count_proc;
            push @{$dirs_aref}, { path => $path->basename };
        }
    }
    return $dirs_aref;
}

no Moose::Role;

1;
