package MooseX::DIC::ServiceCreationException;

use Moose;
with 'Throwable';

has message => ( is => 'ro', isa => 'Str', required => 1);
1;
