#!perl -w

use strict;

use Test::More qw/no_plan/;

use File::Assets;
use Directory::Scratch;

my $scratch = Directory::Scratch->new;
$scratch->create_tree({
    map { $_ => "$_\n" } qw(css/apple.css css/banana.css js/apple.js),
});
my $html = "";

my $assets = File::Assets->new(base => [ "http://example.com/static", $scratch->base ]);
ok($assets);

ok($assets->include("/css/apple.css"));
ok($assets->include("/css/banana.css"));
ok($assets->include("/js/apple.js"));

#ok($assets->filter("yuicompressor" => { path => "YUI.%e", type => "css", jar => "./yuicompressor.jar" }));
ok($assets->filter("yuicompressor:./yuicompressor.jar" => path => "YUI.%e", type => "css"));
$html = $assets->export;
#is($html, <<_END_);
#<link rel="stylesheet" type="text/css" href="http://example.com/static/0721489ea0ebb3a72f863ebb315cd6ad.css" />
#<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
#_END_

ok($scratch->exists("YUI.css"));
diag($scratch->read("YUI.css"));
