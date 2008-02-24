package File::Assets::Asset;

use warnings;
use strict;

use File::Assets::Util;
use Carp::Clan qw/^File::Assets/;
use Object::Tiny qw/type rank attributes hidden/;

sub new {
    croak "$_[0] is an abstract class";
}

sub mtime {
    return 0;
}

sub external {
    return 0;
}

sub hide {
    shift->{hidden} = 1;
}

1;
