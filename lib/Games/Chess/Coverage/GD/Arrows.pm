# $Id: Arrows.pm,v 1.15 2004/05/14 05:39:26 gene Exp $

package Games::Chess::Coverage::GD::Arrows;

$VERSION = '0.0102_1';

use strict;
use warnings;
use Carp;
use GD;

use constant PI    => 2 * atan2( 1, 0 );  # The number.
use constant FLARE => 0.9 * PI;           # The angle of the arrowhead.

sub Arrows {  # {{{
    my( $self, %args ) = @_;
    my $state = $self->{coverage}->states->{ $args{x} . $args{y} };
    for(qw( white black )) {
        draw_arrows(
            $self,
            %args,
            color => $_,
            state => $state,
            capture_color => $self->{$_ . '_arrow_color'}
        );
    }
}  # }}}

sub draw_arrows {  # {{{
    my( $self, %args ) = @_;

    if( exists $args{state}->{ $args{color} } &&
        exists $args{state}->{ $args{color} }{capture}
    ) {
        for( @{ $args{state}->{ $args{color} }{capture} } ) {
            my( $head_x, $head_y ) = split //;
            $head_x =
                $self->{x0} + $self->{border} +
                $head_x * $self->{square_width} + $head_x +
                ($self->{square_width} / 2);
            $head_y =
                $self->{y1} - $self->{border} -
                ($head_y + 1) * $self->{square_height} - ($head_y + 1) +
                ($self->{square_height} / 2);

            my $tail_x = $args{left} + ($self->{square_width} / 2);
            my $tail_y = $args{top}  + ($self->{square_height} / 2);

            # Point from the capturing cell to the captured cell.
            $self->{image}->line(
                $head_x, $head_y,
                $tail_x, $tail_y,
                $args{capture_color}
            );

            _draw_arrowhead(
                $self->{image},
                $head_x, $head_y,
                $tail_x, $tail_y,
                $args{capture_color}
            );
        }
    }
}  # }}}

sub _draw_arrowhead {  # {{{
    my( $img, $hx, $hy, $tx, $ty, $color ) = @_;

    # Calculate the size and distance of the vector.
    my $dx = $tx - $hx;
    my $dy = $ty - $hy;
    my $dist = sqrt( ( $dx * $dx ) + ( $dy * $dy ) );
    # Calculate the angle of the vector in radians.
    my $angle = atan2( $dy, $dx );

    my $poly = GD::Polygon->new;
    $poly->addPt( $tx, $ty);
#    for( $angle + FLARE, $angle - FLARE ) {  # "full arrow"

    for( $angle + FLARE, $angle + PI ) {  # "half arrow"
        my $unitx = cos( $_ ) * 10;
        my $unity = sin( $_ ) * 10;

        $dx = $tx + $unitx;
        $dy = $ty + $unity;

        $poly->addPt( $dx, $dy );
    }

    # Allocate the arrow color if it hasn't been, already.
    $img->filledPolygon( $poly, $color );
}  # }}}

1;

__END__

=head1 NAME

Games::Chess::Coverage::GD::Arrows - Visualize attack with arrows

=head1 DESCRIPTION

Display B<can be attacked> for a square given multiple White and 
Black threats.  This is done with a "half arrow" whose head is the 
threatened square and whose tail is the threatening square.

Required plug-in arguments:

  white_arrow_color => [ $R, $G, $B ]
  black_arrow_color => [ $R, $G, $B ]

=begin html

  <img src="http://search.cpan.org/src/GENE/Games-Chess-Coverage-0.01/eg/arrows.gif"/>

=end html

=head1 SEE ALSO

L<Games::Chess::Coverage>

L<Games::Chess::Coverage::Draw>

L<Games::Chess::Coverage::GD>

L<Games::Chess::Coverage::GD::Threat>

L<GD>

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, Gene Boggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 CVS

$Id: Arrows.pm,v 1.15 2004/05/14 05:39:26 gene Exp $

=cut
