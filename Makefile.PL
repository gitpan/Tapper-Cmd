use strict;
use warnings;

use inc::Module::Install;

name     'Tapper-Cmd';
all_from 'lib/Tapper/Cmd.pm';
author   'AMD OSRC Tapper Team <tapper@amd64.org>';
license  'freebsd';

requires 'perl'                  => '5.010';
requires 'Tapper::Model' => "3.000010";
requires 'Kwalify'               => 0;
requires 'MooseX::Declare'       => 0;
requires 'YAML::Syck'            => "1.17";

build_requires 'Test::More';

author_requires 'Module::Install::WriteAll';

repository 'git://github.com/amd/Tapper-Cmd.git';
bugtracker 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tapper-Cmd';

WriteAll;

