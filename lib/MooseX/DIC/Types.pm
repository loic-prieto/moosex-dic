package MooseX::DIC::Types;

use Moose::Util::TypeConstraints;

role_type Injectable => { role => 'MooseX::DIC::Injectable'};

enum ServiceScope => [ qw/request singleton/ ];

1;
