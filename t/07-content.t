#!perl -w

use strict;

use Test::More qw/no_plan/;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Assets::Test;
my $assets = File::Assets::Test->assets;
my $scratch = File::Assets::Test->scratch;
my $html;

ok(-e $scratch->base->file("static/css/apple.css"));
ok(-e $scratch->base->file("static/css/banana.css"));
ok(-e $scratch->base->file("static/js/apple.js"));

ok($assets->include("css/apple.css"));
ok($assets->include("js/apple.js"));
ok($assets->include_content(<<_END_, "css"));
div {
    background: red;
}
_END_

is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/apple.css" />
<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
<style type="text/css">
div {
    background: red;
}

</style>
_END_

is($assets->export('css'), <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/apple.css" />
<style type="text/css">
div {
    background: red;
}

</style>
_END_

is($assets->export('js'), <<_END_);
<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
_END_

ok($assets->include("css/banana.css"));

is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/apple.css" />
<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
<style type="text/css">
div {
    background: red;
}

</style>
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/banana.css" />
_END_

use Test::Memory::Cycle;
memory_cycle_ok($assets);

my $digest = "4622fcfb3d29438ce9298d288fdcc57e";

ok($assets->filter([ "concat" => type => ".css", output => '%D.%e', ]));
is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/$digest.css" />
<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
_END_

ok($scratch->exists("static/$digest.css"));
ok(-s $scratch->file("static/$digest.css"));
is($scratch->read("static/$digest.css"), <<_END_);
/* Test file: static/css/apple.css */

div {
    background: red;
}
/* Test file: static/css/banana.css */
_END_

SKIP: {
    skip 'install ./yuicompressor.jar to enable this test' unless -e "./yuicompressor.jar";

    $scratch->delete("static/$digest.css");
    $assets->filter_clear;

    ok($assets->filter("yuicompressor:./yuicompressor.jar" => output => '%D.%e', type => "css"));
    is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/$digest.css" />
<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
_END_
    ok($scratch->exists("static/$digest.css"));
    ok(-s $scratch->file("static/$digest.css"));
    is($scratch->read("static/$digest.css"), 'div{background:red;}');
}
