#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use lib 't/res';
BEGIN {
    require_ok 'Cycle::Detect';
}

{
    use Cycle::Detect;

    # Capture warnings
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings => @_ };

    # Make sure we can call require on the modules again in later tests
    local %INC = %INC;

    require NestedA;

    # If this is more than 3 then the nested cases of use Cycle::Detect are
    # also firing.
    is( @warnings, 3, "Nested cycle detection did not fire" );

    is_deeply(
        \@warnings,
        [
            <<"            EOT",
[Cycle Detection started in 'main']
Use Cycle Detected. Require Stack:
  * NestedA.pm
    NestedB.pm
  * NestedA.pm
            EOT
            <<"            EOT",
[Cycle Detection started in 'main']
Use Cycle Detected. Require Stack:
  * NestedA.pm
    NestedB.pm
    NestedC.pm
  * NestedA.pm
            EOT
            <<"            EOT",
[Cycle Detection started in 'main']
Use Cycle Detected. Require Stack:
    NestedA.pm
  * NestedB.pm
    NestedC.pm
  * NestedB.pm
            EOT
        ],
        "Got require stack for all 3 cycles, all from main despite nesting"
    );

}

done_testing;

1;
