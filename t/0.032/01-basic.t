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

is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/apple.css" />
<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
_END_

is($assets->export('css'), <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/apple.css" />
_END_

is($assets->export('js'), <<_END_);
<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
_END_

ok($assets->include("css/banana.css"));

is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/apple.css" />
<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/banana.css" />
_END_

use Test::Memory::Cycle;
memory_cycle_ok($assets);
