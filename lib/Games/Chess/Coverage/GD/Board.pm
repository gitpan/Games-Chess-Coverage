package Games::Chess::Coverage::GD::Board;

$VERSION = '0.01';

use strict;
use warnings;
use Carp;
use GD;

sub Board {
    my( $self, %args ) = @_;

    # Do we care about fonts?
    if( $self->{letters} && !$self->{font} ) {  # {{{
        $self->{font} = GD::Font->Giant;
        UNIVERSAL::isa( $self->{font}, 'GD::Font' ) or
            croak "$self->{font} is not a GD::Font.";
    }  # }}}

    # Color the board.
    $self->{image}->filledRectangle(  # {{{
        0, 0,
        $self->{image_width} - 1, $self->{image_height} - 1,
        $self->{board_color}
    );  # }}}

    # Draw a border around the board.
    # Get thickness by drawing concentric, adjacent rectangles.
    for my $n ( 0 .. $self->{border} - 1 ) {  # {{{
        $self->{image}->rectangle(
            $self->{x0} + $n,
            $n,
            $self->{x1} - $n,
            $self->{y1} - $n,
            $self->{border_color}
        );
    }  # }}}

    # Draw the file letters a-h and the rank numbers 1-8.
    if( $self->{letters} ) {  # {{{
        my( $fw, $fh ) = ( $self->{font}->width, $self->{font}->height );
        my( $left, $bottom ) = (
            $self->{x0} - $fh,
            $self->{y1} + $fw / 2
        );
        for my $n ( 0 .. $self->{max_coord} ) {
            # i.e. inside edge + square size + grid line +
            #      half of the square - half of the font
            my( $file, $rank ) = (
                $self->{x0} + $self->{border} + $n * $self->{square_width}  + $n +
                    $self->{square_width} / 2 - $fw / 2,
                $self->{y0} + $self->{border} + $n * $self->{square_height} + $n +
                    $self->{square_height} / 2 - $fh / 2,
            );
            # Horizontal
            $self->{image}->string(
                $self->{font},
                $file, $bottom,
                chr( ord( 'a' ) + $n ),
                $self->{letter_color}
            );
            # Vertical
            $self->{image}->string(
                $self->{font},
                $left, $rank,
                $self->{board_size} - $n,
                $self->{letter_color}
            );
        }
    }  # }}}

    if( $self->{grid} ) {  # {{{
        for my $n ( 1 .. $self->{max_coord} ) {
            # i.e. inside edge + square size + grid line
            my( $file, $rank ) = (
                $self->{x0} + $self->{border} + $n * $self->{square_width}  + $n - 1,
                $self->{y0} + $self->{border} + $n * $self->{square_height} + $n - 1,
            );
            # Vertical
            $self->{image}->line(
                $file, $self->{y0} + $self->{border},
                $file, $self->{y1} - $self->{border},
                $self->{grid_color}
            );
            # Horizontal
            $self->{image}->line(
                $self->{x0} + $self->{border}, $rank,
                $self->{x1} - $self->{border}, $rank,
                $self->{grid_color}
            );
        }
    }  # }}}
}

1;

__END__

=head1 NAME

Games::Chess::Coverage::GD::Board - Draw a chess board

=head1 DESCRIPTION

Draw a chess board.

Required plug-in arguments with sample settings:

  board_color  => [256,256,256]
  border       => 2
  border_color => [0,0,0]
  letters      => 1
  letter_color => [0,0,0]
  grid         => 1
  grid_color   => [50,50,50]

=begin html

  <img src="http://search.cpan.org/src/gene/Games-Chess-Coverage-0.01/eg/board.gif"/>

=end html

=head1 SEE ALSO

The source code of this file of course.

L<Games::Chess::Coverage>

L<Games::Chess::Coverage::Draw>

L<Games::Chess::Coverage::GD>

L<GD>

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, Gene Boggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 CVS

$Id: Board.pm,v 1.16 2004/05/09 19:30:00 gene Exp $

=cut
