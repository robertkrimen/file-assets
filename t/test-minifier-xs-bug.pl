#!/usr/bin/perl -w

use CSS::Minifier::XS qw/minify/;

my $input;

$input = <<_END_;
/* block comments get removed */

/* comments containing the word "copyright" are left in, though */

/* but all other comments are removed */
_END_

$input = <<_END_;
/* */
_END_

print "Before:\n", $input, "\n";

my $output = minify $input;

print "After:\n", $output, "\n";
