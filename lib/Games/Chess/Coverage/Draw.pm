package Games::Chess::Coverage::Draw;

$VERSION = '0.0101';

use strict;
use warnings;
use Carp;

sub new {  # {{{
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
}  # }}}

sub _init {  # {{{
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

    warn __PACKAGE__ . "::_init():\n",
        join( "\n", map {
            "\t$_: ". (defined $self->{$_} ? $self->{$_} : '')
        } sort keys %$self ), "\n"
        if $self->{verbose};
}  # }}}

sub add_rule {  # {{{
    my $self  = shift;
    my $class = shift or croak "Rule given with no class";
    my %args  = @_;
# NOTE:
# perl -MData::Dumper -Mstrict -wle'my%h=@ARGV;print Dumper\%h'
# $VAR1 = {};
# i.e., an empty hashref is created for undef @_ under strict.

    # Make sure that the class is a perl module.
    eval "require $class";
    return if $@ and warn( "Error: $@" );

    # The rule is a subroutine named for the class.
    ( my $rule = $class ) =~ s/^.+?::(\w+)$/$1/;

    # Keep an ordered list of rule names so we can apply them in a
    # determined sequence.
    push @{ $self->{rule_names} }, $rule;

    # A rule is a code reference in the "rules" attribute.
    $self->{rules}{$rule} = {
        rule => \&{ $class .'::'. $rule }
    };

    # Import the rule arguments so the other plugins can use them as
    # "$self->{$args{whatever}}"
    $self->{$_} = $args{$_} for keys %args;

    warn "Rule: $rule $self->{rules}{$rule}{rule} added.\n"
        if $self->{verbose};
}  # }}}

sub draw {  # {{{
    my $self = shift;

    # Draw a board if there is a rule for it.
    if( exists $self->{rules}{Board}{rule} ) {
        $self->{rules}{Board}{rule}->( $self );
        warn "Board $self->{rules}{Board}{rule} drawn\n"
            if $self->{verbose};
    };

    # For each square...
    for my $x ( 0 .. $self->{max_coord} ) {
        for my $y ( 0 .. $self->{max_coord} ) {
            # Draw the cell coverage visuals
            for my $name (
                # ..except the board that we already drew.
                grep { $_ ne 'Board' } @{ $self->{rule_names} }
            ) {
                # A rule is a named callback in the rules array.
                $self->{rules}{$name}{rule}->(
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
}  # }}}

1;

__END__

=head1 NAME

Games::Chess::Coverage::Draw - Base class for visualizing chess coverage

=head1 DESCRIPTION

Represent chess coverage with a drawing module such as C<GD> or
C<Imager> and plug-in rules based on board settings.

This module is the base class for specific drawing modules and is not
to be used directly.

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

Object arguments computed on initialization:

  image_width, image_height,
  x0, y0, x1, y1

=head2 add_rule

  $drawing->add_rule( $rule, \%colors );

Add a C<Games::Chess::Coverage::Draw> plugin where the rule is a
package containing a subroutine named for itself.  The rules are
kept in an ordered list so that they can be applied in a determined
sequence.

Specific drawing modules such as C<Games::Chess::Coverage::Imager> or
C<Games::Chess::Coverage::GD> must also define this method in order to
create or allocate the necessary colors.  Please see the source code
of these modules for the specific details involved.

=head2 draw

  $img = $drawing->draw;

Apply the defined drawing rules to the image.

=head1 SEE ALSO

L<Games::Chess>

L<Games::Chess::Coverage>

L<Games::Chess::Coverage::Imager>

L<Games::Chess::Coverage::GD>

=head1 TO DO

Make this an I<XBoard> engine.  Maybe draw a transparent image over 
the board itself.

Describe the meta-API.  That is user defined pieces, rules and 
colorings.

Figure out if I<ChessVision> already does this all better and then
assimilate it's brains.

=head1 CVS

$Id: Draw.pm,v 1.7 2004/05/09 23:33:11 gene Exp $

=cut
