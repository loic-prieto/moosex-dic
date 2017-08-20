# Container configuration by code

There are two ways to configure the container in MooseX::DIC:

- The first one involves using marker interfaces to declare moose classes as
implementations of a service.
- The second one involves creating a configuration file in YAML where the wiring
between services and implementations are declared manually.

When configuring wiring for the dependency injection, there is always an interface
/ Role that is to be implemented. It is the contract of the service. For example:

```perl
package MyApp::LoginService;

use Moose::Role;

# (Str,Str) -> Bool
requires 'login';
```

Then, one class or many will implement this interface, like so:

```perl
package MyApp::LoginService::LDAP;

use Moose;
with 'MyApp::LoginService';

has ldap => ( is=>'ro', isa => 'LDAP', required => 1);

sub login {
  my ($self,$user,$password) = @_;
  return $self->ldap->authenticate($user,$password);
}
```

How do these two packages, contract and implementation get binded by the container?

By use of the MooseX::DIC::Injectable marker role, applied to the implementing class
like so:

```perl
package MyApp::LoginService::LDAP;

use Moose;
with 'MyApp::LoginService';

with 'MooseX::DIC::Injectable' => { implements => 'MyApp:LoginService' }

has ldap => ( is=>'ro', isa => 'LDAP', required => 1);

sub login {
  my ($self,$user,$password) = @_;
  return $self->ldap->authenticate($user,$password);
}
```

This role let's the container know, when scanning this class, that this class 
implements the contract of the service MyApp::LoginService. When requesting,
then, from the container, a service for MyApp::LoginService, the container
will return the MyApp::LoginService::LDAP class.

```perl
my $login_service = $container->get_service('MyApp::LoginService');
my $login_result = $login_service->login('username','secret');
```

That's it, there's nothing more to configure. You just have to point the
container to a folder that contains this class (directly or traversing it's
subfolders), and then it is ready to use.

```perl
use MooseX::DIC 'build_container';

my $container = build_container( scan_path => ['lib'] );

my $login_service = $container->get_service('MyApp::LoginService');
```

There are more advanced configuration settings that can be declared in the
MooseX::DIC::Injectable parameterized role, which we will review shortly bellow.

Each advanced use case will be explained in full in it's own section.

## Environments

By default, all mappings between services and implementing classes are linked to
a 'default' environment. But more environments can exist, where different mappings
can be declared.

For example, for our 'production' environment, we may want the MyApp::LoginService::LDAP
class to be used to implement the MyApp::LoginService, but for a 'development' environment
we may want a simple MyApp::LoginService::InMemory class that only checks a fixed list
of credentials.

This way, you can still use the convenience of a container in different environments, such
as unit testing, integration testing, development or production.

A container, when scanning the lib folders, will create it´s registry of mappings, and this
registry links a mapping to an environment. Then, when the container is ready to be used, it 
is configured to serve in an environment.

```perl
package MyApp::LoginService::InMemory;

use Moose;
with 'MyApp::LoginService';

with 'MooseX::DIC::Injectable' => { implements => 'MyApp::LoginService', environment=>'development' };

sub login {
  my ($self,$user,$password) = @_;

  return 1 if ($user eq 'test' and $password eq 'test');

  return 0;
}
```

```perl
use MooseX::DIC 'build_container';

my $container = build_container( scan_path => [ 'lib' ], environment => [ 'development' ] );
my $login_service = $container->get_service 'MyApp::LoginService';
my $login_result = $login_service->login('test','test');
```

## Scopes

There are two sets of scopes, closely related:

- Service scopes
- Injection scopes

These scopes modify the lifecycle of a service when requested as a dependency.

### Service scopes

A service must have a scope. By default, the scope is 'singleton'. This means that the service and its
dependencies are created only once inside the container and then reused each time. It's. in effect, a
singleton service. Only stateless service classes are recommended to be singleton services, since having
state would create race conditions on these kind of services.

If a service is stateful, then it is of type 'request', meaning that a service of that type is built each
time it is requested. This can be useful for services that need to hold state to work, and that can operate
in a session-like manner, or services that need specific parameters to work per request and wouldn't make 
sense configured in a global manner for the whole application.

```perl
package MyApp::LoginService::RDB;

use Moose;
with 'MyApp::LoginService';

# The scope configuration here is redundant, since this is
# the default value.
with 'MooseX::DIC::Injectable' => { scope => 'singleton', qualifiers => [ 'db' ] };

has db => ( is=>'ro', does => 'MyApp::DB', required => 1 );

sub do_login { ... }
```

```perl
package MyApp::LoginService::LDAP;

use Moose;
with 'MyApp::HTTPClient';

with 'MooseX::DIC::Injectable' => { scope => 'singleton', qualifiers => [ 'ldap' ] };

has ldap => ( is=>'ro', does => 'LDAP', required => 1 );

sub do_login { ... }
```

Given these two service definitions, the MyApp::LoginService::RDB will be created only
once in the container and served each time it is requested. For example:

```perl
package MyApp::LoginController;

use Moose;
use MooseX::DIC;

# The login service will be created only once, and that same instance is injected here
has login_service => ( is=>'ro', does => 'MyApp::LoginService', qualifiers => [ 'db' ], injected );

sub login {
	$self->login_service->do_login(...);
}

```

As for the LDAP service, imagining that the LDAP service somewhow has to keep state that is not
transferable between different consumers, we would use it much the same:

```perl
package MyApp::LoginController;

use Moose;
use MooseX::DIC;

# The ldap login service will be created every time it is injected
has login_service => ( is=>'ro', does => 'MyApp::LoginService', qualifiers => [ 'ldap' ], injected );

sub login {
	$self->login_service->do_login(...);
}

```

The consumer won't know, nor does it care, the difference.

### Injection scopes

A consumer can declare a dependency to be injected in two ways:

- once (object)
- every time it is called (request)

What this means is that when the container injects the service as a dependency of the consumer, it will
do so either one time, while building that service, or every time the consumer calls the accessor of the
dependency.

The latter only makes sense for services that are request scoped, since otherwise the container would
always inject the same object anyways. Indeed, requesting that a singleton object be request-injected is
a configuration error that will raise an exception.

Examples:
```perl
package MyApp::LoginService::REST;

use Moose;
with 'MyApp::LoginService';

# This service is singleton scoped, the default
with 'MooseX::DIC::Injectable';

sub do_login { ... }


package MyApp::LoginController;

use Moose;
use MooseX::DIC;

# The injection scope configuration is redundant here, because it is the default
has login_service => ( is=>'ro', does=>'MyApp::LoginService', scope => 'object', injected );

sub login { ... }
```

```perl
package MyApp::HTTPClient::LWP;

use Moose;
with 'MyApp::HTTPClient';

with 'MooseX::DIC::Injectable' => { scope => 'request' };

sub post { ... }


package MyApp::LoginController;

use Moose;

has http_client => ( is=>'ro', does=>'MyApp::HTTPClient', scope => 'request', injected );

sub login {
	
	# A new MyApp::HTTPClient::LWP is built here
	$self->http_client->post(...);

	# And here too
	$self->http_client->post(...);

	my $http1 = $self->http_client;
	my $http2 = $self->http_client;

	# $http1 != $http2
}
```

## Qualifiers (TBD)

Qualifiers are a feature that has to be implemented yet.
