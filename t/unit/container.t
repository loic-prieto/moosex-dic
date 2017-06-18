#!/usr/bin/perl
use strict;
use warnings;

use FindBin;

use lib "$FindBin::RealBin/../../local/lib/perl5";
use lib "$FindBin::RealBin/../../lib";
use lib "$FindBin::RealBin/container/lib";

use Test::Spec;
use MooseX::DIC qw/start_container get_service/;

describe 'A Moose DI container' => sub {

	describe ',given a fixed scanpath' => sub {

		before each => sub {
			start_container( 
				libpath => [ "$FindBin::RealBin/container/lib" ]
			);
		};

		it 'should have registered a service' => sub {
			my $service = get_service 'Test1';
			ok(defined($service));
		};

		it 'should return a correct implementation for a service' => sub {
			my $test_service = get_service 'Test1';
			is(ref $test_service,'Test1Impl');
		};

	};

};

runtests unless caller;
