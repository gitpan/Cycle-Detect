#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use lib 't/res';
require_ok 'Cycle::Detect';

use Cycle::Detect;

{

    # Capture warnings
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings => @_ };

    # Make sure we can call require on the modules again in later tests
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
    eval "no Cycle::Detect; 1" || die $@;

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

done_testing;

1;
