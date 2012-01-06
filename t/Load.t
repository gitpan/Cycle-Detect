#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use lib 't/res';
require_ok 'Cycle::Detect';

{
    # Capture warnings
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings => @_ };

    # Load under Cycle::Detect, should get warnings
    {
        local %INC = %INC;

        no warnings 'once';
        Cycle::Detect->import( 'CycleA' );
    }

    # Load again, should not get warnings;
    local %INC = %INC;
    require CycleA;


    is_deeply(
        \@warnings,
        [
            <<"            EOT",
[Cycle Detection started in 'main']
Use Cycle Detected. Require Stack:
  * CycleA.pm
    CycleB.pm
  * CycleA.pm
            EOT
            <<"            EOT",
[Cycle Detection started in 'main']
Use Cycle Detected. Require Stack:
  * CycleA.pm
    CycleB.pm
    CycleC.pm
  * CycleA.pm
            EOT
            <<"            EOT",
[Cycle Detection started in 'main']
Use Cycle Detected. Require Stack:
    CycleA.pm
  * CycleB.pm
    CycleC.pm
  * CycleB.pm
            EOT
        ],
        "Got require stack for all 3 cycles"
    );
}

{
    my @warnings;
    local $SIG{__WARN__} = sub { @warnings = @_ };
    local %INC = %INC;
    require CycleA;
    is_deeply(
        \@warnings,
        [],
        "no cycle detection"
    );
}

ok( ! __PACKAGE__->can( 'blessed' ), "blessed not yet imported");
Cycle::Detect->import( 'Scalar::Util', 'blessed' );
can_ok( __PACKAGE__, 'blessed' );

done_testing;

1;
