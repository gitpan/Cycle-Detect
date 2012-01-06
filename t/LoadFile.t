#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use lib 't/res';

use Cycle::Detect;

{

    # Capture warnings
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings => @_ };

    # Make sure we can call require on the modules again in later tests
    local %INC = %INC;

    require 't/res/NoCycleA.pm';

    is( @warnings, 0, "no cycles" );

    can_ok( 'NoCycleA', 'foo' );
    can_ok( 'NoCycleC', 'foo' );
}

done_testing;
