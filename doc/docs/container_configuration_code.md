# Container configuration by Code

There are two ways to configure the container in MooseX::DIC:

- The first one involves using marker interfaces to declare moose classes as
implementations of a service.
- The second one involves creating a configuration file in YAML where the wiring
between services and implementations are declared manually.

## Configuration by Code

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

### Environments

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

### Scopes
