package MooseX::DIC::YAMLConfigParser;

use YAML::XS;
use aliased 'MooseX::DIC::ContainerConfigurationException';

sub build_config_object_from_file {
	my ($config_file) = @_;

	ContainerConfigurationException->throw(message=>"Specified config file $config_file not found")
		unless -f $config_file;
	
	my $raw_config = Load $config_file;
}

1;
