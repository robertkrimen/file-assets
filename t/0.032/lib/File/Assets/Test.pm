package File::Assets::Test;

use File::Assets;
use Directory::Scratch;
use Test::Memory::Cycle;

my $scratch;
sub scratch {
    return $scratch ||= do {
        File::Assets::Test::Scratch->new;
    }
}

my $assets;
sub assets {
    memory_cycle_ok($assets) if $assets;
    return $assets = File::Assets->new(base => [ "http://example.com/", scratch->base, "/static" ]);
}

END {
    memory_cycle_ok($assets);
}

package File::Assets::Test::Scratch;

use base qw/Directory::Scratch/;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_, CLEANUP => 0);
    $self->create_tree({
        (map { $_ => "/* Test file: $_ */\n" } qw(static/css/apple.css static/css/banana.css static/js/apple.js)),
        'static/css/cherry.css' => <<_END_,
div.cherry {
    font-weight: bold;
    /* Some comment */
    font-weight: 100;
    border: 1px solid #aaaaaa;
}

div.cherry em {
    color: red;
}
_END_
        
        'static/js/cherry.js' => <<_END_,
(function(){
    alert("Nothing happens.");

    var cherry = 1 + 2;

    /* Nothing happens */
    return function(alpha, beta, delta) {
        return alpha + beta + delta;
    } 

}());
_END_
    });

    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->cleanup;
    $self->SUPER::DESTROY;
}

1;
