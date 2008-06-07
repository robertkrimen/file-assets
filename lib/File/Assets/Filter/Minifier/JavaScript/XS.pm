package File::Assets::Filter::Minifier::JavaScript::XS;

use strict;
use warnings;

use base qw/File::Assets::Filter::Minifier::Base/;
use File::Assets::Carp;

sub minify {
    return JavaScript::Minifier::XS::minify(shift);
}

1;
