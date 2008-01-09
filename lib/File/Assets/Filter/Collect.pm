package File::Assets::Filter::Collect;

use strict;
use warnings;

use base qw/File::Assets::Filter/;

use Digest;
use File::Assets;

my %default = (qw/
        skip_single 0
        skip_if_exists 0
        check_content 0
        content_digest 0
        check_age 1 
        check_digest 1
    /,
);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    local %_ = @_;
    while (my ($setting, $value) = each %default) {
        $self->cfg->{$setting} = exists $_{$setting} ? $_{$setting} : $value;
    }
    $self->cfg->{content_digest} = 1 if $self->cfg->{check_content};
    $self->cfg->{content_digest} = 1 if $self->cfg->{output} && $self->cfg->{output} =~ m/%D/;
    return $self;
}

sub pre {
    my $self = shift;
    $self->SUPER::pre(@_);

    return 0 if $self->skip_if_exists;

    if ($self->cfg->{content_digest}) {
        $self->stash->{content_digester} = File::Assets::Util->digest;
    }

    return 1;
}

sub process {
    my $self = shift;
    $self->SUPER::process(@_);
    if (my $digester = $self->stash->{content_digester}) {
        my $asset = shift;
        $digester->add($asset->content_digest."\n");
    }
}

sub post {
    my $self = shift;
    $self->SUPER::post(@_);

    my $assets = shift;
    my $matched = shift;

    return unless @$matched;

    return if $self->cfg->{skip_single} && 1 == @$matched;

    if (my $digester = $self->stash->{content_digester}) {
        $self->stash->{content_digest} = $digester->hexdigest;
    }

    my $type = $self->find_type;

    return if $self->skip_if_exists;

    my $build = $self->should_build;

    if ($build) {
        $self->check_digest_file->touch;
        $self->build;
    }

    $self->replace;
}

sub skip_if_exists {
    my $self = shift;

    if ($self->cfg->{skip_if_exists} && $self->asset) {
        if (-e $self->asset->file && -s _) {
            $self->replace;
            return 1;
        }
    }
    return 0;
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

sub content_digest {
    my $self = shift;
    return $self->stash->{content_digest};
}

sub build {
    my $self = shift;

    my $content = $self->build_content;

    $self->asset->write($content) if defined $content;
}

sub replace {
    my $self = shift;

    my $assets = $self->stash->{assets};
    my $matched = $self->matched;
    my $top_match = $matched->[0];
    my $top_asset = $top_match->{asset};

    for my $match (reverse @$matched) {
        my $rank = $match->{rank};
        splice @$assets, $rank, 1, ();
    }

    splice @$assets, $top_match->{rank}, 0, $self->asset; 
}

sub find_type {
    my $self = shift;
    my $frob;
    return $frob if $frob = $self->type;
    # FIXME Is this a good idea? What happens when you mix types?
    return $frob if (($frob = $self->stash->{matched}->[0]) && ($frob = $frob->{asset}->type));
    return undef;
}

1;
