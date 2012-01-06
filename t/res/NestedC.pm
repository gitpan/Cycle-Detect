package NestedC;
use strict;
use warnings;

use Cycle::Detect;
use NestedA;
use NestedB;
no Cycle::Detect;

1;
