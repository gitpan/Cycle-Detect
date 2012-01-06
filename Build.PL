#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Cycle::Detect',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    requires => {
        'Carp' => 0,
    },
    build_requires => {
        'Test::Simple' => '0.88',
    },
    meta_merge => {
        resources => {
            repository  => 'http://github.com/exodist/Cycle-Detect',
            bugtracker  => 'http://github.com/exodist/Cycle-Detect/issues',
        },
    }
);

$build->create_build_script;
