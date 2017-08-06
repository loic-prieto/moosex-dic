package MooseX::DIC::Config::CodeScan;

use Moose;
with 'MooseX::DIC::ConfigBuilder';

use MooseX::DIC::Scanner::InjectableScanner 'fetch_injectable_packages_from_path';
use aliased 'MooseX::DIC::Container::DefaultImpl';

sub build_from_path {
	my ($self,$path) = @_;

	my $container = DefaultImpl->new;

	my @injectable_packages = fetch_injectable_packages_from_path( $options{scan_path} );
    foreach my $injectable_package (@injectable_packages) {
        $container->register_service($injectable_package);
    }
}

1;
