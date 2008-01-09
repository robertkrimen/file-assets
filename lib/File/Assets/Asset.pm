package File::Assets::Asset;

use warnings;
use strict;

use File::Assets::Util;
use Carp::Clan qw/^File::Assets/;
use Object::Tiny qw/rsc type rank/;

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
    local %_ = @_;
    my ($path, $rsc, $base, $content, $type, $rank) = @_{qw/path rsc base content type rank/};
    if ($rsc) {
        $self->{rsc} = $rsc;
        $self->{type} = $type;
        $self->{content} = $content if $content;
    }
    elsif ($base && $path) {
        if ($path =~ m/^\//) {
            $self->{rsc} = $base->clone($path);
        }
        else {
            $self->{rsc} = $base->child($path);
        }
        $self->{type} = File::Assets::Util->parse_type($type) ||
            File::Assets::Util->parse_type($path) or 
            croak "Don't know type for asset ($path)";
        $self->{content} = $content if $content;
    }
    elsif ($base && $content) {
        $self->{type} = File::Assets::Util->parse_type($type) or
            croak "Don't know type for asset ($path)";
        $self->{content} = $content;
        my $path = File::Assets::Util->build_asset_path(undef, type => $type, content_digest => $self->content_digest);
        $self->{rsc} = $base->child($path);
    }
    else {
        croak "Don't know what to do: @_";
    }
    croak "Don't understand rank ($rank)" if $rank && $rank =~ m/[^\d\+\-\.]/;
    $self->{rank} = $rank ? $rank : 0;
    $self->{mtime} = 0;
    return $self;
}

=head2 $asset->uri 

Returns a L<URI> object represting the uri for $asset

=cut

sub uri {
    my $self = shift;
    return $self->rsc->uri;
}

=head2 $asset->uri 

Returns a L<Path::Class::File> object represting the file for $asset

=cut

sub file {
    my $self = shift;
    return $self->{file} ||= $self->rsc->file;
}

sub path {
    my $self = shift;
    return $self->rsc->path;
}

=head2 $asset->content 

Returns a scalar reference to the content contained in $asset->file

=cut

sub content {
    my $self = shift;
    my $file = $self->file;
    croak "Trying to get content from non-existent file ($file)" unless -e $file;
    if (! $self->{content} || ($self->{mtime} != $file->stat->mtime)) {
        local $/ = undef;
        $self->{content} = \$self->file->slurp;
        $self->{mtime} = $file->stat->mtime;
        $self->{content_digest} = File::Assets::Util->digest->add(${ $self->{content} })->hexdigest;
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

Returns a hex digest for (currently the filename of) this asset

This is NOT a hex digest of the content, for that, use $asset->content_digest

Hmm, this might change in the future.

=cut

sub digest {
    my $self = shift;
    return $self->{digest} ||= do {
        File::Assets::Util->digest->add($self->file."")->hexdigest;
    }
}

=head2 $asset->content_digest

Returns the  hex digest of $asset->content

=cut

sub content_digest {
    my $self = shift;
    return $self->{content_digest} ||= do {
        $self->content;
        $self->{content_digest};
    }
}

=head2 $asset->mtime

Returns the (stat) mtime of $asset->file, or 0 if $asset->file does not exist

=cut

sub mtime {
    my $self = shift;
    return 0 unless my $stat = $self->file->stat;
    return $stat->mtime;
}

1;
