# ABSTRACT : Core Module using various for interacting with a GUI application through perl
package Moo::Task::ControlByGui::Role::Core;
our $VERSION = 'v1.0.3';

##~ DIGEST : ddbbfb0c802fefd0a8d583e81bdbf253
use strict;
use Moo::Role;
use 5.006;
use warnings;
use Data::Dumper;
use Carp;
use POSIX;
use List::Util qw(min max);

=head1 VERSION & HISTORY
	<breaking revision>.<feature>.<patch>
	1.0.0 - 2024-06-23
		Rip from chitubox-controller project
=head1 SYNOPSIS
	Methods, wrappers and variables to interact with arbitrary GUI applications by simulating manual mouse and keyboard input
=cut

=head3 Output to program
=cut

ACCESSORS: {

	#where the zero point of the application is expected - especially relevant for multi screen setups
	has ControlByGui_zero_point => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			Carp::confess "ControlByGui_zero_point not overwritten";
		}
	);

	#named map of xy coordinates for clicking
	has ControlByGui_coordinate_map => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			Carp::confess "ControlByGui_coordinate_map not overwritten";
		}
	);

	#various other values
	has ControlByGui_values => (
		is   => 'rw',
		lazy => 1,
	);
}

#get highlighted text
sub return_text {
	my ( $self ) = @_;
	$self->handle_external_failure();
	$self->ctrl_copy();
	return $self->return_clipboard();
}

#click on a named something
sub click_on {
	my ( $self, $name, $p ) = @_;
	$self->handle_external_failure();
	$self->move_to_named( $name, $p );
	$self->click();
}

#return hex RGB of pixel at coordinate
sub get_colour_at_named {
	my ( $self, $name ) = @_;
	$self->handle_external_failure();
	my $xy = $self->get_named_xy_coordinates( $name );
	return $self->get_colour_at_coordinates( $xy );
}

#return 1 if a pixel at a named coordinate is a hex colour
sub if_colour_at_named {
	my ( $self, $want_colour, $name ) = @_;
	my $colour = $self->get_colour_at_named( $name );

	#54BBFF
	if ( $colour eq $want_colour ) {
		return 1;
	} else {
		print "Colour mismatch: $colour !eq $want_colour$/";
	}
	return 0;
}

#return 1 if a pixel at a named coordinate is a named and mapped colour
sub if_colour_name_at_named {
	my ( $self, $want_name, $name ) = @_;
	my $colour = $self->ControlByGui_values->{colour}->{$want_name};
	die "Named colour value [$want_name] not found." unless $colour;
	return $self->if_colour_at_named( $colour, $name );

}

#move mouse pointer to a named coordinate with relevant offsets
sub move_to_named {
	my ( $self, $name, $p ) = @_;
	$self->handle_external_failure();
	my $xy = $self->get_named_xy_coordinates( $name, $p );

	#offset here being the offset from the default zero point which is the baseline for everything else
	if ( $p->{offset} ) {
		$xy->[0] += $p->{offset}->[0];
		$xy->[1] += $p->{offset}->[1];
	}
	my $x = $xy->[0] + ( defined( $p->{x_mini_offset} ) ? $p->{x_mini_offset} : 0 );
	my $y = $xy->[1] + ( defined( $p->{y_mini_offset} ) ? $p->{y_mini_offset} : 0 );

	return $self->move_to( [ $x, $y ] );
}

#return [x,y] coordinates of named and mapped value
sub get_named_xy_coordinates {
	my ( $self, $name, $p ) = @_;
	$p ||= {};
	my $map = $p->{'map'} || $self->ControlByGui_coordinate_map();
	die "[$name] Not found in map" unless $map->{$name};
	my ( $x, $y ) = @{$map->{$name}};

	print "$name original -> $x,$y$/";
	unless ( $p->{no_offset} ) {
		$x += $self->ControlByGui_zero_point->[0];
		$y += $self->ControlByGui_zero_point->[1];
	}

	print "$name offset -> $x,$y$/";
	return [ $x, $y ];
}

#calculate a sensible duration to sleep - particularly relevant when IO is a factor and screen elements do not show until a long operation has completed
sub dynamic_sleep {
	my ( $self, $sleep, $p ) = @_;
	$p ||= {};
	sleep( max( $sleep || 0, $p->{sleep_for} || 0, $self->{sleep_for} || 0, 1 ) );
	$self->handle_external_failure();
}

#as dynamic sleep but for notionally shorter operations, but always sleeping for at least 1 second
sub dynamic_short_sleep {
	my ( $self ) = @_;

	my $sleep_for = ceil( ( $self->{sleep_for} || 1 ) / ( $self->config->{dynamic_sleep_short_divider} || 1 ) );
	$sleep_for = 1 if $sleep_for < 1;
	print "dynamic_short_sleep : $sleep_for$/";
	sleep( $sleep_for );
	$self->handle_external_failure();
}

#adjust the dynamic sleep duration according to an expected file size - this might not work on windows?
sub adjust_sleep_for_file {
	my ( $self, $path ) = @_;

	my $filename = $path;
	my @stat     = stat $filename;
	$self->{workspace_size} += $stat[7];

	#sleep 1 second for every x mb
	$self->{sleep_for} = ceil( $self->{workspace_size} / ( 1024 * 1024 * $self->config->{dynamic_sleep_megabyte_size} ) );
	warn "adjusted sleep for to $self->{sleep_for}";

}

#specific application's manager library will modify this with an 'around'
sub check_application_status {
	return 1;
}

sub handle_external_failure {
	my ( $self ) = @_;
	unless ( $self->check_application_status() ) {
		Carp::confess( 'External application not usable' );
	}
}

#for situations where clicking too fast will cause problems, typically where a highlight is applied to the menu item
sub hover_click {
	my ( $self, $name, $p ) = @_;
	$p ||= {};
	$p->{x_mini_offset} ||= -1;
	$self->move_to_named( $name, $p );
	$self->dynamic_sleep();
	$self->click_on( $name );
	$self->handle_external_failure();

}

#deprecating

sub click_to {
	my ( $self, $name, $p ) = @_;
	Carp::cluck( "Obsolete method name - should be click_on" );
	$self->click_on( $name, $p );
}

=head1 AUTHOR
	mmacnair, C<< <mmacnair at cpan.org> >>
=head1 BUGS
	TODO Bugs
=head1 SUPPORT
	TODO Support
=head1 ACKNOWLEDGEMENTS
	TODO
=head1 COPYRIGHT
 	Copyright 2024 mmacnair.
=head1 LICENSE
	TODO
=cut

1;
