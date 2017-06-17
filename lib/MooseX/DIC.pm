package MooseX::DIC;

1;

=head1 Name

MooseX::DIC

=head1 Description

MooseX::DIC is a dependency injection container tailored to L<Moose>, living in a full OOP environment and greatly inspired by Java DIC frameworks like L<Spring|https://docs.spring.io/spring/docs/current/spring-framework-reference/html/beans.html> or L<CDI|http://docs.oracle.com/javaee/6/tutorial/doc/gjbnr.html>.

The goal of this library is to provide an easy to use DI container without configuration files and with automatic wiring of dependencies via constructor by class type (ideally by Role/Interface).

The configuration is performed by the use of L<Marker roles|https://en.wikipedia.org/wiki/Marker_interface_pattern> and a specific trait on attributes that have to be injected.

One of the principal tenets of the library is that while code may be poluted by the use of DIC roles and traits, it should work without a running container. The classes are fully functional without the dependency injection, the library is just a convenient way to wire dependencies (this is mainly accomplished by forbidding non L<constructor injection|https://en.wikipedia.org/wiki/Dependency_injection#Constructor_injection>).

This library is designed to be used on long-running processes where startup time is not a concern (within reason, of course). The container will scan all configured paths to look for services to inject and classes that need injection.

There is a great amount of flexibility to account for testing environments, non-moose libraries, alternative implementations of services, etc, although none of it is needed for a simple usage.

=head1 Synopsis

A service is injectable if it consumes the Role L<MooseX::DIC::Injectable>, which is a parameterized role.

	package MyApp::LDAPAuthService;
	
	use Moose;
	with 'MyApp::AuthService';
	
	with 'MooseX::DIC::Injectable' => {
		implements  => 'MyApp::AuthService',
		qualifiers  => [ 'LDAP' ],
		environment => 'test',
		scope       => 'singleton'
	};

	has ldap => (
		is     => 'ro',
		does   => 'LDAP',
		traits => ['Injected']
	);

	1;

We can see that this service is both an injectable service and consumes another injectable service,LDAP. We register a class as injectable into the container registry by consuming the L<MooseX::DIC::Injectable> role, and we get injected dependencies by using the L<Injected> trait.

None of the parameters of the L<MooseX::DIC::Injectable> role are mandatory, they have defaults or can be inferred. On the example above, the role/interface the LDAPAuthService was implementing could be inferred from the C<with 'MyApp::AuthService'> previous line.

To use this service:

	package MyApp::LoginController;
	
	use Moose;
	use Moosex::DIC;

	has auth_service => ( is=>'ro', does => 'MyApp::AuthService', injected );

	sub do_login {
		my ($self,$request) = @_;
		
		if($self->auth_service->login($request->username,$request->password)) {
			print 'this is fine';
		}
	}

	1; 

Here we made us of the exported C<injected> function from the MooseX::DIC package to define the traits, a little syntactic sugar if you only use the Injected trait.

=head1 Starting the Container

The container is a singleton for the running process. It is shared between all Moose classes. This makes it inherently unsafe to use in threads, specially if you're registering new mappings on runtime.

When starting your application, the container must be launched to start it's scanning. All packages under the libpath will be scanned, which means all packages under the libpath will be loaded. Take this into account for the memory consumption of the program and the starting runtime. You can specify which folders to scan instead of the whole libpath, which should greatly reduce startup time if you have a lot of dependencies and you are only interested in injecting your classes.

To start the container:

	#!/usr/bin/env perl
	use strict;
	use warning;

	use MooseX::DIC 'start_container';
	use MyApp::Launcher;
	
	# This may take some seconds
	start_container;
	
	my $app = MyApp::Launcher->new;
	$app->start;

	exit 0;
	
	1;

=head1 Advanced use cases

=head2 Scopes

Although the vast majority of services we want to inject are by their stateless nature candidates to be singletons, we may want for our service to be instantiated every time they are requested. For example, a one-off  


