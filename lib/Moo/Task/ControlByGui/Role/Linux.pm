# ABSTRACT : Linux specific methods to carry out ::Core methods
package Moo::Task::ControlByGui::Role::Linux;
our $VERSION = 'v1.0.3';

##~ DIGEST : cb44e0bb6738cc4651a6ade5498f51e0
use strict;
use Moo::Role;
use 5.006;
use warnings;
use Data::Dumper;
use Carp;

=head1 VERSION & HISTORY
	<breaking revision>.<feature>.<patch>
	1.0.0 - 2024-06-23
		Rip from chitubox-controller project
=head1 SYNOPSIS
	Use xdotool the way I normally do 
=head2 WRAPPERS
	Should be the whole of the module 
=cut

=head3 Output to program
=cut

sub ctrl_copy {
	print `xdotool key Ctrl+c`;
}

sub return_clipboard {
	return `xsel -o`;
}

sub click {
	print `xdotool click 1`;
}

sub type {
	my ( $self, $string ) = @_;
	print `xdotool type "$string"`;
}

sub type_enter {
	my ( $self, $string ) = @_;
	$self->type( $string );
	print `xdotool key Return`;
}

sub xdo_key {
	my ( $self, $key ) = @_;
	return `xdotool key $key`;
}

sub play_sound {
	my ( $self, $path ) = @_;
	$path ||= '/usr/share/sounds/Oxygen-Im-Nudge.ogg';
	`cvlc $path vlc://quit &`;
}

sub play_end_sound {
	my ( $self ) = @_;
	$self->play_sound( '/usr/share/sounds/Oxygen-Sys-App-Positive.ogg' );

}

sub move_to {
	my ( $self, $xy, $zero ) = @_;
	if ( $zero ) {
		print `xdotool mousemove $zero->[0] $zero->[1]`;
		print `xdotool mousemove_relative $xy->[0] $xy->[1]`;
	} else {
		print `xdotool mousemove $xy->[0] $xy->[1]`;
	}
}

sub get_colour_at_coordinates {
	my ( $self, $xy ) = @_;
	my ( $x, $y )     = @{$xy};
	my $output = `import -window root -depth 8 -crop 1x1+$x+$y txt:-`;
	my @values = split( '  ', $output );
	print "Found colour [$values[1]] at coordinates [$x,$y]$/";
	return $values[1];
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
