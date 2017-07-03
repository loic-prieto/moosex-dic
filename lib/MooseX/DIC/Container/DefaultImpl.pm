package MooseX::DIC::Container::DefaultImpl;

use MooseX::DIC::Types;
use List::Util 'reduce';
use Module::Load 'load';
use aliased 'MooseX::DIC::PackageIsNotServiceException';
use aliased 'MooseX::DIC::FunctionalityNotImplementedException';
use aliased 'MooseX::DIC::ContainerConfigurationException';
use aliased 'MooseX::DIC::UnregisteredServiceException';

use Moose;
with 'MooseX::DIC::Container';

has singletons => ( is => 'ro', isa => 'HashRef[Injectable]', default => sub { {} } );
has services => ( is => 'ro', isa => 'HashRef[MooseX::DIC::Container::ServiceMetaInformation]', default => sub {{}});

sub get_service {
    my ($self,$package_name) = @_;

    # Check it is a registered service
    my $service_meta = $self->services->{$package_name};
    UnregisteredServiceException->throw( service => $package_name) unless $service_meta;

    my $service;

    # If it is a singleton, there's a chance it has already been built
    if($service_meta->scope eq 'singleton') {
        $service = $self->singletons->{$package_name};
    }
    return $service if $service;

    $service = $service_meta->build($self);
    if($service_meta->scope eq 'singleton') {
        $self->singletons->{$package_name} = $service;
    }

    return $service;
}

sub register_service {
    my ($self,$package_name) = @_;

    # Make sure the the package is loaded
    load $package_name;
	
    # Check the package is an Injectable class
    my $injectable_role =
        reduce { $a }
        grep { ref $_ eq 'Injectable'}
        $package_name->meta->calculate_all_roles_with_inheritance;
    PackageIsNotServiceException->throw unless defined $injectable_role;
    
    # Get the meta information from the injectable role
    my $meta = $package_name->meta->get_service_metadata;
    ContainerConfigurationException->throw(message=>"The package $package_name is not propertly configured for injection")
	    unless $meta;

    # Build the implements info if it doesn't exist
    unless($meta->has_implements){
        FunctionalityNotImplementedException->throw( message => 'Injectable services must declare what interface they implement');
    }

    # Until qualifiers are implemented, check the service has not already been
    # registered for the implemented interface
    if(exists $self->services->{$meta->implements}) {
        ContainerConfigurationException->throw(
            message => 'A service has already been declared for the Interface '.$meta->implements);
    }

    # Associate the service meta information to the interface this service implements
    $self->services->{$meta->implements} = $meta;
    
}

1;
