use inc::Module::Install;

name     'File-Assets';
all_from 'lib/File/Assets.pm';
author   'Robert Krimen <rkrimen@cpan.org>';
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

