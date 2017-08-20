# Injection by type

Most of the existing dependency injectors for perl perform dependency injection
by name. You register services to names. And then you fetch that service by
name.

You can see an example with the rightly popular [Beam::Wire library](https://metacpan.org/pod/Beam::Wire).
```perl
# wire.yml
captain:
    class: Person
    args:
        name: Malcolm Reynolds
        rank: Captain
first_officer:
    $class: Person
    name: Zoë Alleyne Washburne
    rank: Commander
 
# script.pl
use Beam::Wire;
my $wire = Beam::Wire->new( file => 'wire.yml' );
my $captain = $wire->get( 'captain' );
print $captain->name; # "Malcolm Reynolds"
```

The MooseX::DIC library, instead, makes use of the type coercion capabilities
of the Moose library to allow for automatic injection of dependencies by type
instead of by name.
So, for example:

```perl
package MyApp::AuthService {
    use Moose::Role;

    requires 'login';
}

package MyApp::LDAPAuthService {

    use Moose;
    with 'MyApp::AuthService';

    with 'MooseX::DIC::Injectable' => {
        implements  => 'MyApp::AuthService',
        qualifiers  => [ 'LDAP' ],
        environment => 'test',
        scope       => 'singleton'
    };

    has ldap => (
        is       => 'ro',
        does     => 'LDAP',
		required => 1
    );

    sub login {
        # does something
    }

}

package MyApp::LoginController {
    use Moose;

    has auth_service => ( is=>'ro', does => 'MyApp::AuthService');

    sub do_login {
        my ($self,$request) = @_;
        
        if($self->auth_service->login($request->username,$request->password)) {
            print 'this is fine';
        }
    }
}
```

What we see here, is that there's a service, whose interface we know, MyApp::AuthService.
The login controller needs an auth service, but it doesn't care which one it is
provided as long as there's one provided.
We also have an implementator of the interface AuthService, LDAPAuthService
which implements the login method agains an LDAP server.
Then, the LoginController asks for an auth service, and the container knows 
where to look when asked for a MyApp::AuthService service.
The link between the interface declaration and the implementation is written
in the implementation class, MyApp::LDAPAuthService by use of the MooseX::DIC::Injectable
parameterizable role.

When the container starts, it scans injectable services like MyApp::LDAPAuthService
and adds it to it's registry where it can be then requested by classes whose 
attributes declare to accept a role/interface.

# Testing with inversion of control

This way of declaring the dependencies of your service, in it's constructor,
allows to test much more easily your classes, providing mocks and stubs when
testing and allowing the container to wire automatically the dependencies based
on whether you're performing tests or running in production.
