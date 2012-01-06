package Cycle::Detect;
use strict;
use warnings;

use Carp qw/croak/;

our $VERSION = "0.001";

# {{{ put our interceptor in between the world and require.
BEGIN {
    # Get any existing overrides, or go use core.
    my $original_require = 'CORE::GLOBAL'->can('require')
        || sub { CORE::require $_[0] };

    my $active;

    my $require = sub {
        my $caller = caller;

        # Initial level, activate detector
        if ( !$active && $caller->can('CYCLE_DETECT') ) {
            $active = $caller->CYCLE_DETECT;

            my $out;
            my $success = eval {
                $out = $active->do_require(
                    $original_require,
                    @_
                );
                1
            };
            my $error = $@;

            $active = undef;

            return $success ? $out : die $error;
        }

        # Already have an active detector
        return $active->do_require(
            $original_require,
            @_
        ) if $active;

        goto &$original_require;
    };

    no warnings 'redefine';
    *{CORE::GLOBAL::require} = $require;
}
# }}}

# {{{ Public API
sub import {
    my $class = shift;
    my $caller = caller;

    return $class->load( $caller, @_ )
        if @_;

    $class->new($caller);
}

sub unimport {
    my $class = shift;
    my $caller = caller;
    croak "Cycle::Detect is not present on '$caller'"
        unless $caller->can( 'CYCLE_DETECT' );

    $caller->CYCLE_DETECT->disable;
}
# }}}

# {{{ Constructor
sub new {
    my $class = shift;
    my ( $package ) = @_;

    return $package->CYCLE_DETECT
        if $package->can( 'CYCLE_DETECT' );

    my $self = bless {
        package => $package,
        stack   => [],
        tracker => {},
    }, $class;

    {
        no warnings 'redefine';
        no strict 'refs';
        *{"$package\::CYCLE_DETECT"} = sub { $self };
    }

    return $self;
}
# }}}

# {{{ Accessors
sub package { shift->{'package'}}
sub stack   { shift->{'stack'}  }
sub tracker { shift->{'tracker'}}
# }}}

sub do_require {
    my $self = shift;
    my ( $orig_require, $_file ) = @_;

    # Something we can safely stringify
    my $file = $_file;

    push @{ $self->stack } => $file;
    $self->dump_stack($file)
        if $self->tracker->{$file}++;

    my $out;
    # Run in eval to ensure stack integrity
    my $success = eval {
        $out = $orig_require->( $_file );
        1
    };
    my $error = $@;

    $self->tracker->{$file}--;
    pop @{ $self->stack };

    # Rethrow any exceptions
    return $success ? $out : die $error;
    die $error unless $success;
}

sub dump_stack {
    my $self = shift;
    my ( $cause ) = @_;

    my $package = $self->package;

    my $stack_string = join "\n" => map {
        "  " . ( $_ eq $cause ? '* ' : '  ') . "$_"
    }  @{ $self->stack };

    warn "[Cycle Detection started in '$package']\nUse Cycle Detected. Require Stack:\n$stack_string\n"
}

sub load {
    my $class = shift;
    my ( $caller, $package, @args ) = @_;

    my $self = $class->new( $caller );

    my $success = eval <<"    EOT";
        package $caller;
        require $package;
        \$package->import(\@args);
        1;
    EOT
    my $error = $@;

    # Go away.
    $self->disable;

    die $error unless $success;
}

sub disable {
    my $self = shift;
    my $package = $self->package;

    no warnings 'redefine';
    no strict 'refs';
    undef *{"$package\::CYCLE_DETECT"};
}

1;

__END__

=pod

=head1 NAME

Cycle-Detect - (mostly) Non-global use/require cycle detection

=head1 DESCRIPTION

When this module is loaded into a package, Cycle Detection is started. Cycle
detection will issue a highly readable warnings whenever a use cycle is
detected. Detection will only trigger warnings when the cycle starts in a
moduel that has used Cycle::Detect. In addition you can choose to use
Cycle::Detect to load a module, effectively limiting the detection to the scope
of that one load.

Example Warnings:

    [Cycle Detection started in 'My::Package']
    Use Cycle Detected. Require Stack:
      * CycleA.pm
        CycleB.pm
        CycleC.pm
      * CycleA.pm

The warning tells you which package started the cycle-detection. It then
displays the require stack. It adds an asterisk before the module that is
cycling. This readout is handy because it lets you trace exactly how the cycle
occurs.

=head1 SYNOPSYS

=head2 PACKAGE SCOPE

    package My::Package;
    use strict;
    use warnings;

    use Cycle::Detect;
    use Something::That::Cycles qw/my_import/;

    # Detection only tirggers on use/require in a package that imported
    # Cycle::Detect. The code below will not report the cycle.
    {
        package My::Other::Package
        use Another::Cycle;
    }

    ...

    no Cycle::Detect; # Optional, turns off detection for this package

=head2 SINGLE LOAD

    package My::Package;
    use strict;
    use warnings;

    # Check for cycles when loading (and importing) a module:
    use Cycle::Detect 'Something::That::Cycles', qw/my_import/;
    # Cycle detection is not active beyond the previous line.

=head1 CAVEATS

This module works by overriding C<CORE::GLOBAL::require>. It tries to be nice
about it. If it has already been overriden, all efforts will be taken to wrap
around it. However if something else overrides it after this module, and is not
nice about wrapping, the detection will stop working.

=head1 SEE ALSO

L<circular::require> - A discussion about this module is what spawned the idea
for L<Cycle::Detect>. Both modules detect cycles, but take radically different
approaches. circular::require works like a pragma: C<no circular::require> and
simply prints the module that is cycled. It is also completely global.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2012 Chad Granum

Cycle-Detect is free software; Standard perl licence.

Cycle-Detect is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
