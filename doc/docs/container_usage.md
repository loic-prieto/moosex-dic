# Container usage

## Initializing the container

### Initializing the container by scanning a folder

A container holds a registry of mappings between service interfaces and
candidate implementations. Your code can then request to the container an
instance of a service by it's interface.
The container will take care of instancing the implementation class with all
the dependencies of that service initialized too.

To build a registry, it must be initalized with a configuration, which may be
built by scanning a series of folders and finding which classes are injectable 
services. Or it can receive a config file and build it's registry from there.

As of now, scanning classes is the only implemented method of building the 
registry.

So, without further ado, let's initialize a container:

```perl
#!/usr/bin/env perl
use strict;
use warning;

use MooseX::DIC 'build_container';

my $container = build_container( scan_path => [ 'lib' ] );

# The launcher is a fully injected service, with all dependencies
# provided by the container.
my $app = $container->get_service 'MyApp::Launcher';
$app->start;

exit 0;
```

The container will scan all files inside the lib folder and it's subfolders
looking for files that declare to be injectable MooseX::DIC services and adding
them to the service registry.

So, let's imagine that we have the following two files inside the lib folder:

```perl
lib/MyApp/AuthService.pm
package MyApp::AuthService {
    use Moose::Role;

    requires 'login';
}

lib/MyApp/AuthService/LDAP.pm
package MyApp::AuthService::LDAP {

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

    sub login {
        # does something
    }

}
```

The registry will have registered a MyApp::AuthService::LDAP service that will
be provided by the container when someone asks for a MyAuth::Service. Like so:

```perl
my $container = build_container( scan_path => [ 'lib' ] );
my $auth_service = $container->get_service('MyApp::AuthService');
$auth_service->login('username','lolsecret');
```

What's even more interesting, the MyAPP::AuthService::LDAP instance that has
been created by the container has it's ldap dependency initialized too (
assuming it has been declared as an injectable service too).

### Initializing the container by scanning multiple folders

The registry, when built by scanning a folder, can be made to scan many other
folders. We may be interested, for example, to scan the classes both of our
application in lib and the classes of our dependencies, in local/lib/perl5 (
following Carton conventions).
That would be done like so:

```perl
my $container = build_container( scan_path => [ qw(lib local/lib/perl5) ] );
```

### Initializing the container by reading a config file

_This funcionality is not yet implemented_

## Using the container

Once a container has been initialized, either by scanning source folders or by
reading from a config file, it can be used to requests services:

```perl
my $auth = $container->get_service('MyApp::AuthService');
```

While this is the easiest way to use it, it's actually an antipattern
[Service Locator](http://blog.ploeh.dk/2010/02/03/ServiceLocatorisanAnti-Pattern/)

