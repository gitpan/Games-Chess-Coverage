BEGIN {
    use strict;
    use warnings;
    use Data::Dumper;
    $Data::Dumper::Terse = $Data::Dumper::Indent = 1;
    use Test::More 'no_plan';#tests => 1;
    use_ok 'Games::Chess::Coverage';
}

# Can we create a default object?
my $obj = eval {
    Games::Chess::Coverage->new(
#        verbose => 1,
    );
};
print $@ if $@;
isa_ok $obj, 'Games::Chess::Coverage',
    'Instance created with no arguments';

#warn Dumper( $obj->{cells} );
#warn Dumper([sort keys %{$obj->pieces}]);
#warn Dumper($obj->pieces->{'00'});

# Did we create a game object?
isa_ok $obj->game, 'Games::Chess::Position', 'The game attribute';
#print $obj->game->to_text(), "\n";

# Locations that should have pieces.
my @xy = qw(
    07 17 27 37 47 57 67 77
    06 16 26 36 46 56 66 76
    01 11 21 31 41 51 61 71
    00 10 20 30 40 50 60 70
);

for my $loc ( @xy ) {
    # Pseudo-test
    my $who = $obj->whoami( $loc );
    ok $who, $who;

    # Test the piece_vector method.
    my( $piece, $x, $y, $direction ) = $obj->piece_vector( $loc );
    isa_ok $piece, 'Games::Chess::Piece';
    ok $loc eq "$x$y", "Location parsed as $x, $y";
    ok $direction == (
        ( split //, $loc )[1] <= 1 ? 1 : -1
    ), "Direction computed as $direction";
}

# "No location is without an occupant."
ok( not( grep { not $obj->pieces->{$_} } @xy ),
    'Pieces defined at valid locations' );

# Locations that should be empty.
@xy = qw(
    05 15 25 35 45 55 65 75
    04 14 24 34 44 54 64 74
    03 13 23 33 43 53 63 73
    02 12 22 32 42 52 62 72
);

# "Empty squares have no occupant."
ok( ( grep { not $obj->pieces->{$_} } @xy ),
    'Empty squares at valid locations' );

# G.I.G.O.
@xy = qw( 09 1a 2- 3 .4 hh 69 777 );
ok( ( grep { not $obj->pieces->{$_} } @xy ),
    'No bogus locations' );

# Test PGN handling.
$obj = eval {
    Games::Chess::Coverage->new(
#        verbose => 1,
        pgn => 'eg/sample.pgn',
    );
};
warn $@ if $@;
isa_ok $obj, 'Games::Chess::Coverage', 'with PGN';
$obj->build_game( 0, 0 );
is $obj->{fen},
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    'starting position';
$obj->build_game( 0, 1 );
is $obj->{fen},
    'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3',
    'first ply';
$obj->build_game( 0, -2 );
is $obj->{fen},
    '6R1/2r1bp1n/3N3k/p3P1p1/2p3P1/PbP4P/5B2/4R1K1 w - -',
    'penultimate ply';
$obj->build_game( 0, -1 );
is $obj->{fen},
    '6R1/2r1bN1n/7k/p3P1p1/2p3P1/PbP4P/5B2/4R1K1 b - -',
    'last ply';
$obj->build_game( 0, 1000 );
is $obj->{fen}, undef, 'not a ply';
