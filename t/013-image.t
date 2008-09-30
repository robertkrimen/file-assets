#!perl -w

use strict;

use Test::More qw/no_plan/;
use t::Test;

{
    my $scratch = t::Test->scratch(1);
    my $assets = t::Test->assets(base => [ "http://example.com/", $scratch->base ]);
    $assets->set_output_path("built/");

    $assets->include("static/apple.png");

    ok(! -e $scratch->file("built/apple.png"));
    $assets->exports;

    ok(-e $scratch->file("built/apple.png"));
    ok(! -e $scratch->file("built/apple.gif"));
}

{
    my $scratch = t::Test->scratch(1);
    my $assets = t::Test->assets(base => [ "http://example.com/", $scratch->base ]);
    $assets->set_output_path("built/");

    $assets->include("static/apple.png");

    ok(! -e $scratch->file("built/apple.png"));
    $assets->exports("image");

    ok(-e $scratch->file("built/apple.png"));
    ok(! -e $scratch->file("built/apple.gif"));
}

{
    my $scratch = t::Test->scratch(1);
    my $assets = t::Test->assets(base => [ "http://example.com/", $scratch->base ]);
    $assets->set_output_path("built/");

    $assets->include("static/apple.png");

    ok(! -e $scratch->file("built/apple.png"));
    $assets->exports("css");

    ok(-e $scratch->file("built/apple.png"));
    ok(! -e $scratch->file("built/apple.gif"));
}

{
    my $scratch = t::Test->scratch(1);
    my $assets = t::Test->assets(base => [ "http://example.com/", $scratch->base ]);
    $assets->set_output_path("built/");

    $assets->include("static/apple.png");

    ok(! -e $scratch->file("built/apple.png"));
    $assets->exports("js");

    ok(! -e $scratch->file("built/apple.png"));
    ok(! -e $scratch->file("built/apple.gif"));
}

sub same_file ($$) {
    my $a = shift;
    my $b = shift;

    my $a_file = t::Test->scratch->file($a);
    my $b_file = t::Test->scratch->file($b);

    ok($a_file->stat->size);
    ok($b_file->stat->size);
    is($a_file->stat->size, $b_file->stat->size);
}

{
    my $scratch = t::Test->scratch(1);
    my $assets = t::Test->assets(base => [ "http://example.com/", $scratch->base ]);
    $assets->set_output_path("built/");

    $assets->include("static/apple.png");
    $assets->include("other/pear.tiff");
    $assets->include("plum.jpeg");
    $assets->include("apple.gif");

    $assets->exports;

    ok(-e $scratch->file("built/apple.png"));
    ok(-e $scratch->file("built/pear.tiff"));
    ok(-e $scratch->file("built/plum.jpeg"));
    ok(-e $scratch->file("built/apple.gif"));

    same_file "built/apple.png", "static/apple.png";
    same_file "built/pear.tiff", "other/pear.tiff";
    same_file "built/plum.jpeg", "plum.jpeg";
    same_file "built/apple.gif", "apple.gif";
}
