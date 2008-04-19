use inc::Module::Install 0.64;

use 5.008001; 
perl_version '5.8.1';

name     'File-Assets';
all_from 'lib/File/Assets.pm';
author   'Robert Krimen <rkrimen@cpan.org>';

build_requires 'Test::More';
build_requires 'Test::Memory::Cycle';
build_requires 'Directory::Scratch';

requires 'MIME::Types';
requires 'Module::Pluggable';
requires 'Path::Resource';
requires 'Scalar::Util';
requires 'Tie::LLHash';
requires 'Digest';
requires 'Carp::Clan';
requires 'Object::Tiny';
requires 'Class::Data::Inheritable';
requires 'HTML::Declare';
requires 'XML::Tiny';
requires 'IO::Scalar';

recommends 'JavaScript::Minifier';
recommends 'CSS::Minifier';

auto_install;

WriteAll;

