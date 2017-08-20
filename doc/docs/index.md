# MooseX::DIC The dependency injection container for Moose.

## Introduction

Welcome to the documentation site for the MooseX::DIC library, which is focused
on providing a dependency injection container based on Moose types. More
specifically based on Moose roles (used as interfaces in the java sense).

The library is greatly inspired by dependency injection frameworks found on
Java land like CDI or Spring. As such, it tries to mimic most of it's features.

The configuration of the container can be made both by config file or by
writing metadata into the classes that declare injectable services. This
library does not make any assumption over which method is better.

Keep reading about the container to get a basic look into how the container
works, what benefits it provides to your application, and how to use it.

## Quick example

```perl
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
        is     => 'ro',
        does   => 'LDAP'
    );

}

package MyApp::LoginController {
    use Moose;

    has auth_service => ( is=>'ro', does => 'MyApp::AuthService' );

    sub do_login {
        my ($self,$request) = @_;
        
        if($self->auth_service->login($request->username,$request->password)) {
            print 'this is fine';
        }
    }
}
```
```perl
#!/usr/bin/env perl
use strict;
use warning;

use MooseX::DIC 'build_container';
use MyApp::Launcher;

# This may take some time depending on your lib size
my $container = build_container( scan_path => [ 'lib' ] );

# The launcher is a fully injected service, with all dependencies
# provided by the container.
my $app = $container->get_service 'MyApp::Launcher';
$app->start;

exit 0;
```
