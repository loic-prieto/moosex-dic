requires 'Moose';
requires 'MooseX::Role::Parameterized';
requires 'Log::Log4perl';
requires 'Throwable';
requires 'aliased';

on 'test' => sub {
    requires 'Test::Spec';
};
