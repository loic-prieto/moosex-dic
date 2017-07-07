package MooseX::DIC::ServiceMetadata;

use MooseX::DIC::Types;

use Moose;

has class_name  => ( is => 'ro', isa => 'ClassName', required => 1 );
has implements  => ( is => 'ro', isa => 'RoleName', predicate => 'has_implements' );
has scope       => ( is => 'ro', isa => 'ServiceScope', required => 1 );
has qualifiers  => ( is => 'ro', isa => 'ArrayRef[Str]', required => 0 );
has environment => ( is => 'ro', isa => 'Str', default => 'default' );
has builder     => ( is => 'ro', isa => 'Str', required => 1);

1;
