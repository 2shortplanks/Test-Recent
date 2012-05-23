use inc::Module::Install;

name           'Test-Recent';
all_from       'lib/Test/Recent.pm';

# any version of DBI will do, I guess...?
requires       'DateTime'                 => 0;
requires       'DateTimeX::Easy'          => 0;
requires       'Time::Duration::Parse'    => 0;
requires       'Test::Builder'            => 0;

# T::B::T before 0.09 breaks with modern perls
build_requires 'Test::Builder::Tester'    => 0.09;
build_requires 'Test::MockTime'           => 0;

license 'perl';
githubmeta;
author_tests('xt');

WriteAll;
