## no critic (RequireUseStrict, RequireUseWarnings, RequireTidyCode)
package Labware::WellMethods;

## use critic

# ABSTRACT: Role of methods shared between Wells and Plates

## Author         : rw4
## Maintainer     : rw4
## Created        : 2013-08-15
## Last commit by : $Author$
## Last modified  : $Date$
## Revision       : $Revision$
## Repository URL : $HeadURL$

use warnings;
use strict;
use Moose::Role;
use namespace::autoclean;
use List::MoreUtils qw( any );
use Carp qw(cluck confess);

requires 'plate_type';

=method number_of_rows

  Usage       : $well->number_of_rows
  Purpose     : Getter for the number of rows of Plate
  Returns     : '8' or '16'
  Parameters  : None
  Throws      : None
  Comments    :

=cut

sub number_of_rows {
    my ( $self, ) = @_;
    my $num_rows =      $self->plate_type eq '96'       ?   8
        :                                                   16
        ;
    return $num_rows;
}

=method number_of_columns

  Usage       : $well->number_of_columns
  Purpose     : Getter for the number of columns of Plate
  Returns     : '12' or '24'
  Parameters  : None
  Throws      : None
  Comments    :

=cut

sub number_of_columns {
    my ( $self, ) = @_;
    my $num_columns =   $self->plate_type eq '96'       ?   12
        :                                                   24
        ;
    return $num_columns;
}

=method check_well_id_validity

  Usage       : $well->check_well_id_validity('A01')
  Purpose     : Checks the validity of a supplied well id
  Returns     : 1 if well is valid
  Parameters  : String (well id)
  Throws      : If EITHER first character is not a valid well row name
                    for the plate type
                OR if characters 2 and 3 don't form a valid column number
                    for the plate type
  Comments    :

=cut

sub check_well_id_validity {
    my ( $self, $well_id ) = @_;
    my ( $row_name, $column_name ) = $self->_split_well_id( $well_id, );
    $self->_check_row_name_validity( $row_name );
    $self->_check_column_name_validity( $column_name );
    return 1;
}

# Usage       : $self->_split_well_id('A01');
# Purpose     : Splits well id into row name and column name
# Returns     : Array of Strings ( row_name, column_name )
# Parameters  : String (well id)
# Throws      :

sub _split_well_id {
    my ( $self, $well_id ) = @_;
    my $row_name = substr( $well_id, 0, 1 );
    my $column_name = substr( $well_id, 1 );
    return ( $row_name, $column_name );
}

# Usage       : $self->_check_row_name_validity( $row_name );
# Purpose     : Checks validity of supplied row name
# Returns     : 1 if row name is valid
# Parameters  : String ( row name )
# Throws      : If row name is not valid

sub _check_row_name_validity {
    my ( $self, $row_name ) = @_;
    my @row_names = $self->_row_names;
    if( !any { $_ eq $row_name } @row_names ){
        confess "Row name, $row_name, is not a valid row name - Row name must be one of @row_names.\n";
    }
    else{ return 1; }
}

# Usage       : $self->_check_column_name_validity( $column_name );
# Purpose     : Checks validity of supplied column name
# Returns     : 1 if column number is valid
# Parameters  : String ( column id )
# Throws      : If column number is not valid

sub _check_column_name_validity {
    my ( $self, $column_name ) = @_;
    $column_name =~ s/\A/0/xms if( length $column_name == 1 );
    my $column_index = $self->_col_name_to_index($column_name);
    if( $column_index < 0 || $column_index > $self->number_of_columns - 1 ){
        confess "Column id, $column_name, is not a valid column id - ",
            "Column number must be between 1 and ", $self->number_of_columns, " inclusive.\n"
    }
    else{ return 1; }
}

# Usage       : $self->_row_name_for( $row_index );
# Purpose     : Gets row name for a given row index
# Returns     : String ( row name )
# Parameters  : String ( row index )
# Throws      :
# Notes       : returns undef if row index is out of bounds

sub _row_name_for {
    my ( $self, $index ) = @_;
    my %row_name_for = (
        '96' => [ qw{ A B C D E F G H } ],
        '384' => [ qw{ A B C D E F G H I J K L M N O P } ],
    );
    return $row_name_for{ $self->plate_type }->[ $index ];
}

# Usage       : $self->_row_names;
# Purpose     : Gets an array of row_names for type of plate
# Returns     : Array of Strings
# Parameters  : None
# Throws      :

sub _row_names {
    my ( $self, ) = @_;
    my %row_name_for = (
        '96' => [ qw{ A B C D E F G H } ],
        '384' => [ qw{ A B C D E F G H I J K L M N O P } ],
    );
    return @{$row_name_for{ $self->plate_type }};
}

# Usage       : $self->_row_name_to_index;
# Purpose     : Gets a row index for a given row name
# Returns     : String ( row name )
# Parameters  : String ( row index )
# Throws      :

sub _row_name_to_index {
    my ( $self, $row_name, ) = @_;
    my %row_index_for = (
        A => '0',
        B => '1',
        C => '2',
        D => '3',
        E => '4',
        F => '5',
        G => '6',
        H => '7',
        I => '8',
        J => '9',
        K => '10',
        L => '11',
        M => '12',
        N => '13',
        O => '14',
        P => '15',
    );
    return $row_index_for{ $row_name };
}

# Usage       : $self->_col_name_to_index;
# Purpose     : Gets a column index for a given column name
# Returns     : Integer ( column index )
# Parameters  : String ( column name )
# Throws      :

sub _col_name_to_index {
    my ( $self, $col_name, ) = @_;
    $col_name =~ s/\A0//xms;
    $col_name--;
    return $col_name;
}

1;

#########
# METHODS
#row_name_for
#row_names
#number_of_rows
#number_of_columns
#_check_well_id_validity
#_split_well_id
#_check_row_name_validity
#_check_column_name_validity
#_row_name_to_index
#_col_name_to_index
