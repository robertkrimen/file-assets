#!perl -w

use strict;

use Test::More qw/no_plan/;

use FindBin;
use lib "$FindBin::Bin/lib";

use t::Test;
my $scratch = t::Test->scratch;

SKIP: {
    skip "URI::ToDisk is not installed" unless eval "require URI::ToDisk;";

    my $assets = File::Assets->new(base => URI::ToDisk->new($scratch->base, "http://www.example.com/assets"));
    my $asset = $assets->include("static/css/apple.css");
    ok($asset);
    ok(-e $asset->file);
    ok(-s _);
    is($asset->uri, "http://www.example.com/assets/static/css/apple.css");
}

1;
