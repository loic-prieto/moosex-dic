package MooseX::DIC::ContainerFactory;

use Moose;
with 'MooseX::DIC::Loggable';

use aliased 'MooseX::DIC::Container::DefaultImpl';
use MooseX::DIC::Scanner::InjectableScanner 'fetch_injectable_packages_from_path';
use MooseX::DIC::Scanner::ConfigScanner 'fetch_config_files_from_path';
use List::Util 'reduce';
use Module::Load 'load';
use aliased 'MooseX::DIC::PackageIsNotServiceException';
use aliased 'MooseX::DIC::FunctionalityNotImplementedException';
use aliased 'MooseX::DIC::ContainerConfigurationException';
use MooseX::DIC::YAMLConfigParser 'build_services_metadata_from_config_file';

has environment => (is => 'ro', isa => 'Str', default => 'default' );
has scan_path => ( is => 'ro', isa => 'ArrayRef[Str]', required => 1 );

sub build_container {
	my ($self) = @_;

	# Build the registry
	$self->logger->debug("Building the registry for the container...");
	my $registry = MooseX::DIC::ServiceRegistry->new;
	$self->_apply_code_config_to($registry);
	$self->_apply_file_config_to($registry);
	
	# Build the container
	my $container = DefaultImpl->new( environment => $self->environment, registry => $registry );

	$self->logger->debug("The container has been built from the registry");
	return $container;
}

sub _apply_code_config_to {
	my ($self,$registry) = @_;

	my @injectable_packages = fetch_injectable_packages_from_path( $self->scan_path );
	$self->logger->debug("Adding ".@injectable_packages." packages to the registry...");

	$registry->add_service_definition($_) foreach
		map { $self->_get_meta_from_package($_) }
		@injectable_packages;
}

sub _get_meta_from_package {
	my ($self,$package_name) = @_;

	# Make sure the the package is loaded
	load $package_name;

	# Check the package is an Injectable class
	my $injectable_role = 
		reduce {$a}
		grep { $_->{package} eq 'MooseX::DIC::Injectable' }
		$package_name->meta->calculate_all_roles_with_inheritance;
	PackageIsNotServiceException->throw( package => $package_name )
		unless defined $injectable_role;

	# Get the meta information from the injectable role
	my $meta = $package_name->get_service_metadata;
	ContainerConfigurationException->throw( message =>
		"The package $package_name is not propertly configured for injection"
	) unless $meta;

	# Build the implements info if it doesn't exist (TBD)
	unless ( $meta->has_implements ) {
		FunctionalityNotImplementedException->throw( message =>
			'Injectable services must declare what interface they implement'
		);
	}	

	return $meta;
}

sub _apply_file_config_to {
	my ($self,$registry) = @_;

	$registry->add_service_definition($_) foreach
		map { build_services_metadata_from_config_file($_) }
		fetch_config_files_from_path($self->scan_path);
}

1;
