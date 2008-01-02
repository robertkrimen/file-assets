package File::Assets::Filter;

use strict;
use warnings;

use Object::Tiny qw/cfg group where stash/;
use Digest;
use Scalar::Util qw/weaken/;
use Carp::Clan qw/^File::Assets/;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new;
    local %_ = @_;

    $self->{group} = $_{group};
    weaken $self->{group};

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
    return $self;
}

sub type {
    return shift->where->{type};
}

sub begin {
    my $self = shift;
    my $assets = shift;

    $self->{stash} = {
        assets => $assets,
        digester => File::Assets::Util->digest,
        mtime => 0,
    };
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

sub assets {
    my $self = shift;
    return $self->stash->{assets};
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
    $self->group->filter_clear(filter => $self);
}

1;
