# $Id: Draw.pm,v 1.9 2004/06/08 04:02:21 gene Exp $

package Games::Chess::Coverage::Draw;
$VERSION = '0.0102';
use strict;
use warnings;
use Carp;

sub new {
    my( $proto, %args ) = @_;
    my $class = ref $proto || $proto;
    my $self = {
        # G::C::Coverage is the heart and soul of this object.
        coverage => undef,
        # Okay.  Where?
        out_file => 'test',
        # Image settings
        image      => undef,
        image_type => 'png',
        # Geometry
        max_coord     => 7,
        board_size    => 8,
        border        => 2,
        left_margin   => 20,
        bottom_margin => 20,
        square_width  => 33,
        square_height => 33,
        # Custom settings and default overrides.
        %args,
    };
    bless $self, $class;
    $self->_init( %args );
    return $self;
}

sub _init {
    my( $self, %args ) = @_;

    # Check boundries
    for(qw( left_margin bottom_margin border )) {
        0 <= $self->{$_} or
            croak "Option $_ $self->{$_} must be >= 0.";
    }

    # Set image dimensions.
    # i.e. squares + the margin + the borders + the grid lines
    $self->{image_width} = ($self->{board_size} * $self->{square_width}) +
        $self->{left_margin} + (2 * $self->{border}) + $self->{max_coord};
    $self->{image_height} = ($self->{board_size} * $self->{square_height}) +
        $self->{bottom_margin} + (2 * $self->{border}) + $self->{max_coord};

    # Convenient board boundries.
    # Top-left
    $self->{x0} = $self->{left_margin};
    $self->{y0} = 0;
    # bottom-right
    $self->{x1} = $self->{image_width}  - 1;
    $self->{y1} = $self->{image_height} - 1 - $self->{bottom_margin};

    warn join( "\n",
        __PACKAGE__ . '::_init():',
        map { "\t$_: ". ($self->{$_} || '') } sort keys %$self
    ), "\n"
    if $self->{verbose};
}

sub add_rule {
    my $self  = shift;
    my $class = shift or croak "Rule given with no class";
    my %args  = @_;
# NOTE:
# perl -MData::Dumper -Mstrict -wle'my%h=@ARGV;print Dumper\%h'
# $VAR1 = {};
# i.e., an empty hashref is created for undef @_ under strict.

    # XXX Naive and insecure:
    # Make sure that the class is a perl module.
    eval "require $class";
    return if $@ and warn( "Error: $@" );

    # The rule is (always) a subroutine named for the class.
    ( my $rule = $class ) =~ s/^.+?::(\w+)$/$1/;

    # Keep an ordered list of rule names so that they can be
    # applied in a determined sequence.
    push @{ $self->{rule_names} }, $rule;

    # A rule is a code reference.
    $self->{rules}{$rule} = \&{ $class .'::'. $rule };

    # Import the rule arguments into the object itself so that the other
    # plugins can magically use them as $self->{ $args{whatever} }.
    $self->{$_} = $args{$_} for keys %args;
    warn join( "\n",
        __PACKAGE__ .'::add_rule():',
        "\t$rule=$self->{rules}{$rule}",
        map { "\t$_: ". ($args{$_} || '') } sort keys %args
    ), "\n"
    if $self->{verbose};
}

sub draw {
    my $self = shift;

    # Always draw a board first if there is a rule for it.
    $self->{rules}{Board}->( $self ) if exists $self->{rules}{Board};
    # ..and then remove it from the sequence of rules to execute.
    my $rules = [ grep { $_ ne 'Board' } @{ $self->{rule_names} } ];

    # For each square...
    for my $x ( 0 .. $self->{max_coord} ) {
        for my $y ( 0 .. $self->{max_coord} ) {
            # Draw the cell coverage visuals
            for my $name ( @$rules ) {
                # A rule is a callback in the rules list.
                $self->{rules}{$name}->(
                    # XXX Uhh. Why do I give the object as an argument to the method?
                    $self,
                    x => $x,
                    y => $y,
                    left => $self->{x0} + $self->{border} +
                            $x * $self->{square_width} + $x,
                    top  => $self->{y1} - $self->{border} -
                            ($y + 1) * $self->{square_height} - $y + 1,
                );
            }
        }
    }
}

1;

__END__

=head1 NAME

Games::Chess::Coverage::Draw - Base class for visualizing chess coverage

=head1 DESCRIPTION

Visually represent chess coverage with a drawing module such as C<GD>
or C<Imager> and custom plug-in rules.

This module represents the base class for specific drawing modules
and should not to be used directly.  Please refer to the C<SEE ALSO>
section, below.

=begin html

  <img src="http://search.cpan.org/src/GENE/Games-Chess-Coverage-0.01/eg/draw.gif"/>

=end html

Please see the examples in the distribution C<eg/> directory.

=head1 METHODS

=head2 new

  $drawing = Games::Chess::Coverage::Draw->new( %args );

Construct a fresh C<Games::Chess::Coverage::Draw> instance.

Here are the construction options with their default settings:

  coverage      => undef,
  out_file      => 'test',
  image         => undef,
  image_type    => 'png',
  max_coord     => 7,
  board_size    => 8,
  border        => 2,
  left_margin   => 20,
  bottom_margin => 20,
  square_width  => 33,
  square_height => 33

These object attributes are computed on initialization:

  image_width, image_height,
  x0, y0, x1, y1

=head2 add_rule

  $drawing->add_rule( $rule, \%colors_etc );

Add a drawing plugin where the rule is a package containing a
subroutine named for itself.  The rules are kept in an ordered list
so that they can be applied in a determined sequence.

Specific drawing modules, that use C<Imager> or C<GD> for instance,
must also define this method in order to create or allocate the
necessary colors for that module.

=head2 draw

  $img = $drawing->draw;

Apply the defined drawing rules to the image.

=head1 SEE ALSO

L<Games::Chess>

L<Games::Chess::Coverage>

L<Games::Chess::Coverage::Imager>

L<Games::Chess::Coverage::GD>

=head1 TO DO

Make this an I<XBoard> engine.  Draw a transparent image over the
board itself.

Describe the meta-API of user defined pieces, rules and colorings.

Figure out if I<ChessVision> already does this all better and then
assimilate its brains.

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, Gene Boggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
