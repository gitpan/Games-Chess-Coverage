# $Id: GD.pm,v 1.9 2004/05/14 05:39:25 gene Exp $

package Games::Chess::Coverage::GD;
$VERSION = '0.0101';
use base 'Games::Chess::Coverage::Draw';
use strict;
use warnings;
use Carp;
use GD;

sub _init {  # {{{
    my( $self, %args ) = @_;

    $self->SUPER::_init;

    # Do we care about fonts?  If not set the margins to zero.
    unless( $self->{letters} ) {
        $self->{left_margin} = $self->{bottom_margin} = 0;
    }

    # Behold: An image.
    $self->{image} = eval {
        GD::Image->new( $self->{image_width}, $self->{image_height} );
    };
    croak $@ if $@;
    croak "Error: No image created" unless $self->{image};

    # Don't forget our arbitrary transparent "color".
#    $self->{transparent_color} = $self->{image}->colorAllocate(
#        255, 192, 192
#    );
    # Color the image transparent.
#    $self->{image}->transparent( $self->{transparent_color} );

    warn __PACKAGE__ . "::_init():\n",
    join( "\n", map {
        "\t$_: ". (defined $self->{$_} ? $self->{$_} : '') }
    sort keys %$self ), "\n"
    if $self->{verbose};
}  # }}}

sub set_color {  # {{{
    my( $self, $name, $def ) = @_;
    $self->{$name} = $self->{image}->colorAllocate( @$def );
    warn "Created $name with @$def as $self->{$name}\n"
        if $self->{verbose};
}  # }}}

sub add_rule {  # {{{
    my( $self, $class, %args ) = @_;
    $self->SUPER::add_rule( $class, %args );
    # Allocate all the plugin colors.
    for( keys %args ) {
        $self->set_color( $_ => $args{$_} ) if /_color$/;
    }
}  # }}}

sub write {    # {{{
    my( $self, $file ) = @_;
    croak "Error: No image to write.\n" unless $self->{image};
    $file ||= $self->{out_file} .'.'. $self->{image_type};

    open IMG, ">$file" or croak "Can't write to $file: $!";
    binmode IMG;
    # Call $img->gif ->png, etc.
    print IMG $self->{image_type} eq 'gif'
        ? $self->{image}->gif : $self->{image}->png;
    close IMG;

    warn "Wrote $self->{image} to $file\n" if $self->{verbose};
}  # }}}

1;

__END__

=head1 NAME

Games::Chess::Coverage::GD - Visualize chess coverage with GD

=head1 SYNOPSIS

  use Games::Chess::Coverage::GD;

  my $drawing = Games::Chess::Coverage::GD->new(
      coverage   => $coverage_object,
      out_file   => 'eg/foo',
      image_type => 'gif',
  );
  while( my( $rule, $args ) = each %rule_set ) {
      $drawing->add_rule( $rule, %$args );
  }
  $drawing->draw;
  $drawing->write;

=head1 DESCRIPTION

Represent chess coverage with the C<GD> drawing module and plug-in
rules based on board settings.

Please see the examples in the distribution C<eg/> directory.

=head1 METHODS

=head2 _init

Create an image based on the settings computed by the
C<Games::Chess::Coverage::Draw> parent.

=head2 add_rule

  $drawing->add_rule( $rule, %args );

Add a rule to the drawing.  This method is required and must call the
C<add_rule> method of the parent followed by this module's
C<set_color> method for all /_color$/ arguments provided.

Please see the method source code for the specific details.

=head2 set_color

  $drawing->set_color( $name => [$red, $green, $blue] );

Create a new color object given an identifying name and an RGB array.

=head2 write

  $drawing->write;
  $drawing->write( $filename );

Write the image object to a file based on the C<out_file> and
C<image_type> settings.

=head1 SEE ALSO

L<Games::Chess>

L<Games::Chess::Coverage>

L<Games::Chess::Coverage::Draw>

L<GD>

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, Gene Boggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
