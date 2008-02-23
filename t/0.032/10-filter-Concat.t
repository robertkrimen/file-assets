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

my $digest = "b11bf9a77b520852e95af3e0b5c1aa95";

ok($assets->filter([ "concat" => type => ".css", output => '%D.%e', ]));
is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/$digest.css" />
<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
_END_

ok($scratch->exists("static/$digest.css"));
ok(-s $scratch->file("static/$digest.css"));
