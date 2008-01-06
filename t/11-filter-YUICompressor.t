#!perl -w

use strict;

use Test::More qw/no_plan/;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Assets::Test;
my $scratch = File::Assets::Test->scratch;
my $assets = File::Assets::Test->assets;

$assets->include("css/apple.css");
$assets->include("css/banana.css");
$assets->include("js/apple.js");

#diag($scratch->read("YUI.css"));
#<link rel="stylesheet" type="text/css" href="http://example.com/static/0721489ea0ebb3a72f863ebb315cd6ad.css" />
ok($assets->filter("yuicompressor:./yuicompressor.jar" => path => "YUI.%e", type => "css"));
is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/YUI.css" />
<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
_END_
ok($scratch->exists("YUI.css"));

ok($assets->filter("yuicompressor" => { path => "YUI.%e", type => "js", jar => "./yuicompressor.jar" }));
is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/YUI.css" />
<script src="http://example.com/static/YUI.js" type="text/javascript"></script>
_END_
ok($scratch->exists("YUI.js"));
