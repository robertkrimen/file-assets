#!perl -w

use strict;

use lib qw(t/lib);
use Test::More qw/no_plan/;
use t::Test;
my $assets = t::Test->assets;
my $scratch = t::Test->scratch;

ok($assets->include("css/apple.css"));
ok($assets->include("css/banana.css"));
ok($assets->include("js/apple.js"));

my $filter;
ok($filter = $assets->filter([ "Test" ]));

$filter->remove; # Doesn't do anything anymore
$assets->filter_clear;

ok($filter = $assets->filter([ "TestCollect" ]));
is($assets->export, <<_END_);
<script src="http://example.com/static/assets.js" type="text/javascript"></script>
<link rel="stylesheet" type="text/css" media="screen" href="http://example.com/static/assets-screen.css" />
_END_

is($scratch->read("static/assets-screen.css"), "/* Everything is replaced with this! */");

$assets->name("base");

is($assets->export, <<_END_);
<script src="http://example.com/static/base.js" type="text/javascript"></script>
<link rel="stylesheet" type="text/css" media="screen" href="http://example.com/static/base-screen.css" />
_END_

$assets->set_output_path_scheme([
    [ "*" => "static/xyzzy" ],
]);

is($assets->export, <<_END_);
<script src="http://example.com/static/static/xyzzy.js" type="text/javascript"></script>
<link rel="stylesheet" type="text/css" media="screen" href="http://example.com/static/static/xyzzy.css" />
_END_

$assets->set_output_path_scheme([
    [ "*" => "static/xyzzy/" ],
]);

is($assets->export, <<_END_);
<script src="http://example.com/static/static/xyzzy/base.js" type="text/javascript"></script>
<link rel="stylesheet" type="text/css" media="screen" href="http://example.com/static/static/xyzzy/base-screen.css" />
_END_


