use inc::Module::Install;

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

recommends 'JavaScript::Minifier';
recommends 'CSS::Minifier';

auto_install;

WriteAll;

