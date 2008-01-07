package File::Assets::Asset;

use warnings;
use strict;

use File::Assets::Util;
use Carp::Clan qw/^File::Assets/;
use Object::Tiny qw/rsc type rank/;

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
    return $self;
}

sub uri {
    my $self = shift;
    return $self->rsc->uri;
}

sub path {
    my $self = shift;
    return $self->rsc->path;
}

sub file {
    my $self = shift;
    return $self->{file} ||= $self->rsc->file;
}

sub content {
    my $self = shift;
    return $self->{content} ||= do {
        my $file = $self->file;
        croak "Trying to get content from non-existent file ($file)" unless -e $file;
        local $/ = undef;
        \$self->file->slurp;
    }
}

sub write {
    my $self = shift;
    my $content = shift;

    my $file = $self->file;
    my $dir = $file->parent;
    $dir->mkpath unless -d $dir;
    $file->openw->print($$content);
}

sub digest {
    my $self = shift;
    return $self->{digest} ||= do {
        File::Assets::Util->digest->add($self->file."")->hexdigest;
    }
}

sub content_digest {
    my $self = shift;
    return $self->{content_digest} ||= do {
        File::Assets::Util->digest->add(${ $self->content })->hexdigest;
    }
}

sub mtime {
    my $self = shift;
    return 0 unless my $stat = $self->file->stat;
    return $stat->mtime;
}

1;
