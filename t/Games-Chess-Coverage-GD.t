BEGIN {
    use strict;
    use warnings;
    use Test::More 'no_plan';
}

SKIP: {                                                                          
    eval { require GD };                                               
    skip "GD not installed", 1 if $@;                                  

    use_ok 'Games::Chess::Coverage::GD';

    # Can we create a default object?
    my $obj = eval {
        Games::Chess::Coverage::GD->new(
            debug => 1,
        );
    };
    print $@ if $@;
    isa_ok $obj, 'Games::Chess::Coverage::GD',
        'Instance created with no arguments';

    #eval{ $obj->add_rule };
    #print $@ if $@;
    #like $@, qr/no class/, 'no class';

    #my $res = eval{ $obj->add_rule( 'bogus' ) };
    #print $@ if $@;
    #ok !$res, 'bogus class';

    eval{ $obj->draw };
    print $@ if $@;
    ok !$@, 'draw nothing';

    #eval{ $obj->write };
    #print $@ if $@;
    #like $@, qr/No image/, 'write nothing';
}
