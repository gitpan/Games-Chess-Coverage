use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Games::Chess::Coverage',
    VERSION_FROM => 'lib/Games/Chess/Coverage.pm',
    PREREQ_PM => {
        'Games::Chess' => 0,
    },
    ($] >= 5.005
        ? (ABSTRACT_FROM => 'lib/Games/Chess/Coverage.pm',
           AUTHOR => 'Gene Boggs <gene@cpan.org>')
        : ()
    ),
);
