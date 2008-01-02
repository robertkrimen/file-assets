package File::Assets::Util;

use strict;
use warnings;

use MIME::Types();
use Scalar::Util qw/blessed/;
use Module::Pluggable search_path => q/File::Assets::Filter/, require => 1, sub_name => q/filter_load/;
__PACKAGE__->filter_load();
use Carp::Clan qw/^File::Assets/;
use Digest;

{
    my $types = MIME::Types->new;
    sub types {
        return $types;
    }
}

sub digest {
    return Digest->new("MD5");
}

sub parse_name {
    my $class = shift;
    my $name = shift;
    $name = "" unless defined $name;
    $name = $name."";
    return undef unless length $name;
    return $name;
}

sub parse_type {
    my $class = shift;
    my $type = shift;
    return unless defined $type;
    return $type if blessed $type && $type->isa("MIME::Type");
    $type = ".$type" if $type !~ m/\W+/;
    # Make sure we get stringified version of $type, whatever it is
    return $class->types->mimeTypeOf($type."");
}

sub parse_rsc {
    my $class = shift;
    my $resource = shift;
    my ($uri, $dir) = @_;
    if (ref $resource eq "ARRAY") {
        ($uri, $dir) = @$resource;
    }
    elsif (ref $resource eq "HASH") {
        ($uri, $dir) = @$resource{qw/uri dir/};
    }
    elsif (blessed $resource) {
        if ($resource->isa("Path::Resource")) {
            return $resource->clone;
        }
        # TODO: URI::ToDisk
    }
    return Path::Resource->new(uri => $uri, dir => $dir);
}

sub parse_asset_by_path {
    my $class = shift;
    local %_ = @_;

    return File::Assets::Asset->new(%_);
}

sub parse_asset_by_content {
    croak "Not ready yet"
}

sub parse_filter {
    my $class = shift;
    my $filter = shift;
    my $group = shift;
    my %new = ref $_[0] eq "HASH" ? %{ $_[0] } : @_;
    if ($filter =~ m/\s*concat\s*/i) {
        return File::Assets::Filter::Concat->new(group => $group, %new);
    }
    elsif ($filter =~ m/\s*yuicompressor\s*/i) {
        return File::Assets::Filter::YUICompressor->new(group => $group, %new);
    }
}

sub build_asset_path {
    my $class = shift;
    my $path_template = shift;

    return $$path_template if ref $path_template eq "SCALAR";

    local %_ = @_;

    $path_template = "%d.%e" unless $path_template;
    $path_template .= ".%e" if $path_template =~ m/(?:^|\/)[^.]+$/;
    my $type = $_{type};
    my $extension;
    $extension = ($type->extensions)[0];
    $path_template =~ s/%e/$extension/g;
    $path_template =~ s/%D/$_{content_digest}/g if $_{content_digest};
    $path_template =~ s/%d/$_{digest}/g if $_{digest};
    $path_template =~ s/%n/$_{name}/g if $_{name};
    $path_template =~ s/%%/%/g;
    
    return $path_template;
}

1;
