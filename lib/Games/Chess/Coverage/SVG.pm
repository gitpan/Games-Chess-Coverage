# $Id: SVG.pm,v 1.6 2004/06/28 06:15:03 gene Exp $

package Games::Chess::Coverage::SVG;
$VERSION = '0.0100_1';
use base 'Games::Chess::Coverage::Draw';
use strict;
use warnings;
use Carp;
use SVG;

sub _init {
    my( $self, %args ) = @_;

    # ..From above
    $self->SUPER::_init;

    $self->{font_width}  ||= 10;
    $self->{font_height} ||= 10;

    # Behold: An image.
    $self->{image} = eval {
        SVG->new(
            width  => $self->{image_width},
            height => $self->{image_height},
        );
    };
    croak $@ if $@;
    warn "Drawing: $self->{image} of $self->{image_width} x $self->{image_height}\n"
        if $self->{verbose};
}

# And the Maker said, "Let there be color" and there was color.
sub set_color {
    my( $self, $name, $def ) = @_;
    $self->{$name} = ref $def eq 'ARRAY'
        ? 'rgb('. join( ',', @$def ) .')'
        : $def;
    warn "Color: $name=$def as $self->{$name}\n"
        if $self->{verbose};
}

sub add_rule {
    my( $self, $class, %args ) = @_;
    $self->SUPER::add_rule( $class, %args );
    # Set the plugin colors.
    for( keys %args ) {
        $self->set_color( $_ => $args{$_} ) if /_color$/;
    }
}

sub write {
    my( $self, $file ) = @_;
    croak "Error: No image to write.\n" unless $self->{image};
    $file ||= $self->{out_file} .'.'. $self->{image_type};
    open IMG, ">$file" or croak "Can't write to $file: $!";
    print IMG $self->{image}->xmlify;
    close IMG;
    warn "Wrote $self->{image} to $file\n" if $self->{verbose};
}

1;

__END__

=head1 NAME

Games::Chess::Coverage::SVG - Visualize chess coverage with SVG

=head1 SYNOPSIS

  use Games::Chess::Coverage::SVG;

  my $drawing = Games::Chess::Coverage::SVG->new(
      coverage   => $coverage_object,
      out_file   => 'eg/foo',
      image_type => 'svg',
  );
  while( my( $rule, $args ) = each %rule_set ) {
      $drawing->add_rule( $rule, %$args );
  }
  $drawing->draw;
  $drawing->write;

=head1 DESCRIPTION

Represent chess coverage with the C<SVG> drawing module and plug-in
rules based on board settings.

Please see the example in the distribution C<eg/> directory.

=head1 METHODS

=head2 _init

Create an image based on the settings computed in the
C<Games::Chess::Coverage::Draw> parent.

=head2 add_rule

  $drawing->add_rule( $rule, %args );

Add a rule to the drawing.  This method is required and must call the
parent's C<add_rule> method, then followed by this module's
C<set_color> method for all the C</_color$/> arguments provided.

Please see the method source code for the specific details.

=head2 set_color

  $drawing->set_color( $name => $definition );

Return a color object given an identifying name and a valid C<SVG>
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

L<SVG>

L<SVG::Color>

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, Gene Boggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
