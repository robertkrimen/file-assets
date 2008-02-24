package File::Assets::Filter::Minifier::JavaScript;

use strict;
use warnings;

use base qw/File::Assets::Filter::Minifier/;
use Carp::Clan qw/^File::Assets/;

my $minifier = "JavaScript::Minifier";
my $available = eval "require $minifier;";

sub new {
    my $class = shift;
    croak "You need to install $minifier to use this filter: $class" unless $available;
    return $class->SUPER::new(@_);
}

sub minify {
    return JavaScript::Minifier::minify(input => shift, outfile => shift);
}
__PACKAGE__->_minifier(\&minify);

1;
