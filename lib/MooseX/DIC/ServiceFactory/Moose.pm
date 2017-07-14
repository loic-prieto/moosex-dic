package MooseX::DIC::ServiceFactory::Moose;

use Moose;
with 'MooseX::DIC::ServiceFactory';

use aliased 'MooseX::DIC::UnregisteredServiceException';
use aliased 'MooseX::DIC::ContainerConfigurationException';
use aliased 'MooseX::DIC::ServiceCreationException';
use Try::Tiny;

has container => ( is => 'ro', does => 'MooseX::DIC::Container', required => 1);

sub build_service {
  my ($self,$class_name) = @_;

  # Build the to-be-injected dependencies of
  # the object
  my $meta = $class_name->meta;
  my %dependencies = ();

  foreach	my $attribute ( $meta->get_all_attributes) {
    if($attribute->does('MooseX::DIC::Injected')) {
      my $dependency = $self->fetch_service_for($attribute);
      ContainerConfigurationException->throw(message => "A dependency ".$attribute->name." could not be injected in $class_name") unless $dependency;
      $dependencies{$attribute->name} = $dependency;
    }
  }

  my $service;
  try {
    $service = $class_name->new(%dependencies);
  } catch {
    MooseX::DIC::ServiceCreationException->throw( 
      message => "Error while building an injected service: $_"
    );
  };

  return $service;
}

sub fetch_service_for {
  my ($self,$attribute) = @_;

  my $dependency;

  if($attribute->does('MooseX::DIC::Injected')){
    my $service_type = $attribute->type_constraint->name;
    
    if($attribute->scope eq 'object') {
      $dependency = $self->container->get_service( $service_type );
      UnregisteredServiceException->throw(service=>$service_type) unless $dependency;
    } elsif ($attribute->scope eq 'request') {
      my $factory = sub {
        my $service = $self->container->get_service($service_type);
        UnregisteredServiceException->throw(service=>$service_type) unless $service;

        return $service;
      };

    } else {
      ContainerConfigurationException->throw(message => "An injection point can only be of type 'object' or 'request'");
    }
  }

  return $dependency;

}

1;
