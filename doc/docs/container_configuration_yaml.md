# Container configuration by config file

Another way to configure the dependency injection container without having to
taint your code with boilerplate marker interfaces is to specify the configuration
inside yaml files.

Before diving into how it is done, just a tiny sample:

```yaml
include:
    - included_config_file.yml
mappings:
  LoginService:
    LoginServiceLDAP:
      scope: request
	  dependencies:
	     ua:
		   scope: request
	LoginServiceDB:{}
  DBService:
    DBServiceMysql:{}
    DBServiceSQLite:
      environment: dev
  HTTPClient:
    HTTPClientLWP:
	  scope: request
```

Following this approach we can see the change on how services are specified:
we map service interfaces to implementation classes, only specifying configuration
when it deviates from the defaults. So let's review these defaults.

## Default configuration values

There are two sets of defaults when writing configuration:

- service declaration defaults
- dependencies injection defaults

### Service declaration defaults

As much as when configuring the container by code, when we declare a service
implementation, we can avoid boilerplate for the common cases.
For a given service implementation declaration, the following values are the
default:

```yaml
mappings:
  Service:
    Implementation:
	   scope: singleton
	   environment: default
	   builder: Moose
       dependencies:
	     *:
		   scope: object
```

So, by default a service is:

- Stateless, only one instance of the service is needed to provide for the
whole application.
- Built by the Moose service factory, the default one.
- Belongs to the default environment
- All of it's dependencies are object-injected (instead of request-injected).

If any of those attribute must change, only the difference must be written, all
other attributes are assumed to have default values. So, for example:

```yaml
mappings:
  LoginService:
    LoginServiceLDAP:
      scope: request
```

The LDAP implementation of the LoginService inherits all default configurations
and overrides the scope of the service, by injecting it as a request-scoped
service whenever it is required, which means it will be created each time for
each service that needs it.

### Dependencies injection defaults

By default, injected attributes of a service have the following default values:

```yaml
mappings:
  Service:
    Implementation:
      dependencies:
        *:
          scope: object
          qualifiers: []
```

The default injection scope for an attribute is object (in contrast to request),
which means that the injected objected is only injected once, when requested
the first time while building the requesting object.

## Configuration parameters

The following code sample shows all possible configuration parameters:

```yaml
include:
    - included_config_file.yml
mappings:
  LoginService:
    LoginServiceLDAP:
      scope: request
	  dependencies:
	     ua:
		   scope: request
	LoginServiceDB:{}
  DBService:
    DBServiceMysql:{}
    DBServiceSQLite:
      environment: dev
  HTTPClient:
    HTTPClientLWP:
	  scope: request
```

### include

A wiring configuration file may include an arbitrary number of different files,
that will be parsed after the content of the current one has been included in the
container.
This means that included files may override service definitions done by the
including file. So, for example, given the following definitions:

moosex-wirings.yml
```yaml
include:
    - wiring-dev.yml
mappings:
  LoginService:
    LoginServiceLDAP:
      scope: request
	  dependencies:
	     ua:
		   scope: request
```

wiring-dev.yml
```yaml
mappings:
  LoginService:
    LoginServiceDB:
      scope: singleton
      environment: development
```

When including the dev wiring file, the LoginService is augmented to have an
implementation on the development environment.

We can also rewrite the LoginServiceLDAP on the other included file:

wiring-override.yml
```yaml
mappings:
  LoginService:
    LoginServiceLDAP:
      scope: singleton
```

The LoginServiceLDAP implementator is redefined on the overriding file, and the
values written on it will completely replace the previous definition.

The name of the file to include can be anything that your file system supports.
It is relative to where the including file resides.

### scope

The service scope defines how the implementation class is instantiated when
injected into a requesting service.

- singleton (default): Only a single instance of the service ever exists. This
is not designed to hold state, but rather to profit from the nature of a
stateless service. Since there's no state, there's no danger in having only one
instance of the service. Almost all of your services should be stateless.
Any requesting service receives this single instance.

- request: The service is instantiated every time it is needed. This is necessary
for stateful services, since otherwise each request service would affect it.

### environment

The environment to which a service implementation belongs to. By default it is
'default'. Can be any arbitrary name.

A container is launched with a given environment, which will be the environment
it will use to search defined services for that environment. So, a service
defined in the development environment will only be fetchable by other services
if the container serving them is launched on that environment.

Auxiliary methods can retrieve services for a given environment.

### builder

A service is built inside the container either by two kind of factories:

- Moose (default): By using this factory, the container will analyze a moose
class and automatically inject dependent services to build an instance.

- Factory: When your moose class instead provides a way to build the declared
service, then it can do so by consuming the MooseX::DIC::ServiceFactory role,
which is an interface that declares the build_service method. This method will
be invoked by the Factory builder to build instances of your declared service.

### dependencies

A key-value hash of dependencies where the key is the name of the attribute,
and the value is a config-hash of injection points config params as seen in the 
Dependencies injection defaults section.

