#!perl -w

use strict;

use Test::More qw/no_plan/;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Assets::Test;
my $assets = File::Assets::Test->assets;
my $scratch = File::Assets::Test->scratch;

$assets->include("css/apple.css");
$assets->include("css/banana.css");
$assets->include("js/apple.js");

my $path = "static/assets.css";
ok(my $filter = $assets->filter([ "Concat" ]));
is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/$path" />
_END_

sleep 2;

is($scratch->read($path), <<_END_);
/* Test file: static/css/apple.css */

/* Test file: static/css/banana.css */

/* Test file: static/js/apple.js */
_END_

ok(my $mtime = $scratch->file($path)->stat->mtime);

ok($assets->export);
is($scratch->file($path)->stat->mtime, $mtime, "Nothing changed, so $path should have an mtime of $mtime");

$scratch->write("static/js/custom.js", <<_END_);
/* This is custom.js */
_END_

ok($assets->include("js/custom.js"));
ok($assets->export);
isnt($scratch->file($path)->stat->mtime, $mtime, "Included a new file, so $path should not have an mtime of $mtime");
is($scratch->read($path), <<_END_);
/* Test file: static/css/apple.css */

/* Test file: static/css/banana.css */

/* Test file: static/js/apple.js */

/* This is custom.js */
_END_

ok($mtime = $scratch->file($path)->stat->mtime);

ok($assets->export);
is($scratch->file($path)->stat->mtime, $mtime, "Again, nothing changed, so $path should have an mtime $mtime");

sleep 2;

$scratch->write("static/js/custom.js", <<_END_);
/* This is a different custom.js */
_END_

ok($assets->export);
isnt($scratch->file($path)->stat->mtime, $mtime, "Changed the contents of custom.js, so $path should not have an mtime $mtime");
is($scratch->read($path), <<_END_);
/* Test file: static/css/apple.css */

/* Test file: static/css/banana.css */

/* Test file: static/js/apple.js */

/* This is a different custom.js */
_END_

ok($mtime = $scratch->file($path)->stat->mtime);

ok($assets->export);
is($scratch->file($path)->stat->mtime, $mtime, "Again, nothing changed, so $path should have an mtime $mtime");
