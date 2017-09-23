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

    with 'MooseX::DIC::Injectable' => { implements  => 'MyApp::AuthService' };

    has ldap => (
        is     => 'ro',
        does   => 'LDAP'
    );

    sub login {
        # does something with the ldap service injected
		# into this class
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
assuming it has been declared as an injectable service somewhere else too).

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

Instead of scanning source folders for classes, and detecting injectable 
services, we can create yaml config files for our mappings. When scanning
for source folders, the container will process any file called _moosex-dic-wiring.yml_.

These yaml files allow to define mappings between interfaces and implementation
classes much like we've done with the marker Injectable role.

Since it scans for these files inside the source folders, nothing changes about
how you create a container:

```perl
my $container = build_container( scan_path => [ qw(lib local/lib/perl5) ] );
```

You can combine both configuration by config file and by code.

There's a whole section to explain how to define mappings with a config file.

## Using the container

Once a container has been initialized, either by scanning source folders or by
reading from a config file, it can be used to requests services:

```perl
my $auth = $container->get_service('MyApp::AuthService');
```

The requested auth service has all of its dependencies injected too, so it may
well be that by requesting a single service, all other services will be pulled
too, recursively, following the chain of dependencies.

What this means in practice, is that usually, you have a Launcher class that has
to know about the container, and once the dependencies of the launcher class and
the transitive dependencies of the launcher's dependencies have been resolved by
the container, no other part of your application has to know about the container.

And this is a good thing, because a dependency injection container is part of your
infrastructure code, not part of the core business of your application, you don't 
want to mix both because having each part isolated, allows for better testability
of you service units, and of your business logic.

Let's see this with an example:

Given the following business classes,

```perl
package MyApp::AccountService {

	use Moose::Role;

	# (Account) -> (Account)
	requires 'update_account';
	
	# (User) -> (Account)
	requires 'fetch_account';
}

package MyApp::RDB {
	use Moose::Role;

	# (Str,Array[Scalar]) -> (ResultObject)
	requires 'query';
}

package MyApp::RDB::MySQL {
	use Moose;
	with 'MyApp::RDB';

	with MooseX::DIC::Injectable => { implements => 'MyApp::RDB' };

	sub query {
		my ($self,$query,@params) = @_;

		my $db = $self->_connect_to_mysql_instance;
		my $resolved_query = $self->_apply_params_to_query($query);
		my $results = $db->execute_query($resolved_query);
		
		return $self->_convert_results_to_result_object($results);
	}
}

package MyApp::AccountService::RDB {
	use Moose;
	with 'MyApp::AccountService';

	with 'MooseX::DIC::Injectable' => { implements  => 'MyApp::AccountService' };

	has rdb => (is => 'ro', does => 'MyApp::RDB' );

	sub update_account {
		my ($self,$account) = @_;

		my $result = $self->rdb->query('update accounts set name = ? where id = ?',
			$account->name,$account->id);

		return $account;
	}

	sub fetch_account {
		my ($self,$user) = @_;

		my $result = $self->rdb->query('select * from accounts where user_id = ?',$user->id);

		return $self->_result_to_account($result);
	}
}
```

TThe following infrastructure classes for a webapp

```perl
package MyApp::Server {
	use Moose;

	has routes => ( ... );
	has state => ( ... isa => 'Bool', default => 0 );
	has container => ( ... does => 'MooseX::DIC::Container' );

	sub add_route {
		my ($self,$method,$path,$controller_classname,$controller_method) = @_;
		die "can only map routes to controllers" unless
			$controller_classname->does('MyApp::Controller');
		$self->_store_route(...);
	}

	sub start {
		$self->state(1);
		listen_request while($self->state);
	}

	sub stop {
		$self->state(0);
	}

	sub listen_request {
		my ($self) = @_;
		
		my $request = wait_for_request;
		my $route = $self->_map_request_to_route($request);
		my $controller = $self->_fetch_controller_from_route($route);
		$controller->apply_route($route);
	}

	sub _fetch_controller_from_route {
		my ($self,$route) = @_;

		return $self->container->build_class($self->routes->{$route}->controller_name);
	}
}

package MyApp::AccountController {
	use Moose;

	has repository => (is => 'ro', does => 'MyApp::AccountService');

	sub get {
		my ($self,$account_id) = @_;

		my $account = $self->repository->fetch_account $account_id;

		return to_json $account;
	}

	sub update {
		my ($self,$account_json) = @_;

		my $account = from_json $account_json;
		$self->repository->update_account $account;

		return 'OK';
	}
}
```

And the following launcher script

```perl
#!/usr/bin/env perl
use MooseX::DIC 'build_container';
use MyApp::Server;

my $container = build_container( scan_path => [ '../lib' ] );

my $server = MyApp::Server->new( container => $container );
$server->add_route('GET','/accounts/{id}','MyApp::AccountController','get');
$server->add_route('PUT','/accounts/{id}','MyApp::AccountController','update');

$server->start;
```

Let's explain a bit what is happening here.

This a webapp that will launch an Account REST API, which provides two methods: fetch accounts 
and update accounts.
We have model classes: an account service that will make use of an account repository based on
mysql. Then we have a web server that will map some routes to a controller that will dispatch
the request to the account service to perform the desired operation.

The remarkable thing here, is that of all the code needed to make this work, only the outmost
code, the Server and the launcher script, have to directly use the dependency injection container.
Once the server instantiates a Controller, all of it's dependencies are automatically pulled
by the container.

And each class only declares what dependencies it needs to work, and these dependencies are provided
outside the class. This allows to make very easy unit testing of the services and controllers of
this application, since we only have to provide mocks on our unit tests, for a fine grained control
of the preconditions and expected outputs. More on testing with MooseX::DIC in the Testing section.

### Requesting Services vs Building Classes

On the previous example, we've seen that dependencies of classes are declared with the Injected trait.

The attributes of a class are injected by the container as they are found if the trait is declared. 

These attributes must have as a type constraint a __does => 'RoleName'__ configuration. This is a convention
of the MooseX::DIC library. The assumption being that a Service implements an interface. We're not
requesting to the container to gives us the Role itself, but rather, a class that implements that
role.
The reason for why we request implementing classes of an interface, is because this allows us to build
robust applications that are testable from the outset, since an interface can be trivially mocked, while
mocking a class requires more [convoluted frameworks](https://metacpan.org/pod/release/PHILIP/Test-Spec-0.45/lib/Test/Spec/Mocks.pm)
with their own quirks and incompatibilities.

But as we've seen from the previous example too, sometimes forcing an interface when we will only ever
have an implementation may feel forced. For this reason, MooseX::DIC containers provide two ways to
obtain a fully initialized class: requesting an interface-based service, and building a class with
injected dependencies. 

Let's see an example based on the previous code.

#### Requesting an interface-based service

All of our model classes declared attributes as dependencies. For example:

```perl
package MyApp::AccountService::RDB {
	use Moose;
	with 'MyApp::AccountService';

	with 'MooseX::DIC::Injectable' => { implements  => 'MyApp::AccountService' };

	has rdb => (is => 'ro', does => 'MyApp::RDB' );

	sub update_account {
		my ($self,$account) = @_;

		my $result = $self->rdb->query('update accounts set name = ? where id = ?',
			$account->name,$account->id);

		return $account;
	}

	sub fetch_account {
		my ($self,$user) = @_;

		my $result = $self->rdb->query('select * from accounts where user_id = ?',$user->id);

		return $self->_result_to_account($result);
	}
}
```

The AccountService::RDB is an implementation of the AccountService interface. 

We've seen the AccountController requesting it in an attribute:
```perl
package MyApp::AccountController {
	use Moose;

	has repository => (is => 'ro', does => 'MyApp::AccountService');

	sub get {
		my ($self,$account_id) = @_;

		my $account = $self->repository->fetch_account $account_id;

		return to_json $account;
	}

	sub update {
		my ($self,$account_json) = @_;

		my $account = from_json $account_json;
		$self->repository->update_account $account;

		return 'OK';
	}
}
```

The AccountController declares AccountService as its dependency, and it receives it by injection.
The container will provide AccountController with an implementation of AccountService, AccountService::RDB.

For a piece of code to get a service based on an interface, it either must call the `get_service` method of
the container, or declare the service as a dependency in it's attribute.

```perl
#!/usr/bin/env perl

use MooseX::DIC 'build_container';

my $container = build_container( ... );

my $service = $container->get_service('MyApp::AccountService');
```

#### Building a class and injecting it's dependencies.

Instead of having the container retrieve an implementation of a service interface, we may only have an
implementing class without interfaces. Not the ideal situation, but we may not want to go full enterprise
and having an interface for every class.
For this, the container provides the `build_class` method. This method takes as a paremeter the name of a
Moose class, and will instantiate it injecting all of it's dependencies by retrieving them from its registry.

We can see an example with the MyApp::AccountController. It is not the implementation of an interface, but
a service itself. And it declares dependencies. To retrieve a controller with it's dependencies injected, 
we can call the `build_class` method of the container like so:

```perl
#!/usr/bin/env perl

use MooseX::DIC 'build_container';

my $container = build_container( ... );

my $controller = $container->build_class('MyApp::AccountController');
```

In the previous example, we can see that the MyApp::Server class makes use of this functionality of the
container, to build dinamically controllers and injecting them with their dependencies.
```perl
package MyApp::Server {
	use Moose;

	has routes => ( ... );
	has state => ( ... isa => 'Bool', default => 0 );
	has container => ( ... does => 'MooseX::DIC::Container' );

	sub add_route { ... }

	sub start { ... }

	sub stop { ... } 

	sub listen_request { ... }

	sub _fetch_controller_from_route {
		my ($self,$route) = @_;

		return $self->container->build_class($self->routes->{$route}->controller_name);
	}
}
```

The container will inspect the attributes of the specified class and if it can find it's types
in the service registry, it will inject them.
The container cannot inject any attribute type that has not been registered, which means that 
attributes that do not have default values and are required will raise an error while building
the class.

```perl
package MyApp::AccountService::MongoDB;

use Moose;
with 'MyApp::AccountService';

with 'MooseX::DIC::Injectable' => { implements => 'MyApp::AccountService' };

# This will cause error, because the container doesn't know how to retrieve
# the mongodb instance since it's not a managed service in the registry.
has mongodb => ( is => 'ro', isa => 'MongoDB', required => 1 );
```
