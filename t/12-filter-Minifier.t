#!perl -w
BEGIN {
    use Test::More;
    plan skip_all => 'install JavaScript::Minifier and CSS:Minifier to enable this test' and exit unless 
        eval "require JavaScript::Minifier" &&
        eval "require CSS::Minifier";
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
$assets->include("css/cherry.css");
$assets->include("js/apple.js");
$assets->include("js/cherry.js");

ok($scratch->exists("static/css/cherry.css"));
is(-s $scratch->file("static/css/cherry.css"), 150);

ok($filter = $assets->filter("minifier-css"));
is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/assets.css" />
<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
<script src="http://example.com/static/js/cherry.js" type="text/javascript"></script>
_END_
ok($scratch->exists("static/assets.css"));
ok(-s $scratch->file("static/assets.css"));
like($scratch->read("static/assets.css"), qr/div\.cherry/);
like($scratch->read("static/assets.css"), qr/font-weight/);

ok($filter = $assets->filter("minifier-javascript"));
is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/assets.css" />
<script src="http://example.com/static/assets.js" type="text/javascript"></script>
_END_
ok($scratch->exists("static/assets.js"));
ok(-s $scratch->file("static/assets.js"));
like($scratch->read("static/assets.js"), qr/"Nothing happens\."/);

$filter->remove;
$scratch->delete("static/assets.js");

ok($filter = $assets->filter("minifier-js"));
is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/assets.css" />
<script src="http://example.com/static/assets.js" type="text/javascript"></script>
_END_
ok($scratch->exists("static/assets.js"));
ok(-s $scratch->file("static/assets.js"));
like($scratch->read("static/assets.js"), qr/"Nothing happens\."/);

1;
