BEGIN {
    use strict;
    use warnings;
    use Test::More 'no_plan';
}

SKIP: {
    eval { require SVG };
    skip "SVG not installed", 1 if $@;

    use_ok 'Games::Chess::Coverage::SVG';

    # Can we create a default object?
    my $obj = eval {
        Games::Chess::Coverage::SVG->new(
#            verbose => 1,
        );
    };
    print $@ if $@;
    isa_ok $obj, 'Games::Chess::Coverage::SVG',
        'with no arguments';

    eval{ $obj->draw };
    print $@ if $@;
    ok !$@, 'draw nothing';
}
