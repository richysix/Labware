package Labware::Plate;
use warnings;
use strict;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;
use Labware::Well;
use Carp qw( cluck confess );
use English qw( -no_match_vars );

enum 'Labware::Plate::plate_type', [qw( 96 384 )];

enum 'Labware::Plate::direction', [qw( row column )];

# ABSTRACT: Object representing a microtitre Plate

=method new

  Usage       : my $plate = Labware::Plate->new(
                    plate_name => 'Plate-01',
                    plate_type => '96',
                    fill_direction => 'column',
                );
  Purpose     : Constructor for creating Plate objects
  Returns     : Labware::Plate object
  Parameters  : plate_name => String
                plate_type => enum('96', '384') # default = 96
                wells => ArrayRef of ArrayRefs of Wells
                fill_direction => enum('row', 'column') # default = column
  Throws      : If parameters are not the correct type
  Comments    : None

=cut

=method plate_name

  Usage       : $plate->plate_name;
  Purpose     : Getter for plate_name attribute
  Returns     : String
  Parameters  : None
  Throws      : If input is given
  Comments    : 

=cut


has 'plate_name' => (
    is => 'rw',
    isa => 'Str',
);

=method plate_type

  Usage       : $plate->plate_type;
  Purpose     : Getter for plate_type attribute
  Returns     : String ('96' or '384')
  Parameters  : None
  Throws      : If input is given
  Comments    : 

=cut

has 'plate_type' => (
    is => 'ro',
    isa => 'Labware::Plate::plate_type',
    default => '96',
    writer => '_set_plate_type',
);

=method wells

  Usage       : $plate->wells;
  Purpose     : Getter for wells attribute
  Returns     : ArrayRef of ArrayRefs of Labware::Well objects
  Parameters  : None
  Throws      : If input is given
  Comments    : 

=cut

has 'wells' => (
    is => 'ro',
    isa => 'ArrayRef[ArrayRef[Labware::Well]]',
    lazy => '1',
    builder => '_build_empty_wells',
);

=method fill_direction

  Usage       : $plate->fill_direction;
  Purpose     : Getter for fill_direction atribute
  Returns     : String ('row' or 'column')
  Parameters  : None
  Throws      : If input is given
  Comments    :

=cut

has 'fill_direction' => (
    is => 'ro',
    isa => 'Labware::Plate::direction',
    default => 'column',
);

with 'Labware::WellMethods';

=method add_well

  Usage       : $plate->add_well( $well );
  Purpose     : method to add a well to a plate
  Returns     : 1 if successful
  Parameters  : Labware::Well object
  Throws      : If well is already filled
  Comments    : 

=cut

sub add_well {
    my ( $self, $well ) = @_;
    if( ref $well && !$well->isa('Labware::Well') ){
        confess "This method requires a LabWare::Well object, not a ", ref $well, " one.\n";
    }
    my ( $rowi, $coli ) = $self->well_id_to_indices( $well->position );
    if( !$self->_check_well_is_empty( $rowi, $coli ) ){
        confess "Well is not empty!\n";
    }
    $self->wells->[$coli][$rowi] = $well;
    return 1;
}

=method add_wells

  Usage       : $plate->add_wells( \@wells );
  Purpose     : method to add a list of wells to a plate
  Returns     : 1 if successful
  Parameters  : ArrayRef of Labware::Well objects
  Throws      : If input is not an ArrayRef 
  Comments    : 

=cut

sub add_wells {
    my ( $self, $list_of_wells, ) = @_;
    if( ref $list_of_wells ne 'ARRAY' ){
        confess "This method requires an ArrayRef as input, not ", ref $list_of_wells, ".\n";
    }
    foreach my $well ( @{$list_of_wells} ){
        $self->add_well( $well );
    }
    return 1;
}

#sub _add_well_using_indices {
#    my ( $self, $well, $rowi, $columni ) = @_;
#    $self->wells->[$columni][$rowi] = $well;
#}

=method fill_well

  Usage       : $plate->fill_well( $contents, 'A01' );
  Purpose     : create a new Labware::Well object, fill it with the supplied contents and 
                add it to the plate
  Returns     : 1 if successful
  Parameters  : ( Any, String )
  Throws      : If well id is not supplied or is not a valid well id
  Comments    :

=cut

sub fill_well {
    my ( $self, $contents, $well_id, ) = @_;
    if( !$well_id ){
        confess "Method fill_well requires a well id.\n";
    }
    $self->check_well_id_validity($well_id);
    # make well object and add to plate
    my $well = Labware::Well->new(
        plate_type => $self->plate_type,
        position => $well_id,
        contents => $contents,
    );
    return $self->add_well( $well );
}

=method fill_wells_from_starting_well

  Usage       : $plate->fill_wells_from_starting_well( $contents, 'A01' );
  Purpose     : fill wells with the supplied list of contents
  Returns     : 1 if successful
  Parameters  : ( Any, String )
  Throws      : If list of contents is not supplied or is not an
                ArrayRef of objects
                If well id is not supplied or is not a valid well id
  Comments    :

=cut

sub fill_wells_from_starting_well {
    my ( $self, $list_of_contents, $well_id, ) = @_;
    
    if( !$list_of_contents ){
        confess "Method fill_wells_from_starting_well requires an ArrayRef of contents.\n";
    }
    else{
        if( !ref $list_of_contents || ref $list_of_contents ne 'ARRAY' ){
            confess "The supplied list of contents must be an ArrayRef, not ", ref $list_of_contents, ".\n";
        }
    }
    if( $well_id ){
        $self->check_well_id_validity($well_id)
    }
    else{
        confess "Method fill_wells_from_starting_well requires a starting well id.\n";
    }
    # make a new copy of the list so that the original list will still exist.
    my @new_list = @{$list_of_contents};
    while( @new_list ){
        my $contents = shift @new_list;
        $self->fill_well( $contents, $well_id );
        eval {
            $well_id = $self->next_well_id( $well_id );
        };
        if( $EVAL_ERROR && $EVAL_ERROR eq 'END OF PLATE' && @new_list ){
            confess $EVAL_ERROR;
        }
    }
    return 1;
}

=method fill_wells_from_first_empty_well

  Usage       : $plate->fill_wells_from_first_empty_well( \@contents );
  Purpose     : find the first empty well on the plate and then fill the wells
                in order with the supplied list of contents
  Returns     : 1 if successful
  Parameters  : ( Any, String )
  Throws      : If list of contents is not supplied or is not an
                ArrayRef of objects
  Comments    :

=cut

sub fill_wells_from_first_empty_well {
    my ( $self, $list_of_contents, ) = @_;
    my $well_id = $self->first_empty_well_id;
    $self->fill_wells_from_starting_well( $list_of_contents, $well_id );
}

=method return_well

  Usage       : $plate->return_well( 'A1' );
  Purpose     : Getter for a well given a well id
  Returns     : Labware::Well
  Parameters  : String (well id)
  Throws      : If well id is not a valid well id
  Comments    :

=cut

sub return_well {
    my ( $self, $well_id, ) = @_;
    if( !$well_id ){
        confess "A well id must be supplied!\n";
    }
    else{
        $self->check_well_id_validity($well_id)
    }
    my ( $rowi, $coli ) = $self->well_id_to_indices( $well_id );
    return $self->wells->[$coli]->[$rowi];
}

=method return_all_wells

  Usage       : $plate->return_all_wells;
  Purpose     : Getter for all wells
  Returns     : ArrayRef of Labware::Well objects
  Parameters  : None
  Throws      : 
  Comments    :

=cut

sub return_all_wells {
    my ( $self, ) = @_;
    my ( $rowi, $coli ) = ( 0, 0 );
    my $wells = $self->wells;
    my @wells;
    my $done = 0;
    while( !$done ){
        if( !$self->_check_well_is_empty( $rowi, $coli ) ){
            push @wells, $wells->[$coli]->[$rowi];
        }
        eval{
            ( $rowi, $coli ) = $self->_increment_indices( $rowi, $coli ) if !$done;
        };
        if( $EVAL_ERROR && $EVAL_ERROR =~ m/END\sOF\sPLATE/xms ){
            $done = 1;
        }
        elsif( $EVAL_ERROR ){
            confess $EVAL_ERROR;
        }
    }
    return \@wells;
}

=method print_all_wells

  Usage       : $plate->return_all_wells;
  Purpose     : Getter for all wells
  Returns     : ArrayRef of Labware::Well objects
  Parameters  : None
  Throws      : 
  Comments    :

=cut

sub print_all_wells {
    my ( $self, $sep, $fh ) = @_;
    
    if( !$sep ){
        $sep = "\t";
    }
    if( !$fh || ref $fh ne 'GLOB' ){
        $fh = \*STDOUT;
    }
    for ( my $well_number = 1; $well_number <= $self->plate_type; $well_number++ ){
        my ( $rowi, $coli ) = $self->_well_number_to_indices( $well_number );
        my $well = $self->wells->[$coli][$rowi];
        if( ref $well->contents ){
            # can't print anything other than a scalar at the momnent
            confess "Well contents is not a String. Don't know how to print it!\n";
        }
        print $fh join($sep, $self->plate_name, $well->position, $well->contents, ), "\n";
    }
}

=method well_id_to_indices

  Usage       : $plate->well_id_to_indices( 'A2' );
  Purpose     : Convert well id to two indices
  Returns     : ( Integer, Integer )
  Parameters  : String (well id)
  Throws      : 
  Comments    :

=cut

sub well_id_to_indices {
    my ( $self, $well_id, ) = @_;
    my ( $row_name, $column_name ) = $self->_split_well_id( $well_id, );
    my $row_index = $self->_row_name_to_index($row_name);
    my $column_index = $self->_col_name_to_index($column_name);
    return ( $row_index, $column_index );
}

=method next_well_id

  Usage       : $plate->next_well_id( 'A2' );
  Purpose     : Return the next well for a given well id
  Returns     : String (next well id)
  Parameters  : String (well id)
  Throws      : 
  Comments    :

=cut

sub next_well_id {
    my ( $self, $well_id, ) = @_;
    my ( $row_index, $column_index ) = $self->well_id_to_indices( $well_id );
    ( $row_index, $column_index ) = $self->_increment_indices( $row_index, $column_index );
    return $self->_indices_to_well_id( $row_index, $column_index );
}

=method first_empty_well_id

  Usage       : $plate->first_empty_well_id;
  Purpose     : Find the first empty well and return the id
  Returns     : String (empty well id)
  Parameters  : None
  Throws      : 
  Comments    :

=cut

sub first_empty_well_id {
    my ( $self, ) = @_;
    my $wells = $self->wells;
    my ( $rowi, $coli ) = ( 0, 0 );
    my $well_id;
    while( !$well_id ){
        if( $self->_check_well_is_empty( $rowi, $coli ) ){
            $well_id = $self->_indices_to_well_id( $rowi, $coli );
        }
        ( $rowi, $coli ) = $self->_increment_indices( $rowi, $coli ) if !$well_id;
    }
    return $well_id;
}

#_check_well_is_empty
#
#Usage       : $plate->_check_well_is_empty( '1', '2' );
#Purpose     : check whether a well is empty using the given row index and column index
#Returns     : 1 if well is empty, 0 if not
#Parameters  : ( Integer, Integer )
#Throws      : If Parameters are not Integers
#Comments    :

sub _check_well_is_empty {
    my ( $self, $rowi, $coli ) = @_;
    if( $rowi !~ /\A\d{1,2}\z/xms || $coli !~ /\A\d{1,2}\z/xms ){
        confess "Indexes must be integers!\n";
    }
    my $wells = $self->wells;
    my $empty = 0;
    if( !defined $wells->[$coli]->[$rowi] ){
        $empty = 1;
    }
    elsif( !$wells->[$coli]->[$rowi]->contents ){
        $empty = 1;
    }
    return $empty;
}

#_increment_indices
#
#Usage       : $plate->_increment_indices( '1', '2' );
#Purpose     : increment the supplied row and column indices in the correct direction given the plate's fill direction
#Returns     : ( Integer, Integer )
#Parameters  : ( Integer, Integer )
#Throws      : If Parameters are not Integers
#Comments    :

sub _increment_indices {
    my ( $self, $rowi, $coli ) = @_;
    if( $rowi !~ /\A\d{1,2}\z/xms || $coli !~ /\A\d{1,2}\z/xms ){
        confess "Indexes must be integers!\n";
    }
    if( $self->fill_direction eq 'row' ){
        ( $rowi, $coli ) = $self->_increment_by_row( $rowi, $coli );
    }
    else{
        ( $rowi, $coli ) = $self->_increment_by_column( $rowi, $coli );
    }
    return ( $rowi, $coli );
}

#_increment_by_row
#
#Usage       : $plate->_increment_by_row( '1', '2' );
#Purpose     : increment the supplied row and column indices by row
#Returns     : ( Integer, Integer )
#Parameters  : ( Integer, Integer )
#Throws      : 
#Comments    :

sub _increment_by_row {
    my ( $self, $rowi, $coli ) = @_;
    $coli++;
    if( $coli > $self->number_of_columns - 1 ){
        $coli = 0;
        $rowi++;
    }
    if( $rowi > $self->number_of_rows - 1 ){
        confess "END OF PLATE\n";
    }
    return ( $rowi, $coli );
}

#_increment_by_column
#
#Usage       : $plate->_increment_by_column( '1', '2' );
#Purpose     : increment the supplied row and column indices by column
#Returns     : ( Integer, Integer )
#Parameters  : ( Integer, Integer )
#Throws      : 
#Comments    :

sub _increment_by_column {
    my ( $self, $rowi, $coli ) = @_;
    $rowi++;
    if( $rowi > $self->number_of_rows - 1 ){
        $rowi = 0;
        $coli++;
    }
    if( $coli > $self->number_of_columns - 1 ){
        confess "END OF PLATE\n";
    }
    return ( $rowi, $coli );
}

#_indices_to_well_id
#
#Usage       : $plate->_indices_to_well_id( '1', '2' );
#Purpose     : returns a well_id for the supplied row and column indices
#Returns     : String
#Parameters  : ( Integer, Integer )
#Throws      : 
#Comments    :

sub _indices_to_well_id {
    my ( $self, $row_index, $column_index, ) = @_;
    my $row_name = $self->_row_name_for( $row_index );
    my $column_name = $column_index + 1;
    $column_name =~ s/\A/0/xms if( length $column_name == 1 );
    return $row_name . $column_name;
}

#_indices_to_well_number
#
#Usage       : $plate->_indices_to_well_number( '1', '2' );
#Purpose     : returns a number for the supplied row and column indices
#              well numbers start at 1 (A01)
#Returns     : Integer
#Parameters  : ( Integer, Integer )
#Throws      : 
#Comments    :

sub _indices_to_well_number {
    my ( $self, $row_index, $column_index, ) = @_;
    if( $self->fill_direction eq 'row' ){
        return $row_index * $self->number_of_columns + $column_index + 1;
    }
    else{
        return $column_index * $self->number_of_rows + $row_index + 1;
    }
}

#_well_number_to_indices
#
#Usage       : $plate->_well_number_to_indices( 40 );
#Purpose     : Converts a number to row and column indices
#Returns     : ( Integer, Integer )
#Parameters  : Integer
#Throws      : 
#Comments    :

sub _well_number_to_indices {
    my ( $self, $well_number, ) = @_;
    my ( $rowi, $coli );
    if( $self->fill_direction eq 'row' ){
        $rowi = int( ($well_number - 1) / $self->number_of_columns );
        $coli = ( $well_number - 1 ) % $self->number_of_columns;
    }
    else{
        $coli = int( ($well_number - 1) / $self->number_of_rows );
        $rowi = ( $well_number - 1 ) % $self->number_of_rows;
    }
    return ( $rowi, $coli );
}

#_build_empty_wells
#
#Usage       : $plate->_build_empty_wells;
#Purpose     : Creates an Array of Arrays and returns a Ref to it
#Returns     : ArrayRef of ArrayRefs
#Parameters  : None
#Throws      : 
#Comments    :

sub _build_empty_wells {
    my ( $self, ) = @_;
    my $wells = [];
    for( 0..$self->number_of_columns - 1 ){
        $wells->[$_] = [];
    }
    return $wells;
}



__PACKAGE__->meta->make_immutable;
1;
