# Dependency Injection and Dependency Inversion

## Definition

What exactly is Dependency Injection and how can it help your projects?

For a full explanation of Dependency Injection and Dependency Inversion, there
are many sources I would recommend for later consumption:

- [Wikipedia source for Dependency Injection](https://en.wikipedia.org/wiki/Dependency_injection)
- [Wikipedia source for Dependency Inversion](https://en.wikipedia.org/wiki/Dependency_inversion_principle)
- [Martin Fowler's article on DI](https://martinfowler.com/articles/injection.html)

The main gist of this, though, is that Dependency Injection is a framework 
for applications that eases the implementation of the Dependency Inversion
principle in your codebase.

So, a better question would be: How can Dependency Inversion help my project?

In traditional applications, a service, a controller, or a script calls the
service it needs directly by instantiating a class, or locating the service
somehow and fetching it. Like this:

```perl
package AuthController;

use Moose;
use AuthService;

sub login {
    my ($self,$http_request) = @_;

    my $auth_service = AuthService->new;
    my $is_logged_in = $auth_service->login(
        $http_request->param("user"),
        $http_request->param("password"));

    ...
}
```

While this code works fine for most situations, there's a glaring problem: 
testability.
Due to the fact that the AuthController directly builds the AuthService, there's
no way to test in isolation the AuthController. The only way to set an preset
set of inputs that should map to expected outputs, is to manipulate how the
AuthService works, by mocking it with sofisticated libraries, or by manipulating
the datasource of the service (by launching a database with your tests) or even
by changing the service, so that it works with different modes (production mode,
testing mode, integration mode, etc).

What is happening here is known as the anti-pattern [Service Locator](https://en.wikipedia.org/wiki/Service_locator_pattern)
, in which the code that requests the service knows how to build it. It doesn't
ultimately matter how the service locator is implemented: a factory, a simple 
new, a service locator singleton. What matters is that the service is retrieved
inside the code that uses it, instead of being provided to the service as part
of it's initialization, like what we will see now.

## Provided dependencies

Instead of letting the AuthController instance the services it needs, let's 
provide it with an object that will be of type AuthService.

```perl
package AuthController;

use Moose;

has auth_service => (is => 'ro', isa => 'AuthService', required => 1 );

sub login {
    my ($self,$request) = @_;

    my $is_logged_in = $self->auth_service->login(
        $http_request->param("user"),
        $http_request->param("password"));

    ...

    return $is_logged_in? 200 : 401;
}
```

This is already better, since the AuthController itself doesn't know about the
auth service he's receiving. It only knows about it's interface, what methods
are available and how to use it.

What this allows us then is the following testing code:

```perl
#!/usr/bin/env perl

package FailingAuthServiceMock {
    use Moose;
    extends 'AuthService';

    sub login { return 0; }
}

use AuthController;
use Test::More;

my $controller = AuthController->new(
    auth_service => FailingAuthServiceMock->new
);

my $return_code = $controller->login(...);

is($return_code,401,"When a failing auth service is used, should return 
                     forbidden access");
```

Quite obviously, the code example is nonsensical, and more useful things 
should be tested, but one can already see that providing mock objects this way 
is far easier than having to provide a database, or using complex mocking 
libraries, or having to change the original object code to accomodate testing.

In fact, if there's only one thing that you learn of this library, this should
be it. If you're using service locators inside your codebase, this single 
change will enhance it tenfold. Easy testing is what makes an application
robust and resilient to change, what gives the confidence to change, refactor,
improve, with the knowledge that no single change breaks the application.

## Dependencies as interfaces

What the AuthController knows is the interface of the dependency it declares.
It knows that the AuthService has a login method which accepts a user and a
password and returns a boolean to tell if the credentials are valid. That's the
contract of the AuthService, that AuthController expects.

So...why no make that contract official?

```perl
package AuthService {
    use Moose::Role;

    # (Str,Str) -> Bool
    requires 'login';
}

package AuthService::DB {
    use Moose;
    with 'AuthService';

    use Database;

    sub login {
        my ($self,$user,$password) = @_;
        my $db = Database->new('database_credentials');

        my $result = $db->query('select count(id) from users where name = ? and 
                                 password = ?',$user,$password);
        
        return $result;
    }
}

package AuthController {
    use Moose;

    has auth_service => (is => 'ro', does => 'AuthService', required => 1 );

    sub login { ... }
}
```

So, now, AuthController, only knows it will receive an object that implements
the interface of AuthService. It doesn't care which object. AuthController is
now decoupled from whathever the way of validating users is. Perhaps we have
an AuthService that looks into a database, or another that looks into LDAP, or
another that just checks a fixed username and password in memory. 
This also means, our tests are even easier, since we only have to mock
interfaces, not classes. 

```perl
#!/usr/bin/env perl

package FailingAuthServiceMock {
    use Moose;
    with 'AuthService';

    sub login { return 0; }
}

use AuthController;
use Test::More;

my $controller = AuthController->new(
    auth_service => FailingAuthServiceMock->new
);

my $return_code = $controller->login(...);

is($return_code,401,"When a failing auth service is used, should return 
                     forbidden access");
```

The difference between this test code and the former appears as negligible, but
in fact it isn't. It is often the case that by subclassing a service to mock it,
we inherit some behaviour or initialization that is not convenient while
testing. And we're also breaking the unit test isolation, since we also have
to take care of the dependency code.

As the [Interface Segregation Principle](http://www.oodesign.com/interface-segregation-principle.html)
teaches us, we should program to an interface, not to an implementation.

The second best thing this documentation can teach you is this: declare your
dependencies as interfaces, so that they can be better mocked, and so that your
code is completely decoupled from the implementation. This ensures that it is
resilient to change.

## Transitive dependencies

An observant eye may have seen in the previous code example something
suspicious:

```perl
package AuthService {
    use Moose::Role;

    # (Str,Str) -> Bool
    requires 'login';
}

package AuthService::DB {
    use Moose;
    with 'AuthService';

    use Database;

    sub login {
        my ($self,$user,$password) = @_;
        my $db = Database->new('database_credentials');

        my $result = $db->query('select count(id) from users where name = ? and 
                                 password = ?',$user,$password);
        
        return $result;
    }
}
```

Right, I'm saying that services inside a class should be declared as 
dependencies of that class, and in the AuthService::DB class I'm once again 
building a service. That should, obviously be changed to:
```perl
package AuthService {
    use Moose::Role;

    # (Str,Str) -> Bool
    requires 'login';
}

package AuthService::DB {
    use Moose;
    with 'AuthService';

    has db => (is => 'ro', does => 'Database', required => 1);

    sub login {
        my ($self,$user,$password) = @_;

        my $result = $self->db->query('select count(id) from users where name = ? and 
                                       password = ?',$user,$password);
        
        return $result;
    }
}
```

And we will also have the declared dependencies transformed to Interface + 
Implementation:

```perl
package Database {
    use Moose::Role;

    has credentials => ( is => 'ro', isa => 'HashRef[Str]', required => 1 );

    # (Str,Array[Any]) -> Any
    requires 'query';
}

package Database::MySQL {
    use Moose;
    with 'Database';

    sub query {
        my ($self,$query_text,@query_args) = @_;

        my $db = $self->_connect_to_mysql_with_credentials;
        my $results = $db->query($query_text,@query_args);

        return $self->_normalize_results($results);
    }
}
```

So, now we have the following dependency chain:
AuthController -> AuthService (AuthService::DB) -> Database (Database::MySQL)

These are not resolved magically: somewhere in our code, they must be 
instantiated. For example, in our app code:
```perl
#!/usr/bin/env perl

use AuthController;
use AuthService::DB;
use Database::MySQL;
use HttpRequest;

my $controller = AuthController->new(
    auth_service => AuthService::DB->new(
        db => Database::MySQL->new
    )
);

my $result = $controller->login(HttpRequest->with_params(
    user => 'username',
    password => 'password' 
);

print "The auth controller returned the status code $result \n";
```

Quite the verbose initialization. For the test code we can take some shortcuts:

```perl
#!/usr/bin/env perl

package FakeAuthService {
    use Moose;
    with 'AuthService';

    sub login { 0 }
}

use Test::More;
use AuthController;

my $controller => AuthController->new(auth_service => FakeAuthService->new);

my $result = $controller->login(...);

is($result,401,"should return invalid credentials");
```

For the test code, since we're only interested in testing the AuthController
package, we can skip initializing the transitive dependencies, we only need to
mock the first one: FakeAuthService. It only returns false, so no need to build
a class with database dependencies. This is one benefit of programming to 
interfaces instead of to implementations.

We can also take shortcuts in the app code, by declaring the default value for
a dependency, like so:

```perl
package AuthService {
    use Moose::Role;

    # (Str,Str) -> Bool
    requires 'login';
}

package AuthService::DB {
    use Moose;
    with 'AuthService';
    use 'Database::MySQL';

    has db => (
        is => 'ro', 
        does => 'Database', 
        default => sub { 
            Database::MySQL->new
        }
    );

    sub login { ... }
}

package AuthController {
    use Moose;
    use AuthService::DB;

    has auth_service => (
        is => 'ro',
        does => 'AuthService',
        default => sub {
            AuthService::DB->new
        }
    );
}
```

And then

```perl
#!/usr/bin/env perl

use AuthController;

my $controller => AuthController->new;
my $result = $controller->login(...);
```

The code is greatly reduced, but you may have observed that it has broken the
Interface Segregation Principle even though it does appear to be using
interfaces.
By declaring default implementation classes, the developer is encouraged to use
these default classes, to save some typing. When the implementation changes or 
another one appears, (s)he will have to change the code everywhere the interface
was used.
Also, the service using the dependencies once again has to know of the 
implementation, so it's actually a step back.

The creation of the dependent services rest entirely upon the caller of a 
service, and this can create some burden, and unrelated responsibilities, which
is why we use _Dependencies Injectors_.

## Dependency Injection

This library, MooseX::DIC, is a Dependency Injection framework. It takes care
of injecting into classes their dependencies automatically, so that the code
remains decoupled, robust and testable while avoiding the burden of having to
build the dependencies each time we need a service, thus freeing your code from
infrastructure concerns.

It does so by using a [Dependency Injection Container](http://www.yiiframework.com/doc-2.0/guide-concept-di-container.html)
, which is a registry of services and builders for these services. The code can
then request an instance of a service to the container, and the container will
provide the service with all of it's dependencies automatically initialized.
And the dependencies of the dependencies too, transitively.

More specifically, the MooseX::DIC (which stands for MooseX Dependency Injection
Container), makes use of Moose type coercions to map Interfaces (Roles) to 
Services (Packages), so for example, with the following code:

```perl
package AuthService {
    use Moose::Role;

    # (Str,Str) -> Bool
    requires 'login';
}

package AuthService::DB {
    use Moose;
    with 'AuthService';

    with 'MooseX::DIC::Injectable' => { implements => 'AuthService' };

    has db => (is => 'ro', does => 'Database', required => 1, traits => [ 'Injected' ]);

    sub login {
        my ($self,$user,$password) = @_;

        my $result = $self->db->query('select count(id) from users where name = ? and 
                                       password = ?',$user,$password);
        
        return $result;
    }
}

package AuthController {
    use Moose;

    has auth_service => (is => 'ro', does => 'AuthService', required => 1, traits => ['Injected'] );

    sub login { ... }
}
```

We can have the following script that uses the container to fetch the Controller
with all of it's dependencies initialized:

```perl
#!/usr/bin/env perl

use MooseX::DIC 'build_container';

my $container = build_container( scan_path => qw/lib/ );
my $controller = $container->get_service('AuthController');

my $result = $controller->login(...);

print "The result of the login was: $result \n";
```

And the magic here is that all the transitive dependencies of the AuthController
have been resolved automatically.

Do not pay yet too much attention to the configuration boilerplate, and take
into account that there's more than one way to write the configuration (into the
code, or in an external yaml configuration file). Just notice we've told the
container that AuthService::DB is an implementation of the AuthService.
That's the way the container knows how to map an Interface to an Implementation
when retrieving the requested services.

Although a container seems like a Service Locator, which by now should be clear
to be a bad idea to use, and indeed it is, the usage of the container is what
sets it apart from a service locator: Once a service is retrieved, all it's
dependencies are injected into it transitively. The code below the service is
unaware of the container. Only the outermost code of your application has to
know about the container, such as the launcher that initializes your server, or
your application.

Your code is independent from the container, as easy to test as it was without
it.

## Conclusion

Dependency Injection is a way to manage complexity in the dependency graph while
keeping the code simple and robust. It handles the instantiation of services
for you.

MooseX::DIC leverages the capabilities of Moose to allow to program to
interfaces in an easy manner. Since MooseX::DIC maps implementations to
interfaces, it allows your code to be highly decoupled and thus easily testable.

MooseX::DIC provides sofisticated tools to customize how the injection is
performed, such as service scopes, injection scopes, environments, qualifiers,
service factories, and more advanced use cases.

Enjoy!
