#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use lib 't/res';
require_ok 'Cycle::Detect';

{
    use Cycle::Detect;

    # Capture warnings
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings => @_ };

    # Make sure we can call require on the modules again in later tests
    local %INC = %INC;

    require BaseCycleA;

    is_deeply(
        \@warnings,
        [
            <<"            EOT",
[Cycle Detection started in 'main']
Use Cycle Detected. Require Stack:
  * BaseCycleA.pm
    BaseCycleB.pm
  * BaseCycleA.pm
            EOT
            <<"            EOT",
[Cycle Detection started in 'main']
Use Cycle Detected. Require Stack:
    BaseCycleA.pm
  * BaseCycleB.pm
    BaseCycleC.pm
  * BaseCycleB.pm
            EOT
        ],
        "Got require stack for all 3 cycles while using base.pm"
    );
}

done_testing;

1;
