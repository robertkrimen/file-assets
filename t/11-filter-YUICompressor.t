#!perl -w
BEGIN {
    use Test::More;
    plan skip_all => 'install ./yuicompressor.jar to enable this test' and exit unless -e "./yuicompressor.jar"
}

use strict;

use Test::More qw/no_plan/;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Assets::Test;
my $scratch = File::Assets::Test->scratch;
my $assets = File::Assets::Test->assets;
my $filter;

$assets->include("css/apple.css");
$assets->include("css/banana.css");
$assets->include("js/apple.js");

#diag($scratch->read("YUI.css"));
#<link rel="stylesheet" type="text/css" href="http://example.com/static/0721489ea0ebb3a72f863ebb315cd6ad.css" />
ok($filter = $assets->filter("yuicompressor:./yuicompressor.jar" => output => "YUI.%e", type => "css"));
is($filter->cfg->{jar}, "./yuicompressor.jar");
is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/YUI.css" />
<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
_END_
ok($scratch->exists("static/YUI.css"));
is(-s $scratch->file("static/YUI.css"), 0);

ok($assets->filter("yuicompressor" => { output => "YUI.%e", type => "js", jar => "./yuicompressor.jar" }));
is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/YUI.css" />
<script src="http://example.com/static/YUI.js" type="text/javascript"></script>
_END_
ok($scratch->exists("static/YUI.js"));
is(-s $scratch->file("static/YUI.js"), 0);

$assets->filter_clear;

ok($assets->filter("yuicompressor" => { output => "xyzzy/YUI.%e", type => "js", jar => "./yuicompressor.jar" }));
is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/apple.css" />
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/banana.css" />
<script src="http://example.com/static/xyzzy/YUI.js" type="text/javascript"></script>
_END_
ok($scratch->exists("static/xyzzy/YUI.js"));
is(-s $scratch->file("static/xyzzy/YUI.js"), 0);
