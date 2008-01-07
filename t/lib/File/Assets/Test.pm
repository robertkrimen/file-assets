package File::Assets::Test;

use File::Assets;
use Directory::Scratch;

my $scratch;
sub scratch {
    return $scratch ||= do {
        File::Assets::Test::Scratch->new;
    }
}

sub assets {
    return File::Assets->new(base => [ "http://example.com/", scratch->base, "/static" ]);
}

package File::Assets::Test::Scratch;

use base qw/Directory::Scratch/;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_, CLEANUP => 0);
    $self->create_tree({
        map { $_ => "/* Test file: $_ */\n" } qw(static/css/apple.css static/css/banana.css static/js/apple.js),
    });
    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->cleanup;
    $self->SUPER::DESTROY;
}

1;
