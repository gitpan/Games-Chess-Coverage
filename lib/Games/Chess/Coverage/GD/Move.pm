# $Id: Move.pm,v 1.15 2004/05/14 05:39:26 gene Exp $

package Games::Chess::Coverage::GD::Move;
$VERSION = '0.0102';
use strict;
use warnings;
use Carp;
use GD;

sub Move {
    my( $self, %args ) = @_;

    my $state = $self->{coverage}->states->{ $args{x} . $args{y} };

    if( $state->{white}{move} || $state->{black}{move} ) {
        $self->{image}->filledRectangle(
            $args{left}, $args{top},
            $args{left} + $self->{square_width}  - 1,
            $args{top}  + $self->{square_height} - 1,
            # What color are we drawing?
            # ..only white?
            ( $state->{white}{move} && !$state->{black}{move} )
                ? $self->{white_move_color}
            # ..only black?
                : ( $state->{black}{move} && !$state->{white}{move} )
                    ? $self->{black_move_color}
            # Okay both.
                    : $self->{both_move_color}
        );
    }
}

1;

__END__

=head1 NAME

Games::Chess::Coverage::GD::Move - Visualize movement

=head1 DESCRIPTION

Display B<can be moved to> for each square given multiple White and 
Black threats.  This is currently drawn as a grid of two pale colors.

Required plug-in arguments:

  white_move_color => [ $R, $G, $B ]
  black_move_color => [ $R, $G, $B ]
  both_move_color  => [ $R, $G, $B ]

=begin html

  <img src="http://search.cpan.org/src/GENE/Games-Chess-Coverage-0.01/eg/move.gif"/>

=end html

=head1 SEE ALSO

The source code of this module.

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

=cut
