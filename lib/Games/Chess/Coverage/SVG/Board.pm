# $Id: Board.pm,v 1.4 2004/06/21 07:43:44 gene Exp $

package Games::Chess::Coverage::SVG::Board;
use base 'Games::Chess::Coverage::SVG';
$VERSION = '0.0100_1';
use strict;
use warnings;
use Carp;
use SVG;

sub Board {
    my $self = shift;

    if( $self->{border} ) {
        $self->{image}->rectangle(
            id => 'border',
            x => $self->{x0} + $self->{border} / 2,
            y => $self->{y0} + $self->{border} / 2,
            width  => $self->{image_width} - $self->{x0} - $self->{border},
            height => $self->{y1} - $self->{border},
            style => {
                stroke => $self->{border_color},
                fill => 'none',
                'stroke-width' => $self->{border},
            }
        );
    }

    if( $self->{grid} ) {
        for my $n ( 1 .. $self->{max_coord} ) {
            # i.e. inside edge + square size + grid line
            my( $file, $rank ) = (
                $self->{x0} + $self->{border} +
                    $n * $self->{square_width}  + $n - 1,
                $self->{y0} + $self->{border} +
                    $n * $self->{square_height} + $n - 1,
            );
            # Vertical
            $self->{image}->line(
                id => "grid_vertical_$n",
                x1 => $file,
                x2 => $file,
                y1 => $self->{y0} + $self->{border},
                y2 => $self->{y1} - $self->{border},
                style => {
                   stroke => $self->{grid_color},
                    'stroke-width' => 1,
                   fill => 'none',
                }
            );
            # Horizontal
            $self->{image}->line(
                id => "grid_horizontal_$n",
                x1 => $self->{x0} + $self->{border},
                x2 => $self->{x1} - $self->{border} + 1,
                y1 => $rank,
                y2 => $rank,
                style => {
                    stroke => $self->{grid_color},
                    'stroke-width' => 1,
                    fill => 'none',
                }
            );
        }
    }

    # Draw the file letters a-h and the rank numbers 1-8.
    if( $self->{letters} ) {
        my( $left, $bottom ) = (
            $self->{left_margin} / 2 - $self->{border},
            $self->{y1} + $self->{bottom_margin} / 2 + $self->{border}
        );
        for my $n ( 0 .. $self->{max_coord} ) {
            # i.e. inside edge + square size + grid line +
            #      half of the square - half of the font
            my( $file, $rank ) = (
                $self->{x0} + $self->{border} +
                    $n * $self->{square_width} + $n +
                    $self->{square_width} / 2,
                $self->{y0} + $self->{border} +
                    $n * $self->{square_height} + $n +
                    $self->{square_height} / 2
            );
            $self->{image}->text(
                id => "letter_horizontal_$n",
                x  => $file,
                y  => $bottom,
                style => {
                    'stroke-width' => 0,
                    'stroke' => $self->{letter_color},
                    'fill' => $self->{letter_color},
                    'font-weight' => 'normal',
                    'font-style' => 'normal',
                },
            )->cdata( chr( ord('a') + $n ) );
            $self->{image}->text(
                id => "letter_vertical_$n",
                x  => $left,
                y  => $rank,
                style => {
                    'stroke-width' => 0,
                    'stroke' => $self->{letter_color},
                    'fill' => $self->{letter_color},
                    'font-weight' => 'normal',
                    'font-style' => 'normal',
                },
            )->cdata( $self->{board_size} - $n );
        }
    }

    warn join( "\n",
        'Rendered: '. __PACKAGE__,
        "\tBoard=$self->{rules}{Board}",
    ), "\n"
    if $self->{verbose};
}

1;

__END__

=head1 NAME

Games::Chess::Coverage::SVG::Board - Draw a chess board

=head1 DESCRIPTION

Render an SVG chess board.

Required plug-in arguments with sample settings:

  board_color  => [256,256,256]
  border       => 2
  border_color => [0,0,0]
  letters      => 1
  letter_color => [0,0,0]
  grid         => 1
  grid_color   => [50,50,50]

=begin html

  <img src="http://search.cpan.org/src/GENE/Games-Chess-Coverage-0.01/eg/board.png"/>

=end html

=head1 SEE ALSO

The source code of this file of course.

L<Games::Chess>

L<Games::Chess::Coverage>

L<Games::Chess::Coverage::Draw>

L<Games::Chess::Coverage::SVG>

L<SVG>

L<SVG::Draw>

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, Gene Boggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
