package NestedA;
use strict;
use warnings;

use Cycle::Detect;
use NestedB;
no Cycle::Detect;

1;
