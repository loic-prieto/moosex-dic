package MooseX::DIC::PackageNotFoundException;

use Moose;
use namespace::autoclean;
extends 'MooseX::DIC::ContainerException';

has package_name => ( is=>'ro', isa=>'Str', required => 1);
has '+message' => ( default => sub { "Package ".(shift->package_name)." was not found" } );

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

MooseX::DIC::PackageNotFoundException

=head1 DESCRIPTION

This exception is thrown when a package is being loaded and it could not be found.
