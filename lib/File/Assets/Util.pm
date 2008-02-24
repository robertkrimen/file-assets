package File::Assets::Util;

use strict;
use warnings;

use MIME::Types();
use Scalar::Util qw/blessed/;
use Module::Pluggable search_path => q/File::Assets::Filter/, require => 1, sub_name => q/filter_load/;
my @filters = reverse sort  __PACKAGE__->filter_load();
use Carp::Clan qw/^File::Assets/;
use Digest;
use File::Assets::Asset::File;
use File::Assets::Asset::Content;

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

sub same_type {
    no warnings 'uninitialized';
    my $class = shift;
    my $aa = $class->parse_type($_[0]) or confess "Couldn't parse: $_[0]";
    my $bb = $class->parse_type($_[1]) or confess "Couldn't parse: $_[1]";
    
    return $aa->simplified eq $bb->simplified;
}

sub type_extension {
    my $class = shift;
    my $type = $class->parse_type($_[0]);
    croak "Couldn't parse @_" unless $type;
    return ($type->extensions)[0];
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
        elsif ($resource->isa("URI::ToDisk")) {
            $uri = $resource->URI;
            $dir = $resource->path;
        }
        # TODO: URI::ToDisk
    }
    return Path::Resource->new(uri => $uri, dir => $dir, path => $path);
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

sub build_output_path {
    my $class = shift;
    my $template = shift;
    my $filter = shift;

    my $path = $template->{path};

    return $$path if ref $path eq "SCALAR";

#   TODO Maybe we should put this here, maybe not
#    if ($output =~ m/^\//) {
#    }
#    elsif ($assets) {
#        $output = $assets->path->child($output);
#    }

    $path = "%n%b.%e" unless $path;
    $path .= "%n%b.%e" if $path && $path =~ m/\/$/;
    $path .= ".%e" if $path =~ m/(?:^|\/)[^.]+$/;

    local %_ = (
        content_digest => $filter->content_digest,
        digest => $filter->digest,
        name => $filter->assets->name,
        kind => $filter->kind->kind,
        head => $filter->kind->head,
        tail => $filter->kind->tail,
    );
    my $extension = $filter->kind->extension;
    $path =~ s/%e/$extension/g if defined $extension;
    $path =~ s/%D/$_{content_digest}/g if $_{content_digest};
    $path =~ s/%d/$_{digest}/g if $_{digest};
    $path =~ s/%n/$_{name}/g if $_{name};
    $path =~ s/%k/$_{kind}/g if $_{kind};
    $path =~ s/%h/$_{head}/g if $_{head};
    $_{tail} = "" unless defined $_{tail};
    $path =~ s/%a/$_{tail}/g;
    my $tail = $_{tail};
    $tail = "-$tail" if length $tail;
    $path =~ s/%b/$tail/g;

    $path =~ m/(?<!%)%[D]/ and carp "Unmatched content digest substitution %D in output path pattern ($path)\n" .
                                        "Did you forget to set \"content_digest => 1\" in the filter?";
    $path =~ m/(?<!%)%[eDdnkhab]/ and carp "Unmatched substitution in output path pattern ($path)";

    $path =~ s/%%/%/g;

    return $path;
}

#sub build_asset_path {
#    my $class = shift;
#    my $output = shift;

#    return $$output if ref $output eq "SCALAR";

#    local %_ = @_;

#    my $assets = $_{assets};
#    my $filter = $_{filter};

#    $output = $filter->output unless defined $output;
#    $output = $assets->output unless defined $assets;

#    return $$output if ref $output eq "SCALAR";

##   TODO Maybe we should put this here, maybe not
##    if ($output =~ m/^\//) {
##    }
##    elsif ($assets) {
##        $output = $assets->path->child($output);
##    }

#    $output = "%n.%e" unless $output;
#    $output .= "%n.%e" if $output && $output =~ m/\/$/;
#    $output .= ".%e" if $output =~ m/(?:^|\/)[^.]+$/;
#    my $type = $_{type};
#    my $extension;
#    $extension = ($type->extensions)[0] if defined $type;
#    $output =~ s/%e/$extension/g if defined $extension;
#    $output =~ s/%D/$_{content_digest}/g if $_{content_digest};
#    $output =~ s/%d/$_{digest}/g if $_{digest};
#    $output =~ s/%n/$_{name}/g if $_{name};

#    $output =~ m/(?<!%)%[eDdn]/ and croak "Unmatched substitution in output pattern ($output)";

#    $output =~ s/%%/%/g;

#    return $output;
#}

1;
