package MooseX::DIC::YAMLConfigParser;

use YAML::XS;
use File::Spec::Functions;
use aliased 'MooseX::DIC::ContainerConfigurationException';
use aliased 'MooseX::DIC::ServiceMetadata';

sub build_services_metadata_from_config_file {
	my ($config_file) = @_;

	ContainerConfigurationException->throw(message=>"Specified config file $config_file not found")
		unless -f $config_file;
	
	my $raw_config = Load $config_file;

	# Load included files, to be applied later
	my @included_files = ();
  push @included_files,@{$raw_config->{include}} if exists($raw_config->{include});
	
	my @services_metadata = ();
  while(my ($interface,$implementators) = each(%{$raw_config->{mappings}})) {
    while( my ($implementator,$definition) = each(%$implementators)) {
      my $service_metadata = ServiceMetadata->new(
        class_name => $implementator,
        implements => $interface,
        (exists($definition->{scope})? (scope => $definition->{scope}):())
        (exists($definition->{builder})? (builder => $definition->{builder}):())
        (exists($definition->{environment})? (environment => $definition->{environment}):())
        (exists($definition->{qualifiers})? (qualifiers => $definition->{qualifiers}):())
      );

      push @services_metadata, $service_metadata;
    }
  }

  # Load include files
  push @services_metadata,
    map { build_services_metadata_from_config_file($_) }
    map { normalize_included_file_path($config_file,$_) }
    @included_files;

	return @services_metadata;
}

sub normalize_included_file_path {
  my ($original_file,$included_file) = @_;
  my ($volume,$path,$file) = splitpath($original_file);

  return rel2abs($included_file,$path);
}

1;
