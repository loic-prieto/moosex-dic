package MooseX::DIC::YAMLConfigParser;

use YAML::XS;
use aliased 'MooseX::DIC::ContainerConfigurationException';

sub build_services_metadata_from_config_file {
	my ($config_file) = @_;

	ContainerConfigurationException->throw(message=>"Specified config file $config_file not found")
		unless -f $config_file;
	
	my $raw_config = Load $config_file;

	# Load included files, to be applied later
	my @included_files = ();
	
	my @services_metadata = ();

	return @services_metadata;
}

1;
