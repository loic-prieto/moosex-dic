# MooseX::DIC

## Description

MooseX::DIC is a dependency injection container tailored to [Moose](https://metacpan.org/pod/Moose), living in a full OOP environment and greatly
inspired by Java DIC frameworks like [Spring](https://docs.spring.io/spring/docs/current/spring-framework-reference/html/beans.html)
or [CDI](http://docs.oracle.com/javaee/6/tutorial/doc/gjbnr.html).

The goal of this library is to provide an easy to use DI container without configuration files and with automatic wiring
of dependencies via constructor by class type (ideally by Role/Interface).

The configuration is performed by the use of [Marker roles](https://en.wikipedia.org/wiki/Marker_interface_pattern) and
a specific trait on attributes that have to be injected.

One of the principal tenets of the library is that while code may be poluted by the use of DIC roles and traits, it
should work without a running container. The classes are fully functional without the dependency injection, the library
is just a convenient way to wire dependencies (this is mainly accomplished by forbidding non [constructor injection](https://en.wikipedia.org/wiki/Dependency_injection#Constructor_injection)).

This library is designed to be used on long-running processes where startup time is not a concern (within reason, of
course). The container will scan all configured paths to look for services to inject and classes that need injection.

There is a great amount of flexibility to account for testing environments, non-moose libraries, alternative
implementations of services, etc, although none of it is needed for a simple usage.

# Synopsis

A service is injectable if it consumes the Role [MooseX::DIC::Injectable](https://metacpan.org/pod/MooseX::DIC::Injectable), which is a parameterized role.

```perl
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
```

We can see that this service is both an injectable service and consumes another injectable service,LDAP. We register a
class as injectable into the container registry by consuming the [MooseX::DIC::Injectable](https://metacpan.org/pod/MooseX::DIC::Injectable) role, and we get injected
dependencies by using the *Injected* trait.

None of the parameters of the [MooseX::DIC::Injectable](https://metacpan.org/pod/MooseX::DIC::Injectable) role are mandatory, they have defaults or can be inferred.
On the example above, the role/interface the LDAPAuthService was implementing could be inferred from the
`with 'MyApp::AuthService'` previous line.

To use this service:

```perl
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
``` 

Here we made use of the exported `injected` function from the [MooseX::DIC](https://metacpan.org/pod/MooseX::DIC) package to define the traits, a little
syntactic sugar if you only use the Injected trait.

# Starting the Container

The container is a singleton for the running process. It is shared between all Moose classes. This makes it inherently
unsafe to use in threads, specially if you're registering new mappings on runtime.

When starting your application, the container must be launched to start it's scanning. All packages under the libpath
will be scanned, which means all packages under the libpath will be loaded. Take this into account for the memory
consumption of the program and the starting time delay. You can specify which folders to scan instead of the whole
libpath, which should greatly reduce startup time if you have a lot of dependencies and you are only interested in
injecting your classes.

To start the container:

```perl
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
```

# Advanced use cases

## Scopes

### Service scope

Although the vast majority of services we want to inject are by their stateless nature candidates to be singletons, we
may want for our service to be instantiated every time they are requested. For example, an http agent could be
instantiated once per service.

```perl
package MyApp::LWPHTTPAgent;

use LWP::UserAgent;

use Moose;
with 'MyApp::HTTPAgent';
with 'MooseX::DIC::Injectable' => { scope => 'request' };

has ua => ( is => 'ro', isa => 'LWP::UserAgent', default => sub { LWP::UserAgent->new; } );

sub request {
	$self->ua->request(shift);
}

1;
```

This service declares that it can be injected on attributes that need an object that does 'MyApp::HTTPAgent' and that
each time it is called, it will be created anew. To use it:

```perl
package MyApp::RESTUserService;

use Moose;
with 'MyApp::UserService';

has http_client => ( is => 'ro', does => 'MyApp::HTTPAgent', traits => [ 'Inject' ] );

sub persist {
	my ($self,$user) = @_;

	# A new instance is created here and lives for as long as
	# the RESTUserService lives.
	$self->http_client->request(...);
}
```

Two types of scope are available for services:

* singleton: The default scope, the registry will only keep one copy of the service and will inject it into every attribute it is
requested.
Make sure the service is stateless or you will run into race conditions.
* request: Each time the service is requested, a new instance of it will be created. Useful for stateful services.

### Injection scope

For services which are request scoped, the requester can also ask the injection container to create a new service each
time the accessor is used, for stateful services that should only live once per use. For example, we may be interested
in using an http user agent that somehow keeps some states between callings and if used for different purposes would be
corrupted.

```perl
package MyApp::RESTUserService;

use Moose;
with 'MyApp::UserService';

has http_client => ( is => 'ro', does => 'MyApp::HTTPAgent', scope => 'request', traits => [ 'Inject' ] );

sub persist {
	my ($self,$user) = @_;

	# A new instance of MyApp::LWPHTTPAgent is created here
	$self->http_client->request(...);

	# Yet another instance of MyApp::LWPHTTPAgent is created again
	$self->http_client->request(...);

	# If we want to keep the same instance for a series of calls, reference it.
	my $ua = $self->http_client;
	$ua->request(...);
	$ua->request(...);
}
```

There are two scopes available for the injection scope:

* object: The default scope. For request scoped services, the service is instantiated once per object.
* request: For request scoped services, if the injection scope is request too, an accessor is created that will fetch a new
instance of the service each time it is called.

The injection scope only makes sense for request scoped services, since singleton services will only be instantiated
once.

It is a configuration error to ask for a singleton scoped service into a request-scoped injection point, and the
container will generate an exception when it encounters this situation (in the spirit of detecting errors as soon as
possible).

## Qualifiers

### Qualifiers usage

Sometimes, we want a Role/Interface to be implemented by many classes and to let the caller specify which one it wants.

While this would seem to oppose the very idea of letting a container to give you objects, in fact it doesn't, and gives
a great deal of flexibility while still allowing the container to choose the best implementator for your caller and
initialize it.

Qualifiers let a service specify with a more fine-grained precision how they implement an interface, so that callers can
choose them based on those qualifiers.

For example, we can have two implementators of an HTTPAgent service:

```perl
package MyApp::LWPHTTPAgent;

use Moose;
with 'MyApp::HTTPAgent';

with 'MooseX::DIC::Injectable' => { qualifiers => [ 'sync' ] };

sub request {
	# returns the response
}


package MyApp::AsyncHTTPAgent;
use Moose;
with 'MyApp::HTTPAgent';

with 'MooseX::DIC::Injectable' => { qualifiers => [ 'async' ] };

sub request {
	# returns a Promise with the response
}

package MyApp::RESTUserService;

use Moose;
use MooseX::DIC;

has http_client => ( is => 'ro', does => 'MyApp::HTTPAgent', qualifiers => [ 'async' ], inject);

sub persist {
	# This service knows it can expect a Promise result
	# from the http agent, since it asked for the async version.
	return $self->http_client->request(...)
		->then(sub {
			...
		})
		->catch(sub {
			...
		});
}
```

It is a configuration error to have two implementators of the same service living in the same *environment* without at 
least one of them having a qualifier, and the container will generate an exception when it encounters that situation.

### Qualifiers match resolution

When there are competing implementators for the same caller, which have different qualifiers, the resolution is based
on the following rule: The longest most precise qualifier match is returned

If the caller requests for qualifiers 'a','b' and 'c', given the following service implementations:

* Impl1 => qualifiers 'a','d'
* Impl2 => qualifiers 'b', 'c'
* Impl3 => qualifiers 'a'

The implementator Impl2 will be selected, since it has the greater number of matching qualifiers.

If no exact qualifier match is found, the next best match is selected. Example:

Given a caller that requests a Service with qualifiers 'a', 'b', and 'c'. For the following implementations:

* Impl1 => qualifiers 'a'
* Impl2 => no qualifiers

The Impl1 will be selected even though it doesn't match all caller qualifiers.

Given a caller that requests a Service with qualifiers and only one implementator with no qualifiers, the implementator
will still be selected.

Given a caller that requests a Service with qualifier 'a', for the following implementations:

* Impl1 => qualifier 'b'
* Impl2 => qualifier 'c'
* Impl3 => no qualifiers

One of the three implementations (always randomly) will be returned, since they are all equal matches. The random
selection will be enforced to avoid library clients shooting themselves on the foot by relying on a specific selection
when there are equal matches.

Following the last example, if a client specifically wants an implementation with no qualifiers it can specify it by
setting the qualifier parameter of the attribute to empty array:

```perl
package MyApp::ExampleController;

use Moose;
use MooseX::DIC;

has service => ( is => 'ro', does => 'ServiceRole', qualifiers => [], inject );
```

## Environments

Sometimes, we want the wiring of services to depend on a runtime environment. To this end, we use the concept of
environments.

By default (that is, if no environment is declared by an *Injectable* service) all services live inside the 'default'
environment. But we can do more. Let's consider the following services:

```perl
package MyApp::UserRepository;

use Moose::Role;


package MyApp::UserRepository::Database;

use Moose;
with 'MyApp::UserRepository';

with 'MooseX::DIC::Injectable' => { environment => 'production' };


package MyApp::UserRepository::InMemory;

use Moose;
with 'MyApp::UserRepository';

with 'MooseX::DIC::Injectable' => { environment => 'test' };
```

With the following caller:

```perl
package MyApp::UserController;

use Moose;
use MooseX::DIC;

has repository => (is => 'ro', does => 'MyApp::UserRepository', inject );

sub do_something {
	my ($self,$user) = @_;
	$self->repository->persist($user);
}
```

These implementations live in different environments and they won't see each other. The selection of one or the other
will depend on which environment we launch the container in, as in:

```perl
#!/usr/bin/env perl
use strict;
use warning;

use MooseX::DIC;
use MyApp::UserController;

start_container( environment => 'test' );

$user = { name => 'loic', email => 'loic.sephiroth@gmail.com' };

# In the test environment, the UserController class will have received
# The InMemory user repository.
my $user_controller = MyApp::UserController->new;
```

When the container doesn't find a service in a given environment, it will fall back to the default environment. If it
doesn't find a service there, it will throw an exception.
