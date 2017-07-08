package MooseX::DIC::Injectable;

use MooseX::DIC::Types;
use aliased 'MooseX::DIC::ServiceMetadata';

use MooseX::Role::Parameterized;

parameter scope => ( isa => 'ServiceScope', default => 'singleton');
parameter environment => ( isa => 'Str', default => 'default');
parameter implements => ( isa => 'Str', predicate => 'has_implements' );
parameter qualifiers => ( isa => 'ArrayRef[Str]', default => sub { [] });

role {
  my ($p,%args) = @_;

  # Inject in the package metadata the mooseX metadata
  $args{consumer}->add_method( get_service_metadata => sub {
      return ServiceMetadata->new(
        class_name => $args{consumer}->{package},
        scope => $p->scope,
        environment => $p->environment,
        qualifiers => $p->qualifiers,
        implements => $p->implements,
        builder => 'Moose'
      );
    });
};

1;
