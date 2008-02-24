#!perl -w
BEGIN {
    use Test::More;
    plan skip_all => 'install JavaScript::Minifier and CSS:Minifier to enable this test' and exit unless 
        eval "require JavaScript::Minifier" &&
        eval "require CSS::Minifier";
}

use strict;

use Test::More qw/no_plan/;
use t::Test;
{
    my $assets = t::Test->assets;
    my $scratch = t::Test->scratch;
    my $filter;

    $assets->include("css/apple.css");
    $assets->include("css/banana.css");
    $assets->include("css/cherry.css");
    $assets->include("js/apple.js");
    $assets->include("js/cherry.js");

    ok($scratch->exists("static/css/cherry.css"));
    is(-s $scratch->file("static/css/cherry.css"), 150);

    ok($filter = $assets->filter(css => "minifier"));
    is($assets->export, <<_END_);
<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
<script src="http://example.com/static/js/cherry.js" type="text/javascript"></script>
<link rel="stylesheet" type="text/css" media="screen" href="http://example.com/static/assets-screen.css" />
_END_
    ok($scratch->exists("static/assets-screen.css"));
    ok(-s $scratch->file("static/assets-screen.css"));
    like($scratch->read("static/assets-screen.css"), qr/div\.cherry/);
    like($scratch->read("static/assets-screen.css"), qr/font-weight/);

    ok($filter = $assets->filter(js => "minifier-javascript"));
    is($assets->export, <<_END_);
<script src="http://example.com/static/assets.js" type="text/javascript"></script>
<link rel="stylesheet" type="text/css" media="screen" href="http://example.com/static/assets-screen.css" />
_END_
    ok($scratch->exists("static/assets.js"));
    ok(-s $scratch->file("static/assets.js"));
    like($scratch->read("static/assets.js"), qr/"Nothing happens\."/);

    $assets->filter_clear($filter);
    $scratch->delete("static/assets.js");

    ok($filter = $assets->filter("minifier"));
    is($assets->export, <<_END_);
<script src="http://example.com/static/assets.js" type="text/javascript"></script>
<link rel="stylesheet" type="text/css" media="screen" href="http://example.com/static/assets-screen.css" />
_END_
    ok($scratch->exists("static/assets.js"));
    ok(-s $scratch->file("static/assets.js"));
    like($scratch->read("static/assets.js"), qr/"Nothing happens\."/);
}
{
    my $assets = t::Test->assets(
        output_path => [
        ],
        filter => [
            [ css => 'minifier', ],
            [ js => 'minifier', ],
        ],
    );
    my $scratch = t::Test->scratch;

    $assets->include("css/apple.css");
    $assets->include("css/banana.css");
    $assets->include("css/cherry.css");
    $assets->include("js/apple.js");
    $assets->include("js/cherry.js");

    ok($scratch->exists("static/css/cherry.css"));
    is(-s $scratch->file("static/css/cherry.css"), 150);

    is($assets->export, <<_END_);
<script src="http://example.com/static/assets.js" type="text/javascript"></script>
<link rel="stylesheet" type="text/css" media="screen" href="http://example.com/static/assets-screen.css" />
_END_
    ok($scratch->exists("static/assets-screen.css"));
    ok(-s $scratch->file("static/assets-screen.css"));
    like($scratch->read("static/assets-screen.css"), qr/div\.cherry/);
    like($scratch->read("static/assets-screen.css"), qr/font-weight/);
    ok($scratch->exists("static/assets.js"));
    ok(-s $scratch->file("static/assets.js"));
    like($scratch->read("static/assets.js"), qr/"Nothing happens\."/);
}
