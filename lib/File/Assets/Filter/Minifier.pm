package File::Assets::Filter::Minifier;

use strict;
use warnings;

use base qw/File::Assets::Filter::Collect Class::Data::Inheritable/;
use Carp::Clan qw/^File::Assets/;
use File::Temp;

__PACKAGE__->mk_classdata($_) for qw/_minifier _type/;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->where->{type} = $self->_type;

    return $self;
}

sub build_content {
    my $self = shift;

    my $matched = $self->matched;
    my $asset = $self->asset;
    my $file = $asset->file;

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

    $self->_minifier->($tmp_io, $file_io);

    close $tmp_io or warn $!;
    close $file_io or warn $!;

    return undef; # We already put the content in the asset file, so we return undef here.
}

1;
