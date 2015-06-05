## no critic (RequireUseStrict, RequireUseWarnings, RequireTidyCode)
package Labware::Well;
## use critic

# ABSTRACT: Object representing a Well of a microtitre Plate

## Author         : rw4
## Maintainer     : rw4
## Created        : 2013-08-15
## Last commit by : $Author$
## Last modified  : $Date$
## Revision       : $Revision$
## Repository URL : $HeadURL$

use warnings;
use strict;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;
use Carp qw(cluck confess);
use Scalar::Util qw( weaken );

enum 'Labware::Well::plate_type', [qw( 96 384 )];

=method new

  Usage       : my $well = Labware::Well->new(
                    position => 'A01',
                    contents => $object,
                    plate => $plate,
                    plate_type => '96',
                );
  Purpose     : Constructor for creating Well objects
  Returns     : Labware::Well object
  Parameters  : position => Str
                contents => Any
                plate => Labware::Plate object
                plate_type => enum('96', '384') # not required if plate is defined
  Throws      : If parameters are not the correct type
  Comments    : None

=cut

=method plate

  Usage       : $well->plate
  Purpose     : Getter for plate attribute
  Returns     : Labware::Plate
  Parameters  : None
  Throws      : If input is given
  Comments    : This method delegates methods plate_name and plate_id to the Plate object

=cut

has 'plate' => (
    is => 'ro',
    isa => 'Labware::Plate',
    handles => {
        plate_name => 'plate_name',
    },
);

=method plate_type

  Usage       : $well->plate_type
  Purpose     : Getter for plate_type attribute of the Plate object
  Returns     : '96' or '384'
  Parameters  : None
  Throws      : If input is given
  Comments    : If plate attribute is defined, uses plate_type defined in that object
                Defaults to '96'

=cut

has 'plate_type' => (
    is => 'ro',
    isa => 'Labware::Well::plate_type',
    default => '96',
    writer => '_set_plate_type',
);

=method position

  Usage       : $well->position
  Purpose     : Getter for position attribute of the Plate object
  Returns     : String
  Parameters  : None
  Throws      : If input is given
  Comments    : None

=cut

has 'position' => (
    is => 'ro',
    isa => 'Str',
);

=method contents

  Usage       : $well->contents
  Purpose     : Getter/Setter for contents attribute of the Plate object
  Returns     : Anything
  Parameters  : contents of well
  Throws      : None
  Comments    : None

=cut

has 'contents' => (
    is => 'rw',
    isa => 'Any',
);

with 'Labware::WellMethods';

around BUILDARGS => sub{
    my $method = shift;
    my $self = shift;
    my %args;
    if( !ref $_[0] ){
        for( my $i = 0; $i < scalar @_; $i += 2){
            my $k = $_[$i];
            my $v = $_[$i+1];
            if( $k eq 'plate' ){
                weaken($v);
            }
            $args{ $k } = $v;
        }
        return $self->$method( \%args );
    }
    elsif( ref $_[0] eq 'HASH' ){
        if( exists $_[0]->{'plate'} ){
            weaken( $_[0]->{'plate'} );
        }
        return $self->$method( $_[0] );
    }
    else{
        confess "method new called without Hash or Hashref.\n";
    }
};

=method BUILD

  Usage       : 
  Purpose     : BUILD method, automatically called after object creation to test
                validity of well position
  Returns     : 
  Parameters  : 
  Throws      : If position supplied to constructor is not a valid well for the
                type of plate
  Comments    : 

=cut

sub BUILD {
    my ( $self, ) = @_;
    $self->position;
}

around 'position' => sub {
    my ( $method, $self, $input ) = @_;
    if( $input ){
        return $self->$method( $input );
    }
    else{
        my $position = $self->$method;
        substr( $position, 1, 0, '0' ) if length $position == 2;
        $self->check_well_id_validity( $position );
        return $position;
    }
};

around 'plate_type' => sub {
    my ( $method, $self, $input ) = @_;
    
    if( $input ){
        die "Can't change a read-only accessor!\n";
    }
    else{
        if( $self->plate ){
            return $self->plate->plate_type;
        }
        else{
            return $self->$method;
        }
    }
};

=method is_empty

  Usage       : $plate->is_empty;
  Purpose     : Tests whether well is empty or not
  Returns     : 1 if well is empty, 0 otherwise
  Parameters  : None
  Throws      : If input is given
  Comments    :

=cut

sub is_empty {
    my ( $self, ) = @_;
    if( !defined $self->contents ){
        return 1;
    }
    else{
        return 0;
    }
}

__PACKAGE__->meta->make_immutable;
1;
