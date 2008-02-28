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
compare($assets->export, qw(
    http://example.com/static/assets.js
    http://example.com/static/assets-screen.css
));

is($scratch->read("static/assets-screen.css"), "/* Everything is replaced with this! */");

$assets->name("base");
compare($assets->export, qw(
    http://example.com/static/base.js
    http://example.com/static/base-screen.css
));

$assets->set_output_path_scheme([
    [ "*" => "static/xyzzy" ],
]);
compare($assets->export, qw(
    http://example.com/static/static/xyzzy.js
    http://example.com/static/static/xyzzy.css
));

$assets->set_output_path_scheme([
    [ "*" => "static/xyzzy/" ],
]);
compare($assets->export, qw(
    http://example.com/static/static/xyzzy/base.js
    http://example.com/static/static/xyzzy/base-screen.css
));
