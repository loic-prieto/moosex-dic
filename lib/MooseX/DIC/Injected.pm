package MooseX::DIC::Injected;

use Moose::Role;
Moose::Util::meta_attribute_alias('Injected');

has qualifiers => ( is=>'ro', isa => 'ArrayRef[Str]', default => sub { [] } );

1;
