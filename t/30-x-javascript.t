#!perl -w

use strict;

use Test::More qw/no_plan/;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Assets::Test;
my $assets = File::Assets::Test->assets;
my $scratch = File::Assets::Test->scratch;
my $html;

File::Assets::Util->types->addType(MIME::Type->new(type => "application/x-javascript", extensions => [qw/js/]));

ok($assets->include("css/apple.css"));
ok($assets->include("js/apple.js")); # Not a great test, as MIME::T

is($assets->export, <<_END_);
<link rel="stylesheet" type="text/css" href="http://example.com/static/css/apple.css" />
<script src="http://example.com/static/js/apple.js" type="text/javascript"></script>
_END_
