package Games::Chess::Coverage::Imager;

$VERSION = '0.01';

use base 'Games::Chess::Coverage::Draw';
use strict;
use warnings;
use Carp;
use Imager;

sub _init {  # {{{
    my( $self, %args ) = @_;

    # ..From above
    $self->SUPER::_init;

    # Behold: An image.
    $self->{image} = eval {
        Imager->new(
            xsize => $self->{image_width},
            ysize => $self->{image_height},
            channels => 4,
        );
    };
    croak $@ if $@;
    warn "Created RGB $self->{image} of $self->{image_width} x $self->{image_height}\n"
        if $self->{verbose};
}  # }}}

# And the Maker said, "Let there be color" and there was color.
sub set_color {  # {{{
    my( $self, $name, $def ) = @_;
    $self->{$name} = Imager::Color->new(
        ref $def eq 'ARRAY' ? @$def
      : ref $def eq 'HASH'  ? %$def
      : $def
    );
    warn "Created color $name with $def definition as $self->{$name}\n"
        if $self->{verbose};
}  # }}}

sub add_rule {  # {{{
    my( $self, $class, %args ) = @_;
    $self->SUPER::add_rule( $class, %args );
    # Create all the plugin colors.
    for( keys %args ) {
        $self->set_color( $_ => $args{$_} ) if /_color$/;
    }
}  # }}}

sub write {  # {{{
    my( $self, $file ) = @_;
    $file ||= $self->{out_file} .'.'. $self->{image_type};
    $self->{image}->write(
        file => $file,
        type => $self->{image_type},
    );
    warn "Wrote $self->{image} to $file\n" if $self->{verbose};
}  # }}}

1;

__END__

=head1 NAME

Games::Chess::Coverage::Imager - Visualize chess coverage with Imager

=head1 SYNOPSIS

  use Games::Chess::Coverage::Imager;

  my $drawing = Games::Chess::Coverage::Imager->new(
      coverage   => $coverage_object,
      out_file   => 'eg/foo',
      image_type => 'png',
  );
  while( my( $rule, $args ) = each %rule_set ) {
      $drawing->add_rule( $rule, %$args );
  }
  $drawing->draw;
  $drawing->write;

=head1 DESCRIPTION

Represent chess coverage with the C<Imager> drawing module and plug-in
rules based on board settings.

=begin html

  <img src="http://search.cpan.org/src/gene/Games-Chess-Coverage-0.01/eg/draw.gif"/>

=end html

Please see the examples in the distribution C<eg/> directory.

=head1 METHODS

=head2 _init

Create an image based on the settings computed in the
C<Games::Chess::Coverage::Draw> parent.

=head2 add_rule

  $drawing->add_rule( $rule, %args );

Add a rule to the drawing.  This method is required and must call the
C<add_rule> method of the parent followed by this module's
C<set_color> method for all /_color$/ arguments provided.

Please see the method source code for the specific details.

=head2 set_color

  $drawing->set_color( $name => $definition );

Return a color object given an identifying name and a valid C<Imager>
color definition.  If the color does not exist yet, create it.

=head2 write

  $drawing->write;
  $drawing->write( $filename );

Write the image object to a file based on the C<out_file> and
C<image_type> settings.

=head1 SEE ALSO

L<Games::Chess>

L<Games::Chess::Coverage>

L<Games::Chess::Coverage::Draw>

L<Imager>

L<Imager::Color>

=head1 CVS

$Id: Imager.pm,v 1.7 2004/05/09 19:30:00 gene Exp $

=cut
