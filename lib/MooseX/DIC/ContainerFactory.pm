package MooseX::DIC::ContainerFactory;

use Moose;

use aliased 'MooseX::DIC::Container::DefaultImpl';
use MooseX::DIC::Scanner::InjectableScanner 'fetch_injectable_packages_from_path';

has environment => (is => 'ro', isa => 'Str', default => 'default' );
has scan_path => ( is => 'ro', isa => 'HashRef[Str]', required => 1 );

sub build_container {
	my ($self) = @_;
	my $container = DefaultImpl->new( environment => $self->environment );

	# Code scan
	
}

sub _apply_code_config_to {
	my ($self,$container) = @_;

	my @injectable_packages = fetch_injectable_packages_from_path( $self->scan_path );
    foreach my $injectable_package (@injectable_packages) {
        $container->register_service($injectable_package);
    }
}

sub _apply_file_config_to {
	my ($self,$container) = @_;
}

1;
