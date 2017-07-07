package Test2Impl;

use Moose;
with 'Test2';

with 'MooseX::DIC::Injectable' => { implements => 'Test2' };

has dependency1 => ( is=>'ro', does => 'Test1', 

sub do_something {}

1;
