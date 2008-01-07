package File::Assets::Filter;

use strict;
use warnings;

use Object::Tiny qw/cfg assets where/;
use Digest;
use Scalar::Util qw/weaken/;
use Carp::Clan qw/^File::Assets/;

my %default = (qw/
    /,
    output => undef,
);

sub new_parse {
    my $class = shift;
    return unless my $filter = shift;

    my $kind = lc $class;
    $kind =~ s/^File::Assets::Filter:://i;
    $kind =~ s/::/-/g;

    my %cfg;
    if (ref $filter eq "") {
        my $cfg = $filter;
        return unless $cfg =~ s/^\s*$kind(?:\s*$|:([^:]))//i;
        $cfg = "$1$cfg" if defined $1;
        %cfg = $class->new_parse_cfg($cfg);
        if (ref $_[0] eq "HASH") {
            %cfg = (%cfg, %{ $_[0] });
            shift;
        }
        elsif (ref $_[0] eq "ARRAY") {
            %cfg = (%cfg, @{ $_[0] });
            shift;
        }
    }
    elsif (ref $filter eq "ARRAY") {
        return unless $filter->[0] && $filter->[0] =~ m/^\s*$kind\s*$/i;
        my @cfg = @$filter;
        shift @cfg;
        %cfg = @cfg;
    }

    return $class->new(%cfg, @_);
}

sub new_parse_cfg {
    my $class = shift;
    my $cfg = shift;
    $cfg = "" unless defined $cfg;
    my %cfg;
    %cfg = map { my @itm = split m/=/, $_, 2; $itm[0], $itm[1] } split m/;/, $cfg;
    $cfg{__cfg__} = $cfg;
    return %cfg;
}

sub new {
    my $class = shift;
    my $self = $class->SUPER::new;
    local %_ = @_;

    $self->{assets} = $_{assets};
    weaken $self->{assets};

    my $where = $_{where};
    if ($_{type}) {
        croak "You specified a type AND a where clause" if $where;
        $where = {
            type => $_{type},
        };
    }
    if (defined (my $type = $where->{type})) {
        $where->{type} = File::Assets::Util->parse_type($_{type}) or croak "Don't know the type ($type)";
    }
    if (defined (my $path = $where->{path})) {
        if (ref $path eq "CODE") {
        }
        elsif (ref $path eq "Regex") {
            $where->{path} = sub {
                return defined $_ && $_ =~ $path;
            };
        }
        elsif (! ref $path) {
            $where->{path} = sub {
                return defined $_ && $_ eq $path;
            };
        }
        else {
            croak "Don't know what to do with where path ($path)";
        }
    }
    $self->{where} = $where;
    $self->{cfg} = {};

    while (my ($setting, $value) = each %default) {
        $self->cfg->{$setting} = exists $_{$setting} ? $_{$setting} : $value;
    }

    return $self;
}

sub stash {
    return shift->{stash} ||= {};
}

sub type {
    return shift->where->{type};
}

sub output {
    return shift->cfg->{output};
}

sub begin {
    my $self = shift;
    my $assets = shift;

    $self->stash->{assets} = $assets;
    $self->stash->{digester} = File::Assets::Util->digest;
    $self->stash->{mtime} = 0;
}

sub end {
    my $self = shift;
    delete $self->{stash};
}

sub filter {
    my $self = shift;
    my $assets = shift;

    $self->begin($assets);

    return unless $self->pre($assets);

    my @matched;
    $self->stash->{matched} = \@matched;

    my $digester = $self->{stash}->{digester};

    my $count = 0;
    for (my $rank = 0; $rank < @$assets; $rank++) {
        my $asset = $assets->[$rank];

        next unless $self->_match($asset);

        $count = $count + 1;
        push @matched, { asset => $asset, rank => $rank, count => $count };

        $digester->add($asset->digest."\n");

        my $asset_mtime = $asset->mtime;
        $self->stash->{mtime} = $asset_mtime if $asset_mtime >= $self->mtime;

        $self->process($asset, $rank, $count, scalar @$assets, $assets);
    }
    $self->stash->{digest} = $digester->hexdigest;

    $self->post($assets, \@matched);

    $self->end($assets, \@matched);
}

sub matched {
    my $self = shift;
    return $self->stash->{matched};
}

sub digest {
    my $self = shift;
    return $self->stash->{digest};
}

sub mtime {
    my $self = shift;
    return $self->stash->{mtime};
}

sub _match {
    my $self = shift;
    my $asset = shift;

    return $self->match($asset, 0) if $self->where->{type} && $self->where->{type}->type ne $asset->type->type;

    my $code;
    if ($code = $self->where->{path}) {
        local $_ = $asset->path;
        return $self->match($asset, 0) if $code->($_, $asset, $self);
    }

    if ($code = $self->where->{code}) {
        return $self->match($asset, 0) if $code->($asset, $self);
    }

    return $self->match($asset, 1);
}

sub match {
    my $self = shift;
    my $asset = shift;
    my $match = shift;
    return $match ? 1 : 0;
}

sub pre {
    return 1;
}

sub process {
}

sub post {
    return 1;
}

sub remove {
    my $self = shift;
    $self->assets->filter_clear(filter => $self);
}

1;
