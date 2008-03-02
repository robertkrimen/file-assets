package File::Assets::Asset;

use warnings;
use strict;

use File::Assets::Util;
use Carp::Clan qw/^File::Assets/;
use Object::Tiny qw/type rank attributes hidden rsc/;

=head1 SYNPOSIS 

    my $asset = File::Asset->new(base => $base, path => "/static/assets.css");
    $asset = $assets->include("/static/assets.css"); # Or, like this, usually.

    print "The rank for asset at ", $asset->uri, " is ", $asset->rank, "\n";
    print "The file for the asset is ", $asset->file, "\n";

=head1 DESCRIPTION

A File::Asset object represents an asset existing in both URI-space and file-space (on disk). The asset is usually a .js (JavaScript) or .css (CSS) file.

=head1 METHODS

=head2 File::Asset->new( base => <base>, path => <path>, [ rank => <rank>, type =>  <type> ]) 

Creates a new File::Asset. You probably don't want to use this, create a L<File::Assets> object and use $assets->include instead.

=cut

sub new {
    my $self = bless {}, shift;
    my $asset = @_ == 1 && ref $_[0] eq "HASH" ? shift : { @_ };

    my $content = delete $asset->{content};
    $content = ref $content eq "SCALAR" ? $$content : $content;
    $self->{content} = \$content;

    my ($path, $rsc, $base) = delete @$asset{qw/path rsc base/};
    my ($type) = delete @$asset{qw/type/};

    if (defined $type) {
        my $_type = $type;
        $type = File::Assets::Util->parse_type($_type) or croak "Don't understand type ($_type) for this asset";
    }

    my ($key, $inline);
    $inline = 0;

    if ($rsc) {
        croak "Don't have a type for this asset" unless $type;
        $self->{rsc} = $rsc;
        $self->{type} = $type;
    }
    elsif ($base && $path) {
        if ($path =~ m/^\//) {
            $self->{rsc} = $base->clone($path);
        }
        else {
            $self->{rsc} = $base->child($path);
        }
        $self->{type} = $type || File::Assets::Util->parse_type($path) or croak "Don't know type for asset ($path)";
    }
    elsif ($content) {
        $inline = 1;
        croak "Don't have a type for this asset" unless $type;
        $self->{type} = $type;
    }
    elsif (0 && $base && $content) { # Nonsense scenario?
        croak "Don't have a type for this asset" unless $type;
        my $path = File::Assets::Util->build_asset_path(undef, type => $type, content_digest => $self->content_digest);
        $self->{rsc} = $base->child($path);
        $self->{type} = $type;
    }

    my $rank = $self->{rank} = delete $asset->{rank} || 0;
    croak "Don't understand rank ($rank)" if $rank && $rank =~ m/[^\d\+\-\.]/;

    $self->{mtime} = delete $asset->{mtime} || 0;
    $self->{inline} = exists $asset->{inline} ? (delete $asset->{inline} ? 1 : 0) : $inline;

    $self->{attributes} = { %$asset }; # The rest goes here!

    return $self;
}

=head2 $asset->uri 

Returns a L<URI> object represting the uri for $asset

=cut

sub uri {
    my $self = shift;
    return unless $self->{rsc};
    return $self->rsc->uri;
}

=head2 $asset->file 

Returns a L<Path::Class::File> object represting the file for $asset

=cut

sub file {
    my $self = shift;
    return unless $self->{rsc};
    return $self->{file} ||= $self->rsc->file;
}

=head2 $asset->path 

Returns the path of $asset

=cut

sub path {
    my $self = shift;
    return unless $self->{rsc};
    return $self->rsc->path;
}

=head2 $asset->content 

Returns a scalar reference to the content contained in $asset->file

=cut

sub content {
    my $self = shift;

    if (my $file = $self->file) {
        croak "Trying to get content from non-existent file ($file)" unless -e $file;
        if (! $self->{content} || ($self->{mtime} != $file->stat->mtime)) {
            local $/ = undef;
            $self->{content} = \$self->file->slurp;
            $self->{mtime} = $file->stat->mtime;
        }
    }
    return $self->{content};
}

=head2 $asset->write( <content> ) 

Writes <content>, which should be a scalar reference, to the file located at $asset->file

If the parent directory for $asset->file does not exist yet, this method will create it first

=cut

sub write {
    my $self = shift;
    my $content = shift;

    my $file = $self->file;
    my $dir = $file->parent;
    $dir->mkpath unless -d $dir;
    $file->openw->print($$content);
}

=head2 $asset->digest

=head2 $asset->content_digest

Returns a hex digest for the content of $asset

NOTE: $asset->digest used to return a unique signature for the asset (based off the filename), but this has changed to
now return the actual hex digest of the content of $asset

=cut

sub digest {
    my $self = shift;
    return $self->{digest} ||= do {
        File::Assets::Util->digest->add(${ $self->content })->hexdigest;
    }
}

sub content_digest {
    my $self = shift;
    return $self->digest;
}

=head2 $asset->mtime

Returns the (stat) mtime of $asset->file, or 0 if $asset->file does not exist

=cut

sub mtime {
    my $self = shift;
    return $self->{mtime} unless $self->{rsc};
    return 0 unless my $stat = $self->file->stat;
    return $stat->mtime;
}

=head2 $asset->key

Returns the unique key for the $asset. Usually the path of the $asset, but for content-based assets returns a value based off of $asset->digest

=cut

sub key {
    my $self = shift;
    if ($self->{rsc}) {
        return $self->path;
    }
    else {
        return $self->{key} ||= '%' . $self->digest;
    }
}

=head2 $asset->hide

Hide $asset (mark it as hidden). That is, don't include $asset during export

=cut

sub hide {
    shift->{hidden} = 1;
}

=head2 $asset->inline

Returns whether $asset is inline (should be embedded into the document) or external.

If an argument is given, then it will set whether $asset is inline or not (1 for inline, 0 for external).

=cut

sub inline {
    my $self = shift;
    $self->{inline} = shift() ? 1 : 0 if @_;
    return $self->{inline};
}

1;
