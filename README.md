# Labware

Modules to represent Labware (Plates and Wells)

## Modules

Contains the following modules:

*   Plate.pm - object representing a micro-titre plate (96 or 384)
*   Well.pm - object representing a single well on a plate
*   WellMethods.pm - Module for shared methods

## Installation

Download latest [Labware](https://github.com/richysix/Labware/releases) release and
install using make.

e.g.  

    cd ~/src
    wget https://github.com/richysix/Labware/releases/download/v0.0.5/Labware-0.0.5.tar.gz
    tar -xvzf Labware-0.0.5.tar.gz
    cd Labware-0.0.5
    perl Makefile.PL
    make
    make test
    make install

## Copyright

This software is Copyright (c) 2014,2015 by Genome Research Ltd.

This is free software, licensed under:

The GNU General Public License, Version 3, June 2007
