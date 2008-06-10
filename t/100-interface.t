#!perl -w

use strict;

use Test::More qw/no_plan/;
use t::Test;

sub assets {
    my $scratch = t::Test::Scratch->new;
    my $assets = File::Assets->new(base => [ "http://example.com/", $scratch->base, "/static" ], @_);
    $assets->include("css/apple.css");
    $assets->include("css/banana.css");
    $assets->include("js/apple.js");
    return ($scratch, $assets);
}

{
    my ($scratch, $assets) = assets(qw(output_path %n%-l.%e minify 1));

    compare($assets->export, qw(
        http://example.com/static/assets.css
        http://example.com/static/assets.js
    ));
    ok($scratch->exists("static/assets.css"));
    is(-s $scratch->file("static/assets.css"), 1);

    $scratch->cleanup;
}

{
    {
        my ($scratch, $assets) = assets(qw(output_path %n%-l.%e minify ./yuicompressor.jar));

        compare($assets->export, qw(
            http://example.com/static/assets.css
            http://example.com/static/assets.js
        ));
        ok($scratch->exists("static/assets.css"));
        is(-s $scratch->file("static/assets.css"), 0);
    }

    {
        my ($scratch, $assets) = assets(qw(output_path %n%-l.%e minify yuicompressor:./yuicompressor.jar));

        compare($assets->export, qw(
            http://example.com/static/assets.css
            http://example.com/static/assets.js
        ));
        ok($scratch->exists("static/assets.css"));
        is(-s $scratch->file("static/assets.css"), 0);
    }
}

{
    my ($scratch, $assets) = assets(qw(output_path %n%-f.%e minify 1));

    compare($assets->export, qw(
        http://example.com/static/assets-b11bf9a77b520852e95af3e0b5c1aa95.css
        http://example.com/static/assets-7442c488c0bf3d37fc6bece0b5b8eea9.js
    ));
}
