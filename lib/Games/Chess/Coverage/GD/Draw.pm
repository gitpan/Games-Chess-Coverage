package Games::Chess::Coverage::GD::Draw;

$VERSION = '0.01';

use strict;
use warnings;
use Carp;
use GD;
use Graphics::ColorNames qw( hex2tuple );
use Games::Chess::Coverage::GD::Board;

use constant MAX_COORD  => 7;
use constant BOARD_SIZE => 8;

sub new {  # {{{
    my( $proto, %args ) = @_;
    my $class = ref $proto || $proto;
    my $self = {
        # Okay.  Where?
        out_file => $args{out_file} || 'test',
        # Games::Chess::Coverage is the heart and soul of this object.
        coverage => $args{coverage} || undef,
        # Graphics::ColorNames settings
        color_scheme => $args{color_scheme} || 'Netscape',  # More: HTML, Windows
        color_table  => undef,  # This needs to be undef.  Again _init is it.
        # GD and image settings
        image        => $args{image} || undef,
        image_type   => $args{image_type} || 'png',
        image_colors => undef,
        letters      => defined $args{letters} ? $args{letters} : 1,
        grid         => defined $args{grid}    ? $args{grid}    : 1,
        # Geometry
        border  => defined $args{border} ? $args{border} : 2,
        lmargin => $args{lmargin} || 20,
        bmargin => $args{bmargin} || 20,
        width   => $args{width}   || 33,
        height  => $args{height}  || 33,
        # Colors for the default board.
        board_color  => $args{board_color}  || 'transparent',
        border_color => $args{border_color} || 'black',
        letter_color => $args{letter_color} || 'black',
        grid_color   => $args{grid_color}   || 'grey',
    };
    bless $self, $class;
    $self->_init( %args );
    return $self;
}  # }}}

sub _init {  # {{{
    my( $self, %args ) = @_;

    # Check boundries
    for(qw( lmargin bmargin border )) {
        0 <= $self->{$_} or
            croak "Option $_ $self->{$_} must be >= 0.";
    }

    # Do we care about fonts?
    if( $self->{letters} ) {
        $self->{font} = GD::Font->Giant;
        UNIVERSAL::isa( $self->{font}, 'GD::Font' ) or
            croak "$self->{font} does not belong to the GD::Font class.";
    }
    else {
        # Set margins to zero.
        $self->{lmargin} = $self->{bmargin} = 0;
    }

    # Set image dimensions.
    # i.e. squares + the margin + the borders + the grid lines
    ( $self->{image_width}, $self->{image_height} ) = (
        (BOARD_SIZE * $self->{width})  + $self->{lmargin} +
            (2 * $self->{border}) + MAX_COORD,
        (BOARD_SIZE * $self->{height}) + $self->{bmargin} +
            (2 * $self->{border}) + MAX_COORD
    );

    # Behold: An image.
    $self->{image} = GD::Image->new(
        $self->{image_width}, $self->{image_height}
    );

    # Set the board colors
    while( my( $name, $hex ) = each %{ $self->color_table } ) {
        $self->{image_colors}{$name} = $self->{image}->colorAllocate(
            hex2tuple( $hex )
        );
    }
    # And don't forget our arbitrary transparent "color".
    $self->{image_colors}{transparent} = $self->{image}->colorAllocate(
        255, 192, 192
    );
    # Color the image transparent.
    $self->{image}->transparent( $self->{image_colors}{transparent} );

    # These board boundries are too convenient to not have.
    # Top-left
    $self->{x0} = $self->{lmargin};
    $self->{y0} = 0;
    # bottom-right
    $self->{x1} = $self->{image_width}  - 1;
    $self->{y1} = $self->{image_height} - 1 - $self->{bmargin};
}  # }}}

sub add_rule {  # {{{
    my $self  = shift;
    my $class = shift or croak "Rule given with no class";

    my %args  = @_;
# NOTE that ^^^ this works in perl:
# perl -MData::Dumper -Mstrict -wle'my%h=@ARGV;print Dumper\%h'
# $VAR1 = {};

    # A rule is a code reference to a subroutine in the given class.
    eval "require $class";
    return if $@ and warn( "Error: $@" );

    # The rule is named for the last part of the class name.
    ( my $rule = $class ) =~ s/^.+?::(\w+)$/$1/;

    # Keep an ordered list of rule names so we can apply them in a
    # determined sequence.
    push @{ $self->{rule_names} }, $rule;

    # A rule is a code reference in the rules attribute.
    $self->{rules}{$rule} = {
        rule => \&{ $class .'::'. $rule },
        arguments => \%args,
    };
}  # }}}

sub color_table {  # {{{
    my $self = shift;
    unless( $self->{color_table} ) {
        tie %{ $self->{color_table} }, 'Graphics::ColorNames',
            $self->{color_scheme};
    }
    return $self->{color_table};
}  # }}}

sub draw {  # {{{
    my $self = shift;

    # Just lump everything into an arguments hash.
    my %args = map { $_ => $self->{$_} } qw(
            coverage image image_colors
            image_width image_height
            border lmargin bmargin
            height width x0 y0 x1 y1
    );

    # Draw the board.
    Games::Chess::Coverage::GD::Board::Board(
        %args,
        map { $_ => $self->{$_} } qw(
            grid letters font
            board_color border_color
            letter_color grid_color
        )
    );

    for my $x ( 0 .. MAX_COORD ) {
        for my $y ( 0 .. MAX_COORD ) {
            # Compute the square coordinates.
            my( $left, $top ) = (
                $self->{x0} + $self->{border} + $x * $self->{width} + $x,
                $self->{y1} - $self->{border} - ($y + 1) * $self->{height} - $y + 1
            );

            # Draw the cell coverage visuals
            for my $name ( @{ $self->{rule_names} } ) {
                # But we already drew the board.
                next if $name eq 'Board';

                # A rule is a named callback in the rules array.
                $self->{rules}{$name}{rule}->(
                    # Subroutine arguments.
                    %args,
                    # Override arguments provided at rule creation.
                    %{ $self->{rules}{$name}{arguments} },
                    # Computed iteration arguments.
                    x => $x,
                    y => $y,
                    left => $left,
                    top  => $top,
                );
            }
        }
    }

#    return $self->{image}->$self->{image_type};  # XXX This should work, right?
    return $self->{image_type} =~ /png/i
         ? $self->{image}->png : $self->{image}->gif;
}  # }}}

sub board_to_file {  # {{{
    my( $self, $file ) = @_;
    $file ||= $self->{out_file} .'.'. $self->{image_type};
    open IMG, ">$file" or croak "Can't write to $file: $!";
    binmode IMG;
    print IMG $self->draw;
    close IMG;
}  # }}}

1;

__END__

=head1 NAME

Games::Chess::Coverage::GD::Draw - Visualize chess coverage

=head1 SYNOPSIS

  use Games::Chess::Coverage::GD::Draw;

  $drawing = Games::Chess::Coverage::GD::Draw->new(
      coverage   => $coverage_object,
      out_file   => 'eg/foo',
      image_type => 'png',
      width      => 40,
      height     => 40,
      grid       => 0,
      border     => 0,
      letters    => 1,
  );

  $drawing->add_rule( $rule, \%colors );

  $img = $drawing->draw;

  $drawing->board_to_file;

=head1 DESCRIPTION

Represent chess coverage with the C<GD> drawing module and plug-in
rules based on board settings.

=begin html

  <img src="http://search.cpan.org/src/gene/Games-Chess-Coverage-0.01/eg/draw.gif"/>

=end html

Please see the examples in the distribution C<eg/> directory.

=head1 METHODS

=head2 new

  $drawing = Games::Chess::Coverage::GD::Draw->new( %args );

Construct a fresh C<Games::Chess::Coverage::GD::Draw> instance.

=head2 add_rule

  $drawing->add_rule( $rule, \%colors );

Add a C<Games::Chess::Coverage::GD::Draw> plugin where the rule is a
package containing a subroutine named for itself.  The rules are kept
in an ordered list so that they can be applied in a determined
sequence.

=head2 draw

  $img = $drawing->draw;

Return a C<GD> image object with the plug-in rules applied.

=head2 board_to_file

  $drawing->board_to_file;

Write the C<GD> image object to a file based on the C<out_file> and
C<image_type> settings.

=head1 SEE ALSO

The source code of this module.

L<Games::Chess>

L<Games::Chess::Coverage>

=head1 TO DO

Allow hex number color specifications.

Make this an I<XBoard> engine.  Maybe draw a transparent image over 
the board itself.

Describe the meta-API.  That is user defined pieces, rules and 
colorings.

Figure out if I<ChessVision> already does this all better and then
assimilate it's brains.

=head1 CVS

$Id: Draw.pm,v 1.21 2004/04/11 04:22:33 gene Exp $

=cut
