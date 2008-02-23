package File::Assets::Asset::Content;

use warnings;
use strict;

use File::Assets::Util;
use Carp::Clan qw/^File::Assets/;
use base qw/File::Assets::Asset/;
use Object::Tiny qw/content uuid/;
use Data::UUID;
my $ug = Data::UUID->new;

sub new {
    my $self = bless {}, shift;
    local %_ = @_;
    my ($content, $type, $rank) = @_{qw/content type rank/};
    $content = ref $content eq "SCALAR" ? $$content : $content;
    $self->{content} = \$content;
    $self->{type} = File::Assets::Util->parse_type($type) or croak "Don't know type for asset";
    croak "Don't understand rank ($rank)" if $rank && $rank =~ m/[^\d\+\-\.]/;
    $self->{rank} = $rank ? $rank : 0;
    $self->{mtime} = 0;
    $self->{uuid} = $ug->create_hex;
    $self->{attributes} = {};
    return $self;
}

sub key {
    return shift->uuid;
}

sub digest {
    my $self = shift;;
    return $self->{digest} ||= do {
        File::Assets::Util->digest->add(${ $self->content })->hexdigest;
    };
}

sub content_digest {
    return shift->digest;
}

1;
