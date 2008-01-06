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

my $digest = "3c19f669dd48b5c16d34e5c00ec3155a";

ok($assets->filter([ "concat" => type => ".css", path => '%D.%e', ]));
is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/$digest.css" />
<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
_END_

ok($scratch->exists("$digest.css"));
