package File::Assets::Asset;

use warnings;
use strict;

use File::Assets::Util;
use Carp::Clan qw/^File::Assets/;
use Object::Tiny qw/type rank/;

sub mtime {
    return 0;
}

sub external {
    return 0;
}

1;
