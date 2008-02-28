package File::Assets::Asset::Content;

use warnings;
use strict;

use base qw/File::Assets::Asset::File/;

1;

__END__
use warnings;
use strict;

use File::Assets::Util;
use Carp::Clan qw/^File::Assets/;
use base qw/File::Assets::Asset/;
use Object::Tiny qw/content/;
#use Data::UUID;
#my $ug = Data::UUID->new;

sub _extract($$$) {
    my ($hash, $name, $default);
    return exists $hash->{$name} ? delete $hash->{$name} : $default;
}

sub new {
    my $self = bless {}, shift;
    my $asset = @_ == 1 && ref $_[0] eq "HASH" ? shift : { @_ };

    croak "Don't have any content for this asset" unless $asset->{content};
    my $content = delete $asset->{content};
    $content = ref $content eq "SCALAR" ? $$content : $content;
    $self->{content} = \$content;

    croak "Don't have a type for this asset" unless $asset->{type};
    my $type = delete $asset->{type};
    $self->{type} = File::Assets::Util->parse_type($type) or croak "Don't understand type ($type) for this asset";

    my $rank = $self->{rank} = delete $asset->{rank} || 0;
    croak "Don't understand rank ($rank)" if $rank && $rank =~ m/[^\d\+\-\.]/;

    $self->{mtime} = delete $asset->{mtime} || 0;
    $self->{inline} = exists $asset->{inline} ? (delete $asset->{inline} ? 1 : 0) : 1;

    $self->{attributes} = { %$asset }; # The rest goes here!

    return $self;
}

sub key {
    my $self = shift;
    return $self->{key} ||= '%' . $self->digest;
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
