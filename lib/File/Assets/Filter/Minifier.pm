package File::Assets::Filter::Minifier;

use strict;
use warnings;

use base qw/File::Assets::Filter::Collect Class::Data::Inheritable/;
BEGIN {
    __PACKAGE__->mk_classdata($_) for qw/_minifier/;
}
use Carp::Clan qw/^File::Assets/;
use File::Temp;
use File::Assets::Filter::Minifier::CSS;
use File::Assets::Filter::Minifier::JavaScript;

sub signature {
    return "minifier";
}

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    return $self;
}

sub build_content {
    my $self = shift;

    my $matched = $self->matched;
    my $output_asset = $self->output_asset;
    my $file = $output_asset->file;

    $file->parent->mkpath unless -d $file->parent;

    my $tmp_io = File::Temp->new;
    for my $match (@$matched) {
        my $asset = $match->{asset};
        my $asset_io = $asset->file->openr or die $!;
        $tmp_io->print($_) while <$asset_io>;
        $tmp_io->print("\n");
        close $asset_io or warn $!;
    }
    $tmp_io->flush;

    my $file_io = $file->openw or die $!;
    seek $tmp_io, 0, 0;

    my $minifier = $self->minifier;
    $minifier->($tmp_io, $file_io);

    close $tmp_io or warn $!;
    close $file_io or warn $!;

    return undef; # We already put the content in the asset file, so we return undef here.
}

sub minifier {
    my $self = shift;
    return $self->stash->{minifier} ||= do {
        my $minifier;
        if ($minifier  = $self->_minifier) {
        }
        else {
            my $kind = $self->kind;
            if ($kind->extension eq "css") {
                $minifier = \&File::Assets::Filter::Minifier::CSS::minify;
            }
            elsif ($kind->extension eq "js") {
                $minifier = \&File::Assets::Filter::Minifier::JavaScript::minify;
            }
            else {
                croak "Don't know how to minify for type ", $kind->type->type, " (", $kind->kind, ")";
            }
        }
        $minifier;
    };
}

1;
