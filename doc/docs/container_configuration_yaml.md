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
