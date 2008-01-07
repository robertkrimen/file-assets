package File::Assets::Filter::Minifier::JavaScript;

use strict;
use warnings;

use base qw/File::Assets::Filter::Minifier/;

use JavaScript::Minifier;

__PACKAGE__->_type(File::Assets::Util->parse_type("js"));
__PACKAGE__->_minifier(sub {
    JavaScript::Minifier::minify(input => shift, outfile => shift);
});

1;
