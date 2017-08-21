requires 'Moose';
requires 'MooseX::Role::Parameterized';
requires 'Throwable';
requires 'aliased';
requires 'Try::Tiny';
requires 'File::Find';
requires 'File::Slurper';
requires 'YAML::XS';
requires 'Log::Log4perl';
requires 'File::Spec';
requires 'Module::Load';
requires 'namespace::autoclean';
requires 'Exporter::Declare';

on 'test' => sub {
    requires 'Test::Spec';
};

on 'develop' => sub {
    requires 'Dist::Zilla';
    requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
    requires 'Dist::Zilla::Plugin::VersionFromModule';
    requires 'Dist::Zilla::PluginBundle::Git';
    requires 'Pod::Markdown';
};
