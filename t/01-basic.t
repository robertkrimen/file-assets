#!perl -w

use strict;

use Test::More qw/no_plan/;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Assets::Test;
my $scratch = File::Assets::Test->scratch;

ok(-e $scratch->base->file("css/apple.css"));
ok(-e $scratch->base->file("css/banana.css"));
ok(-e $scratch->base->file("js/apple.js"));

my $html;
ok(my $assets = File::Assets->new(base => [ "http://example.com/static", $scratch->base ]));

ok($assets->include("css/apple.css"));
ok($assets->include("js/apple.js"));

$html = $assets->export;
is($html, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/apple.css" />
<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
_END_

$html = $assets->export('css');
is($html, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/apple.css" />
_END_

$html = $assets->export('js');
is($html, <<_END_);
<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
_END_

ok($assets->include("css/banana.css"));

$html = $assets->export;
is($html, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/apple.css" />
<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/banana.css" />
_END_

