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
    http://example.com/static/assets-39b784b6d86594ab3b4d9179d15c5514.css
    http://example.com/static/assets-096f395bf653a35849f7d4f4ac741140.js
));

is($scratch->read("static/assets-39b784b6d86594ab3b4d9179d15c5514.css"), "/* Everything is replaced with this! */");

$assets->name("base");
compare($assets->export, qw(
    http://example.com/static/base-39b784b6d86594ab3b4d9179d15c5514.css
    http://example.com/static/base-096f395bf653a35849f7d4f4ac741140.js
));

$assets->set_output_path_scheme([
    [ "*" => "static/xyzzy" ],
]);
compare($assets->export, qw(
    http://example.com/static/static/xyzzy.css
    http://example.com/static/static/xyzzy.js
));

$assets->set_output_path_scheme([
    [ "*" => "static/xyzzy/" ],
]);
compare($assets->export, qw(
    http://example.com/static/static/xyzzy/base-39b784b6d86594ab3b4d9179d15c5514.css
    http://example.com/static/static/xyzzy/base-096f395bf653a35849f7d4f4ac741140.js
));
