#!perl -w

use strict;

use Test::More qw/no_plan/;
use t::Test;
my $assets = t::Test->assets;
my $scratch = t::Test->scratch;

$assets->include("css/apple.css");
$assets->include("css/banana.css");
$assets->include("css/grape.css");

my $path = "static/assets-screen.css";
ok(my $filter = $assets->filter([ "Concat" ]));
is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" media="screen" href="http://example.com/$path" />
_END_

is($scratch->read($path), <<_END_);
/* Test file: static/css/apple.css */

/* Test file: static/css/banana.css */

/* This is grape.css */
_END_

ok(my $mtime = $scratch->file($path)->stat->mtime);

sleep 2;

ok($assets->export);
is($scratch->file($path)->stat->mtime, $mtime, "Nothing changed, so $path should have an mtime of $mtime");

sleep 2;

$scratch->write("static/css/custom.css", <<_END_);
/* This is custom.css */
_END_

ok($assets->include("css/custom.css"));
ok($assets->export);
isnt($scratch->file($path)->stat->mtime, $mtime, "Included a new file, so $path should not have an mtime of $mtime");
is($scratch->read($path), <<_END_);
/* Test file: static/css/apple.css */

/* Test file: static/css/banana.css */

/* This is grape.css */

/* This is custom.css */
_END_

ok($mtime = $scratch->file($path)->stat->mtime);

sleep 2;

ok($assets->export);
is($scratch->file($path)->stat->mtime, $mtime, "Again, nothing changed, so $path should have an mtime $mtime");

sleep 2;

$scratch->write("static/css/custom.css", <<_END_);
/* This is a different custom.css */
_END_

ok($assets->export);
isnt($scratch->file($path)->stat->mtime, $mtime, "Changed the contents of custom.css, so $path should not have an mtime $mtime");
is($scratch->read($path), <<_END_);
/* Test file: static/css/apple.css */

/* Test file: static/css/banana.css */

/* This is grape.css */

/* This is a different custom.css */
_END_

ok($mtime = $scratch->file($path)->stat->mtime);

ok($assets->export);
is($scratch->file($path)->stat->mtime, $mtime, "Again, nothing changed, so $path should have an mtime $mtime");