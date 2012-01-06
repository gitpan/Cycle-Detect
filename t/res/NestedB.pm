package NestedB;
use strict;
use warnings;

use Cycle::Detect;
use NestedA;
use NestedC;
no Cycle::Detect;

1;
