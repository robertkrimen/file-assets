#!perl -w

use strict;

use Test::More qw/no_plan/;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Assets::Test;
my $assets = File::Assets::Test->assets;
my $scratch = File::Assets::Test->scratch;

$assets->include("css/apple.css");
is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/apple.css" />
_END_

$assets->include("css/banana.css", -10);
is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/banana.css" />
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/apple.css" />
_END_

$assets->include("css/cherry.css", 0);
is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/banana.css" />
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/apple.css" />
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/cherry.css" />
_END_

$assets->include("js/cherry.js", -5);
is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/banana.css" />
<script src="http://example.com/static/js/cherry.js" type="text/javascript"></script>
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/apple.css" />
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/cherry.css" />
_END_

$assets->include("js/apple.js", -100);
is($assets->export, <<_END_);
<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/banana.css" />
<script src="http://example.com/static/js/cherry.js" type="text/javascript"></script>
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/apple.css" />
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/cherry.css" />
_END_

is($assets->export('css'), <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/banana.css" />
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/apple.css" />
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/cherry.css" />
_END_

is($assets->export('js'), <<_END_);
<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
<script src="http://example.com/static/js/cherry.js" type="text/javascript"></script>
_END_
