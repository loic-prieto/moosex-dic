requires 'Moose';
requires 'MooseX::Role::Parameterized';
requires 'Log::Log4perl';
requires 'Throwable';
requires 'aliased';
requires 'Try::Tiny';

on 'test' => sub {
    requires 'Test::Spec';
};
