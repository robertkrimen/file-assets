package File::Assets::Kind;

use strict;
use warnings;

use Object::Tiny qw/kind type/;

sub new {
    my $self = bless {}, shift;
    $self->{kind} = my $kind = shift;
    $self->{type} = my $type = shift;
    return $self;
}

1;
