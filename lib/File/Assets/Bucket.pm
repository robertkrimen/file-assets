package File::Assets::Bucket;

use warnings;
use strict;

use Object::Tiny qw/kind assets/;

sub new {
    my $self = bless {}, shift;
    $self->{kind} = my $kind = shift;
    $self->{assets} = my $assets = shift;
    $self->{slice} = [];
    $self->{filters} = {};
    return $self;
}

sub add_asset {
    my $self = shift;
    my $asset = shift;
    push @{ $self->{slice} }, $asset;
}

sub add_filter {
    my $self = shift;
    my $filter = shift;

    my $filters = $self->{filters};
    my $signature = $filter->signature;

    return 0 if $filters->{$signature} && ! $filter->is_better_than($filters->{$signature});

    $filters->{$signature} = $filter;

    return 1;
}

sub exports {
    my $self = shift;
    my @assets = $self->all;
    my $filters = $self->{filters};
    for my $filter (values %$filters) {
        $filter->filter(\@assets, $self, $self->assets);
    }
    return $self->all;
}

sub clear {
    my $self = shift;
    $self->{slice} = [];
    $self->{filters} = {};
}

sub all {
    my $self = shift;
    return @{ $self->{slice} };
}

1;
