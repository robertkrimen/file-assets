package File::Assets;

use warnings;
use strict;

=head1 NAME

File::Assets - Manage .css and .js assets in a web application

=head1 VERSION

Version 0.031

=cut

our $VERSION = '0.031';

=head1 SYNOPSIS

    use File::Assets

    my $assets = File::Assets->new( base => [ $uri_root, $htdocs_root ] );

    $assets->include("/static/style.css"); # File::Assets will automatically detect the type based on the extension

    # Then, later ...
    
    $assets->include("/static/main.js");
    $assets->include("/static/style.css"); # This asset won't get included twice, as File::Assets will ignore repeats of a path

    # And then, in your .tt (Template Toolkit) files:

    [% WRAPPER page.tt %]

    [% assets.include("/static/special-style.css") %]

    # ... finally, in your "main" template:

    [% CLEAR -%]
    <html>

        <head>
            [% assets.export("css") %]
        </head>

        <body>

            [% content %]

            <!-- Generally, you want to include your JavaScript assets at the bottom of your html -->

            [% assets.export("js") %]

        </body>

    </html>

    # If you want to process each asset individually, you can use exports:

    for my $asset ($assets->exports) {

        print $asset->uri, "\n";
    }
    
=head1 DESCRIPTION

File::Assets is a tool for managing JavaScript and CSS assets in a (web) application. It allows you to "publish" assests in one place after having specified them in different parts of the application (e.g. throughout request and template processing phases).

This package has the added bonus of assisting with minification and filtering of assets. Support is built-in for YUI Compressor (L<http://developer.yahoo.com/yui/compressor/>), L<JavaScript::Minifier>, and L<CSS::Minifier>. Filtering is fairly straightforward to implement, so it's a good place to start if need a JavaScript or CSS preprocessor (e.g. something like HAML L<http://haml.hamptoncatlin.com/>)

File::Assets was built with L<Catalyst> in mind, although this package is framework agnostic.

=head1 METHODS

=cut

use strict;
use warnings;

use Tie::LLHash;
use File::Assets::Asset;
use Object::Tiny qw/registry _registry_hash rsc filters output/;
use Path::Resource;
use Scalar::Util qw/blessed refaddr/;
use Carp::Clan qw/^File::Assets::/;

=head2 File::Assets->new( base => <base> )

Create and return a new File::Assets object. <base> can be:
    
* An array (list reference) where <base>[0] is a URI object or uri-like string (e.g. "http://www.example.com")
and <base>[1] is a Path::Class::Dir object or a dir-like string (e.g. "/var/htdocs")

* A L<URI::ToDisk> object

* A L<Path::Resource> object

=cut

sub new {
    my $self = bless {}, shift;
    local %_ = @_;

    my $rsc = File::Assets::Util->parse_rsc($_{rsc} || $_{base_rsc} || $_{base});
    $rsc->uri($_{uri} || $_{base_uri}) if $_{uri} || $_{base_uri};
    $rsc->dir($_{dir} || $_{base_dir}) if $_{dir} || $_{base_dir};
    $rsc->path($_{base_path}) if $_{base_path};
    $self->{rsc} = $rsc;

    my %registry;
    $self->{registry} = tie(%registry, qw/Tie::LLHash/, { lazy => 1 });
    $self->{_registry_hash} = \%registry;

    $self->{filters} = [];

    $self->{name} = $_{name};
    $self->{output} = $_{output};

    return $self;
}

=head2 $asset = $assets->include(<path>, [ <rank>, <type> ])

=head2 $asset = $assets->include_path(<path>, [ <rank>, <type> ])

Include an asset located at "<base.dir>/<path>" for processing. The asset will be exported as "<base.uri>/<path>".

Optionally, you can specify a rank, where a lower number (i.e. -2, -100) causes the asset to appear earlier in the exports
list, and a higher number (i.e. 6, 39) causes the asset to appear later in the exports list. By default, all assets start out
with a neutral rank of 0.

Also, optionally, you can specify a type override as the third argument.

Returns the newly created asset.

=cut

sub include {
    my $self = shift;
    return $self->include_path(@_);
}

sub include_path {
    my $self = shift;
    my $path = shift;
    my $rank = shift;
    my $type = shift;

    croak "Don't have a path to include" unless defined $path && length $path;

    return $self->fetch($path) if $self->exists($path);

    my $asset = File::Assets::Util->parse_asset_by_path(path => $path, type => $type, rank => $rank, base => $self->rsc);

    $self->store($asset);

    return $asset;
}

=head2 $html = $assets->export([ <type> ])

Generate and return HTML for the assets of <type>. If no type is specified, then assets of every type are exported.

$html will be something like this:

    <link rel="stylesheet" type="text/css" href="http://example.com/assets.css">
    <script src="http://example.com/assets.js" type="text/javascript"></script>

=cut

sub export {
    my $self = shift;
    my $type = shift;
    my $format = shift;
    $format = "html" unless defined $format;
    my @assets = $self->exports($type);

    if ($format eq "html") {
        return $self->_export_html(\@assets);
    }
    else {
        croak "Don't know how to export for format ($format)";
    }
}

sub _export_html {
    my $self = shift;
    my $assets = shift;

    my $html = "";
    for my $asset (@$assets) {
        if ($asset->type->type eq "text/css") {
            $html .= <<_END_;
<link rel="stylesheet" type="text/css" href="@{[ $asset->uri ]}" />
_END_
        }
        elsif ($asset->type->type eq "application/javascript" ||
                $asset->type->type eq "application/x-javascript" || # Handle different MIME::Types versions.
                $asset->type->type =~ m/\bjavascript\b/) {
            $html .= <<_END_;
<script src="@{[ $asset->uri ]}" type="text/javascript"></script>
_END_
        }

        else {
            $html .= <<_END_;
<link type="@{[ $asset->type->type ]}" href="@{[ $asset->uri ]}" />
_END_
        }
    }
    return $html;
}

=head2 @assets = $assets->exports([ <type> ])

Returns a list of assets, in ranking order, that are exported. If no type is specified, then assets of every type are exported.

You can use this method to generate your own HTML, if necessary.

=cut

sub exports {
    my $self = shift;
    my @assets = sort { $a->rank <=> $b->rank } $self->_exports(@_);
    $self->_filter(\@assets);
    return @assets;
}

=head2 $assets->empty

Returns 1 if no assets have been included yet, 0 otherwise.

=cut

sub empty {
    my $self = shift;
    return keys %{ $self->_registry_hash } ? 0 : 1;
}

=head2 $assets->exists( <path> )

Returns true if <path> has been included, 0 otherwise.

=cut

sub exists {
    my $self = shift;
    my $path = shift;

    return exists $self->_registry_hash->{$path} ? 1 : 0;
}

=head2 $assets->store( <asset> )

Store <asset> in $assets

=cut

sub store {
    my $self = shift;
    my $asset = shift;

    $self->_registry_hash->{$asset->path} = $asset;
}

=head2 $asset = $assets->fetch( <path> )

Fetch the asset located at <path>

Returns undef if nothing at <path> exists yet.

=cut

sub fetch {
    my $self = shift;
    my $path = shift;

    return $self->_registry_hash->{$path};
}

=head2 $name = $assets->name([ <name> ])

The name of the assets, by default it iss "assets".

=cut

sub name {
    my $self = shift;
    $self->{name} = shift if @_;
    my $name = $self->{name};
    return defined $name && length $name ? $name : "assets";
}

sub _exports {
    my $self = shift;
    my $type = shift;
    $type = File::Assets::Util->parse_type($type);
    my $hash = $self->_registry_hash;
    return values %$hash unless defined $type;
    return grep { $type->type eq $_->type->type } values %$hash;
}

sub filter {
    my $self = shift;
    my $_filter = shift;
    croak "Couldn't find filter for ($_filter)"  unless my $filter = File::Assets::Util->parse_filter($_filter, @_, assets => $self);
    push @{ $self->filters }, $filter;
    return $filter;
}

sub filter_clear {
    my $self = shift;
    if (@_) {
        local %_ = @_;
        if ($_{type}) {
            my $type = File::Assets::Util->parse_type($_{type}) or croak "Don't know type ($_{type})";
            for my $filter (@{ $self->filters }) {
                $filter->remove if $filter->type && $filter->type->type eq $type->type;
            }
        }
        if ($_{filter}) {
            my $filter = ref $_{filter} ? refaddr $_{filter} : $_{filter};
            my @filters = grep { $filter ne refaddr $_ } @{ $self->filters };
            $self->{filters} = \@filters;
        }
    }
    else {
        $self->{filters} = [];
    }
}

sub _filter {
    my $self = shift;
    my $assets = shift;
    for my $filter (@{ $self->filters }) {
        $filter->filter($assets);
    }
}

1;

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-assets at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Assets>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Assets


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Assets>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Assets>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Assets>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Assets>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Robert Krimen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of File::Assets
