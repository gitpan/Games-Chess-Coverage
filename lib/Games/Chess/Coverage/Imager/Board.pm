package Games::Chess::Coverage::Imager::Board;

$VERSION = '0.0101';

use strict;
use warnings;
use Carp;
use Imager;
use Imager::Fill;

sub Board {
    my( $self, %args ) = @_;
    warn __PACKAGE__ . "\n",
        join( "\n", map {
            "\t$_: ". (defined $args{$_} ? $args{$_} : '')
        } sort keys %args ), "\n"
        if $self->{verbose};

    # Draw the board background.  # {{{
    $self->{image}->box(
        xmin => 0,
        ymin => 0,
        xmax => $self->{image_width},
        ymax => $self->{image_height},
        fill => Imager::Fill->new( solid => $self->{board_color} ),
    );  # }}}

    # Draw a border around the board.
    # Get thickness by drawing concentric, adjacent rectangles.
    for my $n ( 0 .. $self->{border} - 1 ) {  # {{{
        $self->{image}->box(
            xmin   => $self->{x0} + $n,
            ymin   => $n,
            xmax   => $self->{x1} - $n,
            ymax   => $self->{y1} - $n,
            filled => 0,
            color  => $self->{border_color},
        );
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
                x1    => $file,
                x2    => $file,
                y1    => $self->{y0} + $self->{border},
                y2    => $self->{y1} - $self->{border},
                aa    => 1,
                color => $self->{grid_color},
            );
            # Horizontal
            $self->{image}->line(
                x1    => $self->{x0} + $self->{border},
                x2    => $self->{x1} - $self->{border},
                y1    => $rank,
                y2    => $rank,
                aa    => 1,
                color => $self->{grid_color},
            );
        }
    }  # }}}

    # Draw the file letters a-h and the rank numbers 1-8.
    if( $self->{letters} && $self->{font_file} ) {  # {{{
        # Do we care about fonts but don't have them yet?
        $self->{font} ||= Imager::Font->new(
            file  => $self->{font_file},
            color => $self->{letter_color},
            size  => $self->{font_size} || 20,
        );

        my( $fw, $fh ) = ( $self->{font}->width, $self->{font}->height );
        my( $left, $bottom ) = (
            $self->{x0} - $fh,
            $self->{y1} + $fw / 2
        );
        for my $n ( 0 .. $self->{max_coord} ) {
            # i.e. inside edge + square size + grid line +
            #      half of the square - half of the font
            my( $file, $rank ) = (
                $self->{x0} + $self->{border} + $n * $self->{square_width} + $n +
                    $self->{square_width} / 2 - $fw / 2,
                $self->{y0} + $self->{border} + $n * $self->{square_height} + $n +
                    $self->{square_height} / 2 - $fh / 2,
            );
            # Horizontal
            $self->{image}->string(
                font  => $self->{font},
                text  => chr( ord( 'a' ) + $n ),
                x     => $file,
                y     => $bottom,
                size  => $self->{font_size},
                aa    => 1,
                color => $self->{letter_color},
            );
            # Vertical
            $self->{image}->string(
                font  => $self->{font},
                text  => $self->{board_size} - $n,
                x     => $left,
                y     => $rank,
                size  => $self->{font_size},
                aa    => 1,
                color => $self->{letter_color},
            );
        }
    }  # }}}
}

1;

__END__

=head1 NAME

Games::Chess::Coverage::Imager::Board - Draw a chess board

=head1 DESCRIPTION

Draw a chess board

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

L<Games::Chess::Coverage::Imager>

L<Imager>

L<Imager::Draw>

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, Gene Boggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 CVS

$Id: Board.pm,v 1.17 2004/05/09 23:31:07 gene Exp $

=cut
