#!perl -w

use strict;

use Test::More qw/no_plan/;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Assets::Test;
my $assets = File::Assets::Test->assets;
my $scratch = File::Assets::Test->scratch;

my $asset;
my $assets1 = $asset = $assets->include("/css/apple.css");
ok($asset);
is($asset->uri, "http://example.com/css/apple.css");
is($asset->path, "/css/apple.css");
like($asset->file, qr{/css/apple\.css});

my $assets2 = $asset = $assets->include("css/apple.css");
ok($asset);
is($asset->uri, "http://example.com/static/css/apple.css");
is($asset->path, "/static/css/apple.css");
like($asset->file, qr{/css/apple\.css});
isnt($assets1, $assets2);

my $assets3 = $asset = $assets->include("/static/css/apple.css");
is($assets2, $assets3);
