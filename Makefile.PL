#!/usr/bin/perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'Games::Chess::Coverage',
    VERSION_FROM => 'lib/Games/Chess/Coverage.pm',
    ($] >= 5.005
        ? (ABSTRACT_FROM => 'lib/Games/Chess/Coverage.pm',
           AUTHOR => 'Gene Boggs <gene@cpan.org>')
        : ()
    ),
);
