package File::Assets::Filter::YUICompressor;

use strict;
use warnings;

use base qw/File::Assets::Filter::Collect/;
use Carp::Clan qw/^File::Assets/;

my %default = (qw/
        java java
    /,
    jar => undef,
    opt => "",
);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    local %_ = @_;
    # TODO $self->parse_cfg(\%default, \%_);
    while (my ($setting, $value) = each %default) {
        $self->cfg->{$setting} = exists $_{$setting} ? $_{$setting} : $value;
    }
    $self->cfg->{jar} or croak "You need to specify the location of the YUI Compressor jar file (something like \"yuicompressor-?.?.?.jar\")";
    -f $self->cfg->{jar} && -r _ or croak "Doesn't exist/can't read: ", $self->cfg->{jar};
#    -f $self->cfg->{java} && -x _ or croak "Doesn't exist/can't execute: ", $self->cfg->{java};
    return $self;
}

sub build_content {
    my $self = shift;

    my $matched = $self->matched;
    my $asset = $self->asset;
    my $file = $asset->file;
    my $extension = ($asset->type->extensions)[0];

    my $java = $self->cfg->{java};
    my $jar = $self->cfg->{jar};
    my $opt = $self->cfg->{opt};

    open my $yc_io, "| $java -jar $jar --type $extension $opt > $file" or die $!;
    for my $match (@$matched) {
        my $asset = $match->{asset};
        print $yc_io ${ $asset->content };
    }
    close $yc_io or warn $!;

    # TODO Fallback to concat if it doesn't work

    return undef; # We (the jar) already put the content in the asset file, so we return undef here.
}

1;
