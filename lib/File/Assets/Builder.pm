package File::Assets::Builder;

use strict;
use warnings;

sub process {
}

sub should_build {
    my $self = shift;

    if ($self->cfg->{check_content}) {
        my $digest = $self->content_digest;
        my $dir = $self->group->rsc->dir->subdir(".check-content-digest");
        my $file = $dir->file($digest);
        unless (-e $file) {
            $file->touch;
            return 1;
        }
        $file->touch;
    }

    if ($self->cfg->{check_age}) {
        my $mtime = $self->mtime;
        return 1 if $mtime > $self->asset->mtime;
    }

    if ($self->cfg->{check_digest}) {
        my $file = $self->check_digest_file;
        unless (-e $file) {
            return 1;
        }
    }

    return 0;
}

sub check_digest_file {
    my $self = shift;
    my $digest = $self->digest;
    my $dir = $self->assets->rsc->dir->subdir(".check-digest");
    $dir->mkpath unless -d $dir;
    my $file = $dir->file($digest);
    return $file;
}

sub asset {
    my $self = shift;
    return $self->stash->{asset} ||= do {
        my $type = shift || $self->find_type;
        my $path = File::Assets::Util->build_asset_path(undef, # $output
            assets => $self->assets,
            filter => $self,
            name => $self->assets->name,
            type => $type,
            digest => $self->digest,
            content_digest => $self->content_digest,
        );
        return File::Assets::Util->parse_asset_by_path(
            path => $path,
            base => $self->assets->rsc,
            type => $type,
        );
    }
}

sub build {
    my $self = shift;

    my $content = $self->build_content;

    $self->asset->write($content) if defined $content;
}

1;
