# $Id: Coverage.pm,v 1.23 2004/08/06 03:04:29 gene Exp $

package Games::Chess::Coverage;
$VERSION = 0.0201;
use strict;
use warnings;
use Carp;
use Games::Chess qw( :constants :functions );
use Chess::PGN::Filter;

sub new {
    my( $class, %args ) = @_;
    my $self = {
        verbose => 0,
        piece_names => [qw( bishop king knight pawn queen rook )],
        game_number => 1,  # Number of the PGN game.
        ply_number  => 0,  # Number of the game's ply.
        pgn_dom     => undef,
        fen    => undef,   # Forsythe-Edwards Notation string.
        pgn    => undef,   # Portable Game Notation string or file.
        game   => undef,   # Games::Chess::Position object.
        rules  => undef,   # Defined constraints.
        states => undef,   # Computed board state.
        pieces => undef,   # Location lookup table of G::C::Pieces.
        size   => 7,       # Width of the chessboard.
        %args,             # Add arbitrary settings on creation
    };
    bless $self, $class;
    $self->_init;
    return $self;
}

sub _init {
    my $self = shift;

    $self->build_rules;

    # Create a new game unless we're given one.
    if( $self->{game} ) {
        $self->{fen} = $self->{game}->to_FEN;
        warn "FEN initialized: $self->{fen}\n" if $self->{verbose};
    }
    else {
        $self->build_game;
    }
}

# Build a disptch table of callbacks for each piece.
sub build_rules {
    my $self = shift;

    $self->{rules} = {
        map { $_ => __PACKAGE__->can( $_ ) && \&{ $_ } }
            @{ $self->{piece_names} }
    };
    warn 'Piece movement rules initialized: ',
        join( ', ', sort keys %{ $self->{rules} } ), "\n"
        if $self->{verbose};
}

sub build_game {
    my( $self, $i, $j ) = @_;

    $self->{game_number} = $i if defined $i;
    $self->{ply_number} = $j if defined $j;

    $self->{pgn_dom} = filter(
        source => $self->{pgn},
        filtertype => 'DOM',
        verbose => 0,
    ) if $self->{pgn};
#use Data::Dumper;warn Dumper($self->{pgn_dom});

    $self->{fen} = $self->extract_ply;

    $self->{game} = Games::Chess::Position->new( $self->{fen} );
    warn "Game initialized: $self->{game}\n" if $self->{verbose};
}

# The FEN is deep within a Chess::PGN::Filter DOM.
# Game numbers are 1 .. n and Move numbers are 0 .. m where the
# "zeroth ply" is the API default starting position and the
# -1st, -2nd, etc. array indices work as expected.
sub extract_ply {
    my $self = shift;

    $self->{fen} = $self->{ply_number} && $self->{pgn_dom}
        ? $self->{pgn_dom}[
                $self->{game_number} - ($self->{game_number} < 0 ? 0 : 1)
            ]{Gametext}[
                $self->{ply_number} - ($self->{ply_number} < 0 ? 0 : 1)
            ]{Epd}
        : 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

    warn "FEN: $self->{fen}\n" if $self->{fen} && $self->{verbose};

    return $self->{fen};
}

sub number_of_games {
    my $self = shift;
    return unless $self->{pgn_dom};
    return scalar @{ $self->{pgn_dom} };
}

sub number_of_ply {
    my $self = shift;
    return unless $self->{pgn_dom};
    my $game = shift || $self->{game_number};
    return scalar @{
        $self->{pgn_dom}[ $game - ($game < 0 ? 0 : 1) ]{Gametext}
    };
}

sub game { return shift->{game} }

# Return a hash reference of G-C pieces keyed by locations.
sub pieces {
    my $self = shift;
    my %pieces;

    # Fetch the uncached pieces.
    unless( $self->{pieces} ) {
        for my $rank ( 0 .. $self->{size} ) {
            for my $file ( 0 .. $self->{size} ) {
                my $p = $self->{game}->at( $file, $rank );
                next unless $p->piece;
                warn sprintf "Piece: %s %d, %d\n", $p->name, $file, $rank
                    if $self->{verbose};
                $self->{pieces}{ $file . $rank } = $p;
            }
        }
    }

    return $self->{pieces};
}

# Return a hash reference of cell states keyed by color and location.
sub states {
    my $self = shift;
    # Fetch the uncached pieces.
    unless( $self->{states} ) {
        while( my( $loc, $p ) = each %{ $self->pieces } ) {
            $self->cover( $loc, $p ) if $p->piece != KING;
        }
        # Kings come last since check impedes their movement.
        while( my( $loc, $p ) = each %{ $self->pieces } ) {
            $self->cover( $loc, $p ) if $p->piece == KING;
        }
    }
    return $self->{states};
}

# The deceptively lowly pawn.
sub pawn {
    my( $self, $location ) = @_;
    my( $piece, $x, $y, $direction ) =
        $self->piece_vector( $location );

    # Can we march forward?
    $self->_update_cells(
        location => $location,
        piece => $piece,
        file  => $x,
        rank  => $y + $direction,
        marching => 1,
    );
    # Can we double-step on our first move?
    $self->_update_cells(
        location => $location,
        piece => $piece,
        file  => $x,
        rank  => $y + 2 * $direction,
        marching => 1,
    ) if $y == ( $piece->colour == WHITE ? 1 : $self->{size} - 1 );

    # Can we capture on the diagonals?
    $self->_update_cells(
        location => $location,
        piece => $piece,
        file  => $x + $_,
        rank  => $y + $direction,
    ) for -1, 1;

    # En passant capture?
    $self->_update_cells(
        location => $location,
        piece => $piece,
        file  => $x + $_,
        rank  => $y,
        en_passant => 1,
    ) for -1, 1;
}

sub rook {
    my( $self, $location ) = @_;
    my( $piece, $x, $y ) = $self->piece_vector( $location );

    # We control the horizontal,
    for( reverse 0 .. $x - 1 ) {
        last unless $self->_update_cells(
            location => $location,
            piece => $piece,
            file  => $_,
            rank  => $y,
        );
    }
    for( $x + 1 .. $self->{size} ) {
        last unless $self->_update_cells(
            location => $location,
            piece => $piece,
            file  => $_,
            rank  => $y,
        );
    }
    # ..and the vertical.
    for( reverse 0 .. $y - 1 ) {
        last unless $self->_update_cells(
            location => $location,
            piece => $piece,
            file  => $x,
            rank  => $_,
        );
    }
    for( $y + 1 .. $self->{size} ) {
        last unless $self->_update_cells(
            location => $location,
            piece => $piece,
            file  => $x,
            rank  => $_,
        );
    }
}

sub bishop {
    my( $self, $location ) = @_;
    my( $piece, $x, $y ) = $self->piece_vector( $location );

    # We also control the diagonal (NE/SW),
    for( 1 .. $self->{size} ) {
        last unless $self->_update_cells(
            location => $location,
            piece => $piece,
            file  => $x + $_,
            rank  => $y + $_,
        );
    }
    for ( 1 .. $self->{size} ) {
        last unless $self->_update_cells(
            location => $location,
            piece => $piece,
            file  => $x - $_,
            rank  => $y - $_,
        );
    }
    # and the... other diagonal (NW/SE).
    for( 1 .. $self->{size} ) {
        last unless $self->_update_cells(
            location => $location,
            piece => $piece,
            file  => $x + $_,
            rank  => $y - $_,
        );
    }
    for( 1 .. $self->{size} ) {
        last unless $self->_update_cells(
            location => $location,
            piece => $piece,
            file  => $x - $_,
            rank  => $y + $_,
        );
    }
}

sub queen {
    return rook( @_ ), bishop( @_ );
}

sub knight {
    my( $self, $location ) = @_;
    my( $piece, $x, $y ) = $self->piece_vector( $location );

    # white: NNE, ENE, ESE, SSE, SSW, WSW, WNW, NNW
    $self->_update_cells(
        location => $location,
        piece => $piece,
        file  => $x + $_->[0],
        rank  => $y + $_->[1],
    ) for [ 1, 2], [ 2, 1], [ 2,-1], [ 1,-2],
          [-1,-2], [-2,-1], [-2, 1], [-1, 2];
}

sub king {
    my( $self, $location ) = @_;
    my( $piece, $x, $y ) = $self->piece_vector( $location );

    # white: NNE, ENE, ESE, SSE, SSW, WSW, WNW, NNW
    $self->_update_cells(
        location => $location,
        piece => $piece,
        file  => $x + $_->[0],
        rank  => $y + $_->[1],
    ) for [0, 1], [ 1, 1], [ 1,0], [ 1,-1],
          [0,-1], [-1,-1], [-1,0], [-1, 1];

    # King and Queen side castle
    $self->_update_cells(
        location => $location,
        piece  => $piece,
        file   => $x + $_,
        rank   => $y,
        castle => 1,
    ) for -2, 2;
}

# Execute the callback subroutine for the given piece.
sub cover {
    my( $self, $loc, $p ) = @_;
    my $callback = $self->{rules}{ $p->piece_name } || 0;
    warn sprintf "Where: %s, Who: %s, How: %s\n",
        $loc, $p, $callback
        if $self->{verbose};
    $callback->( $self, $loc ) if $callback;
}

# Add cell metadata to states if we can move-to or attack the given location.
sub _update_cells {
    my( $self, %args ) = @_;
    # self, piece, rank, file, marching, en_passant, castle

    return unless xy_valid( $args{file}, $args{rank} );

    # Set the board location I am going to inspect.
    my $location = $args{file} . $args{rank};
    warn "\tChecking $location\n" if $self->{verbose};

    # Set the additional position if we are en passant or castling.
    my( $x2, $y2 );
    if( $args{en_passant} or $args{castle} ) {
        $x2 = $args{file};
        $y2 = $args{rank} + ( $args{piece}->colour == WHITE ? 1 : -1 );
    }

    # What color is my enemy?
    my $enemy = $args{piece}->colour == WHITE ? 'black' : 'white';

    # Is anyone at the inspection location?
    my $cell = $self->{game}->at( $args{file}, $args{rank} );
    warn 'Cell: ', $self->whoami( $location ), "\n" if $self->{verbose};

    my $state = $self->{states}{$location};

    # A king cannot move into check. 
    my $king_check = $args{piece}->piece == KING &&
        $state && exists $state->{$enemy} &&
        exists $state->{$enemy}{capture} &&
        @{ $state->{$enemy}{capture} }
        ? 1 : 0;

    unless( $args{en_passant} || $args{castle} || $king_check ) {
        # Can I move here?
        push @{
            $self->{states}{$location}{ $args{piece}->colour_name }{move}
        }, $args{location}
        unless
            # I'm a marching pawn and someone's in the way.
            ( $cell->colour != EMPTY && $args{marching} ) ||
            # My teammate is already there.
            ( $cell->colour != EMPTY && $cell->colour_name ne $enemy );

        # Can I possibly capture here?  (This is not the enemy but the
        # square itself.)
        push @{
            $self->{states}{$location}{ $args{piece}->colour_name }{capture}
        }, $args{location}
        unless
            # I'm a marching (not attacking) pawn.
            $args{marching};
    }

    # For bishops and rooks: Stop if someone is in the way.  Keep on
    # keepin' on if not.
    return $cell->colour == EMPTY ? 1 : 0;
}

# Return the position occupancy status.
sub whoami {
    my( $self, $location ) = @_;
    my $p = $self->pieces()->{$location} || 0;
    return sprintf "%s at %s",
        ($p ? $p->colour_name.' '.$p->piece_name : 'empty'),
        $location;
}

sub piece_vector {
    my( $self, $location ) = @_;

    # Who are we?
    my $piece = $self->pieces()->{$location} ||
        croak "Can't get a piece vector for $location without an occupant.";

    # Get the coordinate in a form we can do math on.
    my ( $x, $y ) = split //, $location;

    # The direction of movement depends on our color.
    my $direction = $piece->colour eq WHITE ? 1 : -1;

    warn 'Me: ', $self->whoami( $location ), "\n" if $self->{verbose};

    return $piece, $x, $y, $direction;
}



__END__

=head1 NAME

Games::Chess::Coverage - Expose the potential energy of chess games

=head1 SYNOPSIS

  use Games::Chess::Coverage;

  $g = Games::Chess::Coverage->new;
  $g = Games::Chess::Coverage->new( fen => $fen_string );
  $g = Games::Chess::Coverage->new( game => $games_chess_object );

  $g = Games::Chess::Coverage->new( pgn => $pgn );
  for my $game ( 1 .. $g->number_of_games ) {
      for my $ply ( 0 .. $g->number_of_ply( $game ) ) {
          $g->build_game( $game, $ply );
          # Do something interesting like visualize with $g->pieces
          # and $g->states...
      }
  }

=head1 DESCRIPTION

A I<Games::Chess::Coverage> object represents a chess game in terms of 
move and capture state.

A piece's coverage extends within its limit of mobility or until a
collision occurs with another piece.  This includes the many special
considerations that are part of chess like en passant capture and the
fact that a king can't move into check, etc.

In my mind this module:

=over 4

=item * Is a chess analysis laboratory

=item * Measures potential energy

=item * Represents tension as a landscape

=item * Shows footprint interference patterns and trends

=item * Delineates power stuggle

=item * Looks cool when visualized  :-)

=back

B<Note:> This is not a chess playing module.  It simply returns the 
state of a chess game at a particular moment.  If you want to know
what the coverage might be in say five ply, you must either have the
PGN or generate that slice of the game (in real-time, for instance :).

=head1 PUBLIC METHODS

=over 4

=item * new

  $g = Games::Chess::Coverage->new( %attributes );

Create a new I<Games::Chess::Coverage> object based on the following 
attributes:

  Key     Default
  ________________
  verbose => 0
  fen  => rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
  game => new Games::Chess::Position
  number_of_games => 1
  number_of_ply   => 0

Calling the constructor with no arguments creates a single game with
the traditional starting board position.

=item * pieces

  $pieces = $g->pieces;

This method returns a hash reference of the game coverage object's 
C<Games::Chess::Piece>'s keyed by their location.

=item * states

  $states = $g->states;

This method returns a hash reference of board location states.

A state in the context of this module is ...

=item * number_of_games

  $n = $g->number_of_games;

Return the number of games in the provided PGN.

=item * number_of_ply

  $p = $g->number_of_ply;
  $p = $g->number_of_ply( $n );

Return the number of ply (twice the number of moves) in a given game
from the object's PGN.  If a game number is not provided, the current
object C<game_number> attribute is used.

=item * warp_spacetime

  $g->warp_spacetime( $manifold );

Warp local space-time.

=back

=head1 EXAMPLES

Coming soon to a theatre near you...

Until then, take a look at the eg directory in this distribution.

=head1 TO DO

B<Remove the dependence upon C<Games::Chess>.>

Abstract the cell updating method so that smoother inheritance can
happen.

Document the API extensibility by showing how "user defined" piece
move/capture constraint callbacks may be created.

Make this tiny and fast with bit vector matrix calculations?

=head1 SEE ALSO

L<Games::Chess>

L<Games::Chess::Coverage::Draw>

This is a great site:

C<http://www.chessclub.demon.co.uk/tutorial/beginner/intro/intro.htm>

Of course there is also

C<http://mathworld.wolfram.com/Chess.html>

This is a related (possibly mathematically equivalent) concept:

C<http://www.users.globalnet.co.uk/~perry/maths/chessgraph/chessgraph.htm>

Here is a chess glossary with many analysis terms:

C<http://www.jeremysilman.com/chess_glossary/glossary_chess_terms_a.html>

What document on visualization would be complete without references
to Edward R. Tufte?

C<http://www.edwardtufte.com/bboard/q-and-a-fetch-msg?msg_id=00013l&topic_id=1&topic=Ask%20E%2eT%2e>
and
C<http://www.edwardtufte.com/bboard/q-and-a-fetch-msg?msg_id=0000Mn&topic_id=1&topic=Ask%20E%2eT%2e>

And what chess module about analysis would be complete without a 
reference to the Canon of educational chess games?

C<http://www.ex.ac.uk/~dregis/DR/Canon/canonidx.html>

=head1 DEDICATION

My chess playing Brother, Aaron.  Hi Aaron.  :-)

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, Gene Boggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
