package Types;

use Moose::Util::Constraints;

role_type Injectable => { role => 'MooseX::DIC::Injectable'};

enum ServiceScope => [ qw/request singleton/ ];

1;