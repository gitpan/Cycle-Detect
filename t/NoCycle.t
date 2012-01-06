#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use lib 't/res';

use Cycle::Detect;

# Capture warnings
my @warnings;
local $SIG{__WARN__} = sub { push @warnings => @_ };


require NoCycleA;
is( @warnings, 0, "No Cycles" );


my $success = eval { require Bad; 1 };
ok( ! $success, "Error loading bad file" );
my $error = $@;
like( $error, qr/Can't locate Bad\.pm in \@INC/, "got error" );

$success = eval { require Broken; 1 };
ok( ! $success, "Error loading broken file" );
$error = $@;
like( $error, qr/I am broken at/, "got error" );
like( $error, qr/Compilation failed in require/, "got error" );

# Reset so we can try again
delete $INC{'Broken.pm'};
delete $INC{'Bad.pm'};

$success = eval "use base 'Bad'; 1";
ok( ! $success, "Error loading bad file as base" );
$error = $@;
like( $error, qr/Can't locate Bad\.pm in \@INC/, "got error" );

$success = eval "use base 'Broken'; 1 ";
ok( ! $success, "Error loading broken file as base" );
$error = $@;
like( $error, qr/I am broken at/, "got error" );
like( $error, qr/Compilation failed in require/, "got error" );

{
    package Foo::Bar::Baz;
    use strict;
    use warnings;
    use Test::More;

    local %INC = %INC;
    require CycleA;

    is(
        @warnings,
        0,
        "No warnings when cycle does not come from a require in a package that uses Cycle::Detect"
    );
}

require CycleA;
is( @warnings, 3, "Cycle loaded from package that used Cycle::Detect" );

done_testing;

1;
