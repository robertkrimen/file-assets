#!perl -w

use strict;

use Test::More qw/no_plan/;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Assets::Test;
my $assets = File::Assets::Test->assets;
my $scratch = File::Assets::Test->scratch;

ok($assets->include("css/apple.css"));
ok($assets->include("css/banana.css"));
ok($assets->include("js/apple.js"));

my $filter;
ok($filter = $assets->filter([ "Test" ]));
is($filter->assets, $assets);
is($filter->cfg->{output}, undef);
ok($filter->stash);

ok($assets->filters);
is(ref $assets->filters, "ARRAY");
is(@{ $assets->filters }, 1);

$filter->remove;
is(@{ $assets->filters }, 0);

ok($filter = $assets->filter([ "Test" ]));
is(@{ $assets->filters }, 1);
$assets->filter_clear(filter => 0);
is(@{ $assets->filters }, 1);

$assets->filter_clear;
is(@{ $assets->filters }, 0);

ok($filter = $assets->filter([ "TestCollect" ]));
is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/assets.css" />
_END_

is($scratch->read("static/assets.css"), "/* Everything is replaced with this! */");

$assets->name("base");

is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/base.css" />
_END_

$assets->filter_clear;

ok($filter = $assets->filter("TestCollect" => output => "static/xyzzy"));
is($filter->cfg->{output}, "static/xyzzy");

is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/static/xyzzy.css" />
_END_

$assets->filter_clear;

ok($filter = $assets->filter("TestCollect" => output => "static/xyzzy/"));
is($filter->cfg->{output}, "static/xyzzy/");

is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/static/xyzzy/base.css" />
_END_


