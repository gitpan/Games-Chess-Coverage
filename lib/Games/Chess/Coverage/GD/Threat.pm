package Games::Chess::Coverage::GD::Threat;

$VERSION = '0.0101';

use strict;
use warnings;
use Carp;
use GD;

sub Threat {
    my( $self, %args ) = @_;

    my $state = $self->{coverage}->states->{ $args{x} . $args{y} };

    for my $color (qw( white black )) {
        if( exists $state->{$color} && exists $state->{$color}{capture} ) {
            my $is_enemy = $color eq 'white' ? 0 : 1;

            my $i = 0;
            for( @{ $state->{$color}{capture} } ) {
                $i++;
                $self->{image}->rectangle(
                    $args{left} + $i + $is_enemy,
                    $args{top}  + $i + $is_enemy,
                    $args{left} + $self->{square_width}  - $i - $is_enemy - 1,
                    $args{top}  + $self->{square_height} - $i - $is_enemy - 1,
                    $self->{$color . '_threat_color'}
                );
                $i++;
            }
        }
    }
}

1;

__END__

=head1 NAME

Games::Chess::Coverage::GD::Threat - Visualize attack

=head1 DESCRIPTION

Display the "can attack" state for multiple White and Black threats
as alternating concentric squares.

Required plug-in arguments:

  white_threat_color => [ $R, $G, $B ]
  black_threat_color => [ $R, $G, $B ]

=begin html

  <img src="http://search.cpan.org/src/GENE/Games-Chess-Coverage-0.01/eg/threat.gif"/>

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

=head1 CVS

$Id: Threat.pm,v 1.18 2004/05/09 23:33:12 gene Exp $

=cut
