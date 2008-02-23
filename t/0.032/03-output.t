#!perl -w

use strict;

use Test::More qw/no_plan/;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Assets::Test;
my $assets = File::Assets::Test->assets;
my $scratch = File::Assets::Test->scratch;

my $filter;
ok($filter = $assets->filter([ "TestCollect" => output => 'xyzzy/', type => "css" ]));
is($filter->asset->path, "/static/xyzzy/assets.css");
$filter->remove;

ok($filter = $assets->filter([ "TestCollect" => output => 'xyzzy', type => "css" ]));
is($filter->asset->path, "/static/xyzzy.css");
$filter->remove;

ok($filter = $assets->filter([ "TestCollect" => output => \'xyzzy', type => "css" ]));
is($filter->asset->path, "/static/xyzzy");
$filter->remove;

ok($filter = $assets->filter([ "TestCollect" => output => \'/xyzzy', type => "css" ]));
is($filter->asset->path, "/xyzzy");
$filter->remove;

ok($filter = $assets->filter([ "TestCollect" => output => '/xyzzy', type => "css" ]));
is($filter->asset->path, "/xyzzy.css");
$filter->remove;

ok($filter = $assets->filter([ "TestCollect" => output => '/%n/%e/xyzzy.%e', type => "css" ]));
is($filter->asset->path, "/assets/css/xyzzy.css");
$filter->remove;
