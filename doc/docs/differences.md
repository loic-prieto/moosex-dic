# Differences with other frameworks

There are already many libraries and frameworks that provide DI for Perl.
Among others, we can count:

- Beam::Wire
- Bread::Board
- IoC
- Class::DI

What does this library add to the mix that others don't? 

While the mentioned libraries are excellent in their purpose and use case, 
(and some of them quite mature), I felt that my projects were mostly Moose 
based, and with a heavy emphasis in using Types. I fealt like the already 
existing DI solutions cater to a more general perl usage, where types are
not used, and thus must limit themselves to wire the dependencies by name.

Some CI Containers provide plugins to perform the dependency wiring by type
and even by automatically infering connections.

This library is born from the start with the usage of Moose types in mind. 
It leverages them to perform automatic infering of dependencies and injections. 
It complements dependency injection for large enterprise projects implemented
in Perl striving to reduce the configuration boilerplate as much as possible
by use of sensible defaults, backed by experience with large codebases.

By encouraging the use of Moose Roles to define interfaces, and to provide
implementations for these interfaces, and some tools to ease the wiring between
different environments for them, I feel like MooseX::DIC is a friendlier library
for unit testing services, and that it encourages to follow best practices
on enterprise applications too.

By drawing inspiration from the Java DI libraries, I've designed two parallel
systems to configure the container, each equally capable:

- By code, in which an implementating class for a service declares it's config
in the container, much like annotating classes and methods in java.
- By yaml config file, which is what most ressembles the alternative DI libraries
and which is what avoids tainting the code with infrastructure concerns.

So, *if your project has a sizable codebase, is based on Moose, and makes
heavy use of types, then this library is a very good fit*. I would say more so
than the alternatives. If not, then there is a clearer advantage in using the
other libraries. In that sense, MooseX::DIC suffers from a very narrow focus, 
which is both a blessing and a curse. But, that's the trade-off I made when 
designing the library, and is one that serves me well.


Let´s see how it compares to other DI, as far as I know. I have almost no experience
with them, aside from some quick prototyping with them to test them before
I implemented my own DI library, so I may be wrong. If that's the case, please
contact me (Or better yet, send me a MR in github) with the error and I will be 
more than happy to fix it, or to include other comparisons:

## Beam::Wire

[Beam::Wire](https://metacpan.org/pod/Beam::Wire) is one of the most known DI 
libraries for Perl, and for good reason. It provides a very comprehensive 
solution to wire and define services, with both a config file and a direct API
to configure the container in code.

By virtue of covering a different use case on the wiring and definition of services,
config values, and general data values, there is a greater amount of configuration
boilerplate to fill, if your use case is only to define services. So I would say
it's more verbose in exchange of providing more options and flexibility, which is
not really needed if the use case of your project is defining and wiring Moose
tiped services.

In MooseX::DIC you only define what implementations exist for which roles, and then
the container automatically injects service dependencies by role type into the
services. In Beam::Wire, you must manually define which dependency is going to
which attribute of every service. 
This, of course, ties you to Moose, unlike Beam::Wire.

## Bread::Board

Another of the well known libraries for DI in Perl.

I will quote the authors of the library, for it is this sentence that better defines
the differences between [Bread::Board](https://metacpan.org/pod/Bread::Board) and 
MooseX::DIC:

> Those who have encountered IoC in the Java world may be familiar with the idea that 
> there are 3 'types' of IoC/Dependency Injection; Constructor Injection, Setter 
> Injection, and Interface Injection. 
> In Bread::Board we support both Constructor and Setter injection, it is the authors 
> opinion though that Interface injection was not only too complex, but highly java 
> specific and the concept did not adapt itself well to perl.

It is very true, the concept of interfaces does not adapt to Perl too well. That is, if
you're not using Moose roles. By using Moose Roles as interfaces, you can perform injection
by Interface with MooseX::DIC. In fact, it is both by Interface and by Constructor that
MooseX::DIC works with.

In MooseX::DIC you only define what implementations exist for which roles, and then
the container automatically injects service dependencies by role type into the
services. In Bread::Board, you must manually define which dependency is going to
which attribute of every service by name. 

Unlike Beam::Wire Bread::Board does have a typemapping feature, but it feels like it's more of
an addon than a basic feature of the library, not as idiomatic as if that feature was
planned from the start. Once again, with more flexibility comes a more verbose
configuration spec.

## IoC

[IoC](https://metacpan.org/pod/IOC) is another classic by Stevan Little.

>  Interface injection support is on the to-do list, but I feel that interface injection is better
> suited to more 'type-strict' languages like Java or C# and is really not appropriate to perl.

Once again, we differ on how we want to approach the Dependency Injection. By leveraging Moose 
types, MooseX::DIC only way to perform DI is by Interface injection, on contructors. So, that's
the main difference between IoC and MooseX::DIC.

This library, while providing the basic needs of a DI Container, has less features than both the 
previous frameworks, and MooseX::DIC. But then, it's a lightweight container, so it makes sense.

Configuration is done either by creating the code model, or by writing an XML file. It's less
sugary than the alternatives.

There's an addon to integrate IoC with Moose: [MooseX::IoC](https://metacpan.org/pod/MooseX::IOC).
It's purpose is much like MooseX::DIC, by using traits on attributes of a service to automatically
make use of a previously registered container to inject container services into attributes. 
MooseX::DIC, though, infers automatically how to inject services into a attributes of a Moose class.
