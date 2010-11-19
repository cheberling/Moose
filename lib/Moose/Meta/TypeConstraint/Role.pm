package Moose::Meta::TypeConstraint::Role;

use strict;
use warnings;
use metaclass;

use Scalar::Util 'blessed';
use Moose::Util::TypeConstraints ();

our $VERSION   = '1.20';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use base 'Moose::Meta::TypeConstraint';

__PACKAGE__->meta->add_attribute('role' => (
    reader => 'role',
));

sub new {
    my ( $class, %args ) = @_;

    $args{parent} = Moose::Util::TypeConstraints::find_type_constraint('Object');
    my $self      = $class->_new(\%args);

    $self->_create_hand_optimized_type_constraint;
    $self->compile_type_constraint();

    return $self;
}

sub _create_hand_optimized_type_constraint {
    my $self = shift;
    my $role = $self->role;
    $self->hand_optimized_type_constraint(
        sub { Moose::Util::does_role($_[0], $role) }
    );
}

sub parents {
    my $self = shift;
    return (
        $self->parent,
        map {
            # FIXME find_type_constraint might find a TC named after the role but that isn't really it
            # I did this anyway since it's a convention that preceded TypeConstraint::Role, and it should DWIM
            # if anybody thinks this problematic please discuss on IRC.
            # a possible fix is to add by attr indexing to the type registry to find types of a certain property
            # regardless of their name
            Moose::Util::TypeConstraints::find_type_constraint($_)
                ||
            __PACKAGE__->new( role => $_, name => "__ANON__" )
        } @{ Class::MOP::class_of($self->role)->get_roles },
    );
}

sub equals {
    my ( $self, $type_or_name ) = @_;

    my $other = Moose::Util::TypeConstraints::find_type_constraint($type_or_name);

    return unless defined $other;
    return unless $other->isa(__PACKAGE__);

    return $self->role eq $other->role;
}

sub is_a_type_of {
    my ($self, $type_or_name) = @_;

    my $type = Moose::Util::TypeConstraints::find_type_constraint($type_or_name);

    ($self->equals($type) || $self->is_subtype_of($type_or_name));
}

sub is_subtype_of {
    my ($self, $type_or_name_or_role ) = @_;

    if ( not ref $type_or_name_or_role ) {
        # it might be a role
        return 1 if Class::MOP::class_of($self->role)->does_role( $type_or_name_or_role );
    }

    my $type = Moose::Util::TypeConstraints::find_type_constraint($type_or_name_or_role);

    return unless defined $type;

    if ( $type->isa(__PACKAGE__) ) {
        # if $type_or_name_or_role isn't a role, it might be the TC name of another ::Role type
        # or it could also just be a type object in this branch
        return Class::MOP::class_of($self->role)->does_role( $type->role );
    } else {
        # the only other thing we are a subtype of is Object
        $self->SUPER::is_subtype_of($type);
    }
}

sub create_child_type {
    my ($self, @args) = @_;
    return Moose::Meta::TypeConstraint->new(@args, parent => $self);
}

1;

__END__

=pod

=head1 NAME

Moose::Meta::TypeConstraint::Role - Role/TypeConstraint parallel hierarchy

=head1 DESCRIPTION

This class represents type constraints for a role.

=head1 INHERITANCE

C<Moose::Meta::TypeConstraint::Role> is a subclass of
L<Moose::Meta::TypeConstraint>.

=head1 METHODS

=over 4

=item B<< Moose::Meta::TypeConstraint::Role->new(%options) >>

This creates a new role type constraint based on the given
C<%options>.

It takes the same options as its parent, with two exceptions. First,
it requires an additional option, C<role>, which is name of the
constraint's role.  Second, it automatically sets the parent to the
C<Object> type.

The constructor also overrides the hand optimized type constraint with
one it creates internally.

=item B<< $constraint->role >>

Returns the role name associated with the constraint.

=item B<< $constraint->parents >>

Returns all the type's parent types, corresponding to the roles that
its role does.

=item B<< $constraint->is_subtype_of($type_name_or_object) >>

If the given type is also a role type, then this checks that the
type's role does the other type's role.

Otherwise it falls back to the implementation in
L<Moose::Meta::TypeConstraint>.

=item B<< $constraint->create_child_type(%options) >>

This returns a new L<Moose::Meta::TypeConstraint> object with the type
as its parent.

Note that it does I<not> return a C<Moose::Meta::TypeConstraint::Role>
object!

=back

=head1 BUGS

See L<Moose/BUGS> for details on reporting bugs.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2010 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
