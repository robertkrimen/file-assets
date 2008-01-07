package File::Assets::Filter::Minifier::CSS;

use strict;
use warnings;

use base qw/File::Assets::Filter::Minifier/;

use CSS::Minifier;

__PACKAGE__->_type(File::Assets::Util->parse_type("css"));
__PACKAGE__->_minifier(sub {
    CSS::Minifier::minify(input => shift, outfile => shift);
});

1;