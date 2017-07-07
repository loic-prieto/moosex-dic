package MooseX::DIC::ServiceFactory::Moose;

use Moose;
with 'MooseX::DIC::ServiceFactory';

use aliased 'MooseX::DIC::UnregisteredServiceException';
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
			# This assumes that the attribute injected has a 'does'
			# that is directly the name of an existing role.
			my $service_type = $attribute->type_constraint->name;
			
			# The following assignemnt assumes that all possible services have
			# been registered.
			my $dependency = $self->container->get_service( $service_type );
			UnregisteredServiceException->throw(service=>$service_type) unless $dependency;
			
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

1;
