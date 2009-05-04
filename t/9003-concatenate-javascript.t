#!perl -w

use strict;

use Test::More qw/no_plan/;
use t::Test;
my $assets = t::Test->assets( minify => 1 );
my $scratch = t::Test->scratch;

$assets->include( \<<_END_, 'js', 0, { inline => 0 } );
var a = function() { 1; }
a()
_END_

$assets->include( \<<_END_, 'js', 0, { inline => 0 } );
(
    function(){1;}
)();
_END_


my ($asset) = $assets->exports;
warn $asset->file;
warn $asset->file->slurp;


