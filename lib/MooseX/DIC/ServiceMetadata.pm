package ServiceMetadata;

use MooseX::DIC::Types;

use Moose;

has implements => ( is => 'ro', isa => 'RoleName', predicate => 'has_implements' );
has scope => ( is => 'ro', isa => 'ServiceScope', required => 1 );
has qualifiers => ( is => 'ro', isa => 'ArrayRef[Str]', required => 0 );
has environment => ( is => 'ro', isa => 'Str', default => 'default' );
has builder => ( is => 'ro', does => 'MooseX::DIC::ServiceFactory', required => 1);

1;
