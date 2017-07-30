# Overview

MooseX::DIC is a [dependency injection container](https://en.wikipedia.org/wiki/Dependency_injection)
tailored to [Moose](https://metacpan.org/pod/Moose), living in a full OOP
environment and greatly inspired by Java DIC frameworks like
[Spring](https://docs.spring.io/spring/docs/current/spring-framework-reference/html/beans.html)
or [CDI](http://docs.oracle.com/javaee/6/tutorial/doc/gjbnr.html).

The goal of this library is to provide an easy to use DI container without
configuration files and with automatic wiring of dependencies via constructor
by class type (ideally by Role/Interface) (although a file-based config file
is available too for those that would prefer a clean codebase ).

The configuration is performed by the use of
[Marker roles](https://en.wikipedia.org/wiki/Marker_interface_pattern) and a
specific trait on attributes that have to be injected.

One of the principal tenets of the library is that while code may be polluted
by the use of DIC roles and traits, it should work without a running container.
The classes are fully functional without the dependency injection, the library
is just a convenient way to wire dependencies (this is mainly accomplished by
forbidding non [constructor injection](https://en.wikipedia.org/wiki/Dependency_injection#Constructor_injection)).

This library is designed to be used on long-running processes where startup
time is not a concern (within reason, of course). The container will scan all
configured paths to look for services to inject and classes that need
injection.

There is a great amount of flexibility to account for testing environments,
non-moose libraries, alternative implementations of services, etc, although
none of it is needed for a simple usage.
