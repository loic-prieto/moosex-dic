requires 'Moose';
requires 'MooseX::Role::Parameterized';
requires 'Log::Log4perl';

on 'test' => sub {
    requires 'Test::Spec';
};
