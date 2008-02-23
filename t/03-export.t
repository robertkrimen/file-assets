#!perl -w

use strict;

use Test::More qw/no_plan/;

use t::Test;
my $assets = t::Test->assets;

$assets->include("apple.css");
is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" media="screen" href="http://example.com/static/apple.css" />
_END_

$assets->include("apple.js");
$assets->include("banana.css");
is($assets->export, <<_END_);
<script src="http://example.com/static/apple.js" type="text/javascript"></script>
<link rel="stylesheet" type="text/css" media="screen" href="http://example.com/static/apple.css" />
<link rel="stylesheet" type="text/css" media="screen" href="http://example.com/static/banana.css" />
_END_
