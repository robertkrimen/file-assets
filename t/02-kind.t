#!perl -w

use strict;

use Test::More qw/no_plan/;

use t::Test;
my $assets = t::Test->assets;

my ($asset, $kind);

$asset = $assets->include("apple.css");
$kind = File::Assets->kind($asset);
ok($kind);
is($kind->kind, "css-screen");

is(File::Assets->kind($assets->include("apple.js"))->kind, "js");

$asset->attributes->{media} = "print";
is(File::Assets->kind($asset)->kind, "css-print");
