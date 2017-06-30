requires 'Moose';
requires 'MooseX::Role::Parameterized';
requires 'Log::Log4perl';
requires 'Throwable';
requires 'aliased';
requires 'Try::Tiny';
requires 'File::Find';
requires 'File::Slurp';

on 'test' => sub {
    requires 'Test::Spec';
};
