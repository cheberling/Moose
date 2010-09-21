package Moose::Meta::Method::Accessor::Native::Array::splice;

use strict;
use warnings;

our $VERSION = '1.13';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::Method::Accessor::Native::Array::Writer';

sub _minimum_arguments { 1 }

sub _adds_members { 1 }

sub _inline_process_arguments {
    return 'my $idx = shift;' . "\n" . 'my $len = @_ ? shift : undef;';
}

sub _inline_check_arguments {
    my $self = shift;

    return
          $self->_inline_check_var_is_valid_index('$idx') . "\n"
        . $self->_inline_throw_error(q{'The length argument passed to splice must be an integer'})
        . ' if defined $len && $len !~ /^-?\\d+$/;';
}

sub _potential_value {
    my ( $self, $slot_access ) = @_;

    return "( do { my \@potential = \@{ $slot_access };"
        . 'defined $len ? ( splice @potential, $idx, $len, @_ ) : ( splice @potential, $idx ); \\@potential } )';
}

sub _inline_optimized_set_new_value {
    my ( $self, $inv, $new, $slot_access ) = @_;

    return "defined \$len ? ( splice \@{ $slot_access }, \$idx, \$len, \@_ ) : ( splice \@{ $slot_access }, \$idx );";
}

1;
