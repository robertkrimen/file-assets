package File::Assets::Filter::TestCollect;

use strict;
use warnings;

use base qw/File::Assets::Filter::Collect/;

sub build_content {
    my $self = shift;

    return \"/* Everything is replaced with this! */"
}

1;
