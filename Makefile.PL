#!/usr/bin/perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $modules = optional_modules();
#use Data::Dumper;die Dumper($modules);

WriteMakefile(
    NAME => 'Games::Chess::Coverage',
    VERSION_FROM => 'lib/Games/Chess/Coverage.pm',
    PREREQ_PM => {
        'Games::Chess' => 0,  # XXX This mandates GD - yikes :(
        'Chess::PGN::Filter' => 0.13,
        %$modules,
    },
    ($] >= 5.005
        ? (ABSTRACT_FROM => 'lib/Games/Chess/Coverage.pm',
           AUTHOR => 'Gene Boggs <gene@cpan.org>')
        : ()
    ),
);

# This subroutine was initially stolen from the TT Makefile.PL. :)
sub optional_modules {
    print <<'EOF';
###########################################################
# Chess-Coverage can use plugin modules for visualization.
# All the plugin code will be installed but tests requiring
# modules not available will be skipped.
# Checking for installed modules...

EOF

    my @modules = qw( GD Imager SVG );
    for my $module ( @modules ) {
        printf '  %-7s', $module;
        eval "use $module";
        if( $@ ) {
            print '[ ] module not installed';
        }
        else {
            no strict 'refs';
            my $version = ${ "$module\::VERSION" };
            print "[X] version $version installed";
        }
        print "\n";
    }
    print "\n";

    my $modules = {};
    for my $module ( @modules ) {
        eval "use $module";
        if( $@ ) {
            my $value = prompt(
                "Require $module for plugin support?",
                'no'
            );
            $modules->{$module} = 0 if $value =~ /^y/i;
        }
    }

    return $modules;
}
