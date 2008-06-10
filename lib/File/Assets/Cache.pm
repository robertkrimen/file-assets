package File::Assets::Cache;

use strict;
use warnings;

use Object::Tiny qw//;
use File::Assets::Carp;

use File::Assets;

my %cache;

sub new {
    my $class = shift;
    local %_ = @_;

    my $name = $_{name};
    if (defined $name) {
        if (ref $name eq "SCALAR") {
            $name = $$name;
        }
        elsif ($name eq 1) {
            $name = "__File::Assets::Cache_cache__";
        }
        return $cache{$name} if $cache{$name}
    }

    my $self = bless {}, $class;

    $self->{_registry} = {};

    $cache{$name} = $self if $name;

    return $self;
}

sub assets {
    my $self = shift;
    return File::Assets->new(cache => $self, @_);
}

sub exists {
    my $self = shift;
    my $dir = shift;
    my $key = shift;

    return exists $self->_registry($dir)->{$key} ? 1 : 0;
}

sub store {
    my $self = shift;
    my $dir = shift;
    my $asset = shift;

    return $self->_registry($dir)->{$asset->key} = $asset;
}

sub fetch {
    my $self = shift;
    my $dir = shift;
    my $key = shift;

    if (my $asset = $self->_registry($dir)->{$key}) {
        $asset->refresh;
        return $asset;
    }

    return undef;
}

sub _registry {
    my $self = shift;
    return $self->{_registry} unless @_;
    my $dir = shift;
    return $self->{_registry}->{$dir} ||= {};
}

sub clear {
    my $self = shift;
    $self->{_registry} = {};
}

1;
