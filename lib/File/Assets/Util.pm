package File::Assets::Util;

use strict;
use warnings;

use MIME::Types();
use Scalar::Util qw/blessed/;
use Module::Pluggable search_path => q/File::Assets::Filter/, require => 1, sub_name => q/filter_load/;
my @filters = reverse sort  __PACKAGE__->filter_load();
use Carp::Clan qw/^File::Assets/;
use Digest;

{
    my $types;
    sub types {
        return $types ||= MIME::Types->new(only_complete => 1);
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
    my ($uri, $dir, $path) = @_;
    if (ref $resource eq "ARRAY") {
        ($uri, $dir, $path) = @$resource;
    }
    elsif (ref $resource eq "HASH") {
        ($uri, $dir, $path) = @$resource{qw/uri dir path/};
    }
    elsif (blessed $resource) {
        if ($resource->isa("Path::Resource")) {
            return $resource->clone;
        }
        # TODO: URI::ToDisk
    }
    return Path::Resource->new(uri => $uri, dir => $dir, path => $path);
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

    my $_filter;
    for my $possible (@filters) {
        last if $_filter = $possible->new_parse($filter, @_);
    }

    return $_filter;
#    my $group = shift;
#    my %new = ref $_[0] eq "HASH" ? %{ $_[0] } : @_;
#    if ($filter =~ m/\s*concat\s*/i) {
#        return File::Assets::Filter::Concat->new(group => $group, %new);
#    }
#    elsif ($filter =~ m/\s*yuicompressor\s*/i) {
#        return File::Assets::Filter::YUICompressor->new(group => $group, %new);
#    }
}

sub build_asset_path {
    my $class = shift;
    my $output = shift;

    return $$output if ref $output eq "SCALAR";

    local %_ = @_;

    my $assets = $_{assets};
    my $filter = $_{filter};

    $output = $filter->output unless defined $output;
    $output = $assets->output unless defined $assets;

    return $$output if ref $output eq "SCALAR";

#   TODO Maybe we should put this here, maybe not
#    if ($output =~ m/^\//) {
#    }
#    elsif ($assets) {
#        $output = $assets->path->child($output);
#    }

    $output = "%n.%e" unless $output;
    $output .= "%n.%e" if $output && $output =~ m/\/$/;
    $output .= ".%e" if $output =~ m/(?:^|\/)[^.]+$/;
    my $type = $_{type};
    my $extension;
    $extension = ($type->extensions)[0] if defined $type;
    $output =~ s/%e/$extension/g if defined $extension;
    $output =~ s/%D/$_{content_digest}/g if $_{content_digest};
    $output =~ s/%d/$_{digest}/g if $_{digest};
    $output =~ s/%n/$_{name}/g if $_{name};

    $output =~ m/(?<!%)%[eDdn]/ and croak "Unmatched substitution in output pattern ($output)";

    $output =~ s/%%/%/g;

    return $output;
}

1;
