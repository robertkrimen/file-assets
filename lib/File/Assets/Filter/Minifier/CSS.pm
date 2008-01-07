package File::Assets::Filter::Minifier::CSS;

use strict;
use warnings;

use base qw/File::Assets::Filter::Minifier/;
use Carp::Clan qw/^File::Assets/;

my $minifier = "CSS::Minifier";
sub new {
    my $class = shift;
    croak "You need to install $minifier to use this filter: $class" unless eval "require $minifier";
    return $class->SUPER::new(@_);
}

__PACKAGE__->_type(File::Assets::Util->parse_type("css"));
__PACKAGE__->_minifier(sub {
    CSS::Minifier::minify(input => shift, outfile => shift);
});

1;
