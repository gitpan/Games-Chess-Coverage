BEGIN {
    use strict;
    use warnings;
    use Test::More 'no_plan';
    use_ok 'Games::Chess::Coverage::Imager';
}

# Can we create a default object?
my $obj = eval {
    Games::Chess::Coverage::Imager->new(
#        debug => 1,
    );
};
print $@ if $@;
isa_ok $obj, 'Games::Chess::Coverage::Imager',
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
