package Moose::Meta::Method::Accessor::Native::String::inc;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::String::Writer';

sub _minimum_arguments { 0 }
sub _maximum_arguments { 0 }

sub _potential_value {
    my ( $self, $slot_access ) = @_;

    return "( do { my \$val = $slot_access; \$val++ } )";
}

sub _inline_optimized_set_new_value {
    my ( $self, $inv, $new, $slot_access ) = @_;

    return "${slot_access}++;";
}

1;
