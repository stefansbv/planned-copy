package App::PlannedCopy::Role::Resource::Utils;

# ABSTRACT: Utils

use 5.010001;
use utf8;
use Moose::Role;
use Try::Tiny;
use Path::Tiny;
use Path::Iterator::Rule;
use List::Compare;
use Moose::Util::TypeConstraints;

use constant RESOURCE_FILE => 'resource.yml';

use App::PlannedCopy::Resource::Read;
use App::PlannedCopy::Resource::Write;

has 'destination_path' => (
    is  => 'rw',
    isa => 'Maybe[Str]',
);

has 'resource_old' => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => ['Hash'],
    lazy    => 1,
    builder => '_build_old_resource',
    handles => {
        get_old_res    => 'get',
        has_no_old_res => 'is_empty',
        old_res_keys   => 'keys',
        old_res_pairs  => 'kv',
    },
);

has 'resource_new' => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => ['Hash'],
    lazy    => 1,
    builder => '_build_new_resource',
    handles => {
        get_fs_res    => 'get',
        has_no_fs_res => 'is_empty',
        fs_res_keys   => 'keys',
    },
);

has '_compare' => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => ['Hash'],
    lazy    => 1,
    builder => '_build_compare',
    handles => {
        get_compare => 'get',
    },
);

has '_kept' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    traits  => ['Array'],
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->get_compare('upd');
    },
    handles => {
        get_kept   => 'elements',
        count_kept => 'count',
    },
);

has '_removed' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    traits  => ['Array'],
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->get_compare('del');
    },
    handles => {
        get_removed   => 'elements',
        count_removed => 'count',
    },
);

has '_added' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    traits  => ['Array'],
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->get_compare('add');
    },
    handles => {
        get_added   => 'elements',
        count_added => 'count',
    },
);

sub _build_old_resource {
    my $self = shift;
    my %items;
    if ( $self->is_project ) {
        my $reader = App::PlannedCopy::Resource::Read->new(
            resource_file => $self->resource_file );
        foreach my $res ( @{ $reader->get_contents('resources') } ) {
            my $name = path( $res->{source}{path}, $res->{source}{name} )->stringify;
            $items{$name} = $res;
        }
    }
    return \%items;
}

sub _build_new_resource {
    my $self = shift;
    my @items;
    try {
        @items = @{ $self->get_all_files( $self->project ) };
    }
    catch {
        if ( my $e = Exception::Base->catch($_) ) {
            if ( $e->isa('Exception::IO::PathNotFound') ) {
                $self->print_exeception_message($e->message, $e->pathname);
                exit;                        # ???
            }
            else {
                die "Unexpected exception: $_";
            }
        }
    };
    return {} unless scalar @items;
    my %items;
    foreach my $rec (@items) {
        my $file = $rec->{name};
        my $path = $rec->{path};
        my $subd = path($path)->relative($self->project);
        my $name = path( $path, $file )->stringify;
        my $dest = $self->destination_path
                 ? path($self->destination_path, $subd)->stringify
                 : undef;
        $items{$name} = {
            source => {
                name => $file,
                path => $path,
            },
            destination => {
                name => $file,
                path => $dest,
                perm => '0644',
            }
        };
    }
    return \%items;
}

sub _build_compare {
    my $self = shift;
    my @old = $self->old_res_keys;
    my @fs  = $self->fs_res_keys;
    my $dc  = List::Compare->new( \@old, \@fs );
    my @upd = $dc->get_intersection;
    my @del = $dc->get_unique;
    my @add = $dc->get_complement;
    my %comp;
    $comp{upd} = \@upd;
    $comp{del} = \@del;
    $comp{add} = \@add;
    return \%comp;
}

sub write_resource {
    my ($self, $data) = @_;
    my $rw = App::PlannedCopy::Resource::Write->new(
        resource_file => $self->resource_file );
    try   { $rw->create_yaml( { resources => $data } ) }
    catch {
        if ( my $e = Exception::Base->catch($_) ) {
            if ( $e->isa('Exception::IO') ) {
                die "[EE] ", $e->message, ' (', $e->pathname, ').';
            }
            elsif ( $e->isa('Exception::Config::YAML') ) {
                die "[EE] ", $e->message, ' ', $e->logmsg;
            }
            else {
                die "[EE] Unknown exception: $_";
            }
        }
    };
    return;
}

sub get_all_files {
    my ($self, $dir) = @_;

    die "The 'dir' parameter is required for 'get_all_files'\n" unless $dir;

    my $proj = $self->find_project( sub { $_->{path} eq $dir } );
    unless ($proj) {
        Exception::IO::PathNotFound->throw(
            message  => 'The project was not found:',
            pathname => $dir,
        );
    }

    my $abs_dir = path( $self->config->repo_path, $dir );
    my $rule    = Path::Iterator::Rule->new;
    $rule->skip(
        $rule->new->file->empty,
        $rule->new->file->name(RESOURCE_FILE),
    );
    my $next = $rule->iter( $abs_dir,
        { relative => 0, sorted => 1, follow_symlinks => 0 } );
    my @files;
    while ( defined( my $item = $next->() ) ) {
        my $item = path $item;
        next if $item->is_dir;
        my $name = $item->basename;
        my $path = $item->parent->relative( $abs_dir->parent )->stringify;
        push @files, { name => $name, path => $path };
    }
    return \@files;
}

sub update_resource {
    my $self = shift;

    my @del = $self->get_removed;
    my @upd = $self->get_kept;
    my @add = $self->get_added;

    unless ( $self->dryrun ) {
        my @res_data;
        foreach my $name (@upd) {
            my $data = $self->get_old_res($name);
            push @res_data, $data;
        }
        foreach my $name (@add) {
            my $data = $self->get_fs_res($name);
            push @res_data, $data;
        }
        $self->write_resource( \@res_data );
    }

    $self->project_changes_list_printer( 'removed', @del );
    $self->project_changes_list_printer( 'kept',    @upd );
    $self->project_changes_list_printer( 'added',   @add );

    return;
}

no Moose::Role;

1;

__END__

=encoding utf8

=head1 Description

Helper role the C<resu> command.  TODO: change the name.

=head1 Interface

=head2 Constants

=head2 RESOURCE_FILE

Returns the name of the resource file.

=head2 Attributes

=head3 resource_old

Holds a hash reference with the contents of the resource file.

=head3 resource_new

Holds a hash reference with a new resource data structure with all the
files from the project dir.

=head3 _compare

Build a data structure that contains the list of added, updated and
deleted resource items.

=head3 _kept

Returns an array reference of updated items.

=head3 _removed

Returns an array reference of deleted items.

=head3 _added

Returns an array reference of added items.

=head2 Instance Methods

=head3 write_resource

Write the resource file into the project dir using the
L<App::PlannedCopy::Resource::Write> module.

=head3 get_all_files

Recursively scan the project dir and get a list of the files,
excepting the C<resource.yml> file if it exists and return the data as
an array reference.

=head3 update_resource

Collect info about kept, added and removed files and create a new
resource file.  Print a summary of the operations performed.

=cut
