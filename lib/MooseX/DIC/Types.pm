package MooseX::DIC::Types;

use Moose::Util::TypeConstraints;

role_type Injectable => { role => 'MooseX::DIC::Injectable'};
role_type ServiceFactory => { role => 'MooseX::DIC::ServiceFactory'};

enum ServiceScope => [ qw/request singleton/ ];

1;
