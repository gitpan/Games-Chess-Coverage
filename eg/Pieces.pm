package Pieces;

# That is "Games::Chess GD Pieces"

$VERSION = '0.01';

use strict;
use warnings;
use Carp;
use GD;
use Games::Chess qw( :functions );

# Global holder for the piece images to be populated by Games::Chess.
use vars qw( $gifs );

sub Pieces {
    my %args = @_;  # left top width height x y image colors coverage image

    my $c = $args{coverage}->game->at( $args{x}, $args{y} )->code;
    return if $c eq ' ';

    # Populate the image hash of piece glyphs if one does not exist.
    $gifs = Games::Chess::Position::piece_gifs unless keys %$gifs;

    # Copy the glyph to the evolving image.
    $args{image}->copy(
        $gifs->{$c},
        $args{left},  $args{top},
        0, 0,
        $args{width}, $args{height}
    );
}

1;

__END__

=head1 NAME

Games::Chess::Coverage::GD::Pieces - Draw the pieces in Games::Chess

=head1 DESCRIPTION

This is directly taken from the C<Games::Chess> module but simplified
and made to operate as a C<Games::Chess::Coverage> plug-in.

=head1 SEE ALSO

The source code of this file of course.

L<Games::Chess>

L<Games::Chess::Coverage>

L<Games::Chess::Coverage::Draw>

L<Games::Chess::Coverage::Analysis>

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, Gene Boggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 CVS

$Id: Pieces.pm,v 1.2 2004/02/02 05:05:24 gene Exp $

=cut
