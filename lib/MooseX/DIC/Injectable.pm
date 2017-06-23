package Injectable;

use MooseX::DIC::Types;
use aliased 'MooseX::DIC::Container::ServiceMetaInformation';

use MooseX::Role::Parameterized;


parameter scope => ( isa => 'ServiceScope', default => 'singleton');
parameter environment => ( isa => 'Str', default => 'default');
parameter implements => ( isa => 'Str', predicate => 'has_implements' );
parameter qualifiers => ( isa => 'ArrayRef[Str]', default => sub { [] });

role {
    my $p = shift;

    method _moosex_dic_meta => sub {
        return ServiceMetaInformation->new(
            scope => $p->scope,
            environment => $p->environment,
            qualifiers => $p->qualifiers,
            implements => $p->implements
        );
    };
};

1;