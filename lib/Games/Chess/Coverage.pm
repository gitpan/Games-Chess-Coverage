# $Id: Coverage.pm,v 1.18 2004/05/14 05:39:25 gene Exp $

package Games::Chess::Coverage;
$VERSION = '0.0102';
use strict;
use warnings;
use Carp;
use Games::Chess qw( :constants :functions );

sub new {  # {{{
    my( $class, %args ) = @_;
    my $self = {
        verbose => 0,
        # The width of the chessboard
        size => 7,
        # A Games::Chess::Position object.
        game => undef,
        # Usually this is FEN.
        fen => undef,
        # The piece name keyed rules for how to update the cells list.
        rules  => undef,
        states => undef,
        pieces => undef,
        piece_names => [qw( bishop king knight pawn queen rook )],
        %args,  # Add arbitrary settings on creation
    };
    bless $self, $class;
    $self->_init;
    return $self;
}  # }}}

# Set the game and piece rules.
sub _init {  # {{{
    my $self = shift;

    # Create a new game if we are handed a FEN notation string.  If 
    # neither a game object nor notation are given, G:C:P sets the
    # default game.
    $self->{game} = Games::Chess::Position->new( $self->{fen} )
        if $self->{fen} or not( $self->{game} );
    warn "Game initialized: $self->{game}\n" if $self->{verbose};

    # Set the callback for each piece name if one exists in the
    # package.
    $self->{rules} = {
        map { $_ => __PACKAGE__->can( $_ ) && \&{ $_ } }
            @{ $self->{piece_names} }
    };
    warn 'Rules initialized: ',
        join( ', ', keys %{ $self->{rules} } ), "\n"
        if $self->{verbose};
}  # }}}

sub game { return shift->{game} }

# Return a hash reference of pieces keyed by locations.
sub pieces {  # {{{
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
}  # }}}

# Return a hash reference of cell states keyed by location and color.
sub states {  # {{{
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
}  # }}}

# Execute the callback subroutine for the given piece.
sub cover {  # {{{
    my( $self, $loc, $p ) = @_;
    my $callback = $self->{rules}{ $p->piece_name } || 0;
    warn sprintf "Where: %s, Who: %s, How: %s\n",
        $loc, $p, $callback if $self->{verbose};
    $callback->( $self, $loc ) if $callback;
}  # }}}

# The deceptively lowly pawn.
sub pawn {  # {{{
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
}  # }}}

sub rook {  # {{{
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
}  # }}}

sub bishop {  # {{{
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
}  # }}}

sub queen {  # {{{
    return rook( @_ ), bishop( @_ );
}  # }}}

sub knight {  # {{{
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
}  # }}}

sub king {  # {{{
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
}  # }}}

# Add cell metadata to the cells array if we can move to that location.
sub _update_cells {  # {{{
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

    # En passant and castling are treated separately.
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
}  # }}}

# Return the position occupancy status.
sub whoami {  # {{{
    my( $self, $location ) = @_;
    my $p = $self->pieces->{$location} || 0;
    return sprintf "%s at %s",
        ( $p ? $p->colour_name.' '.$p->piece_name : 'empty' ),
        $location;
}  # }}}

sub piece_vector {  # {{{
    my( $self, $location ) = @_;

    # Who are we?
    my $piece = $self->pieces->{$location} ||
        croak "Can't call pawn() for $location with no location occupant.";

    warn 'Me: ', $self->whoami( $location ), "\n" if $self->{verbose};

    # The direction of movement depends on our color.
    my $direction = $piece->colour eq WHITE ? 1 : -1;

    # Get the coordinate in a form we can do math on.
    my ( $x, $y ) = split //, $location;

    return $piece, $x, $y, $direction;
}  # }}}

#
sub tension {  # {{{
}  # }}}

1;

__END__

=head1 NAME

Games::Chess::Coverage - Expose the potential energy states of a chess game

=head1 SYNOPSIS

  use Games::Chess::Coverage;

  $g = Games::Chess::Coverage->new;
  $g = Games::Chess::Coverage->new( fen => $fen_string );
  $g = Games::Chess::Coverage->new( game => $games_chess_object );

  $pieces = $g->pieces;
  $states = $g->states;

=head1 DESCRIPTION

A I<Games::Chess::Coverage> object represents a chess game in terms of 
move and capture states by location.

A piece's coverage extends within its limit of mobility or until a
collision occurs with another piece.

In my mind this module:

=over 4

=item * Is a chess analysis laboratory

=item * Measures potential energy

=item * Represents tension as a landscape

=item * Shows footprint interference patterns (trends?)

=item * Delineates power stuggle

=item * Looks cool when visualized  :-)

=back

B<Note:> This is not a chess playing module.  It simply returns the 
state of a chess board.  If you want to know what the coverage might 
be in say five ply, you must generate the FEN (or C<Games::Chess> 
object) first.  Please see L</TO DO> for more details.

=head1 PUBLIC METHODS

=head2 CONSTRUCTOR

=over 4

=item * new

  $g = Games::Chess::Coverage->new( %attributes );

Create a new I<Games::Chess::Coverage> object based on the following 
optional attributes provided to the constructor as named parameters:

  Key      Default
  ________________
  verbose => 0
  game => new Games::Chess::Position
  fen => rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1

That is, calling the constructor with no arguments creates a new 
C<Games::Chess> object with the traditional starting board position.

=back

=head2 ACCESSORS

=over 4

=item * pieces

  $pieces = $g->pieces;

This method returns a hash reference of the game coverage object's 
C<Games::Chess::Piece>'s keyed by their location.

=item * states

  $states = $g->states;

This method returns a hash reference of board location states.

=back

=head2 CONVENIENCE METHODS

=over 4

=item * warp_spacetime

  $g->warp_spacetime( $manifold );

Warp local space-time.

=back

=head1 EXAMPLES

Coming soon to a theatre near you...

Until then, take a look at the eg directory in this distribution.

=head1 TO DO

Represent pawn promotion.

Make this tiny and fast with bit vector matrix calculations.

Use C<Chess::PGN::Filter> and build a list of coverages for entire 
games in PGN.

Output ChessGML.

=head1 SEE ALSO

L<Games::Chess>

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
