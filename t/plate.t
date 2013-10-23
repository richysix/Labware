# plate.t

use Test::More;
use Test::Exception;
use Test::Warn;
use Test::MockObject;

plan tests => 26 + 3 + 5 + 5 + 4 + 3 + 7 + 12 + 7 + 5 + 13 + 2 + 4 + 96 * 4 + 4 + 4;

use Labware::Plate;

# make a plate object with no attributes
my $plate = Labware::Plate->new();

# check method calls 26 tests
my @methods = qw( plate_name plate_type wells fill_direction number_of_columns
_row_name_for _row_names number_of_rows number_of_columns check_well_id_validity
_split_well_id _check_row_name_validity _check_column_name_validity _row_name_to_index _col_name_to_index
add_well add_wells fill_well fill_wells_from_starting_well well_id_to_indices
next_well_id _increment_by_row _increment_by_column _indices_to_well_id _indices_to_well_number
_build_empty_wells 
);

foreach my $method ( @methods ) {
    can_ok( $plate, $method );
}

my $plate_2 = Labware::Plate->new(
    plate_name => 'CR-000002b',
    plate_type => '96',
    fill_direction => 'row',
);

# new 384 well plate
my $plate_3 = Labware::Plate->new(
    plate_name => 'CR-000003a',
    plate_type => '384',
    fill_direction => 'column',
);

# check class - 3 tests
isa_ok( $plate, 'Labware::Plate' );
isa_ok( $plate_2, 'Labware::Plate' );
isa_ok( $plate_3, 'Labware::Plate' );

# name attribute - 5 tests
is( $plate->plate_name, undef, 'Get plate_name' );
is( $plate->plate_name('CR-000001a'), 'CR-000001a', 'Set plate_name' );
is( $plate_2->plate_name, 'CR-000002b', 'Get plate_name 2' );
is( $plate_2->plate_name('CR-000002a'), 'CR-000002a', 'Set plate_name 2' );
is( $plate_3->plate_name, 'CR-000003a', 'Get plate_name 3' );

# plate type - 5 tests
is( $plate->plate_type, '96', 'Get default plate_type' );
is( $plate_2->plate_type, '96', 'Get plate_type 2' );
is( $plate_3->plate_type, '384', 'Get plate_type 3' );
throws_ok{ $plate->plate_type('384') } qr/read-only accessor/, 'try changing ro plate_type';
throws_ok{ Labware::Plate->new( plate_type => '192') } qr/Validation failed/, 'test plate_type type-constraint';

# wells - 4 tests
isa_ok( $plate->wells, 'ARRAY', 'Get default wells 1');
isa_ok( $plate_2->wells, 'ARRAY', 'Get wells 2');
isa_ok( $plate_3->wells, 'ARRAY', 'Get default wells 3');
isa_ok( $plate_2->wells->[0], 'ARRAY', 'Get well class 2.1');

# fill_direction - 3 tests
is( $plate->fill_direction, 'column', 'Get default fill_direction' );
is( $plate_2->fill_direction, 'row', 'Get fill_direction 2' );
is( $plate_3->fill_direction, 'column', 'Get fill_direction 3' );

# methods
# should really use mock well object
# add real well
use Labware::Well;
my $well = Labware::Well->new(
    plate_type => '96',
    position => 'A01',
    contents => 'String contents',
);
# add and return a single well - 7 tests
ok( $plate->add_well( $well ), 'Add single well');
is( $plate->return_well('A01')->position, 'A01', 'Add single well - Position of returned well');
is( $plate->return_well('A01')->plate_type, '96', 'Add single well - Plate type of returned well');
is( $plate->return_well('A01')->contents, 'String contents', 'Add single well - contents of returned well');
throws_ok { $plate->return_well(  ) }
    qr/A\swell\sid\smust\sbe\ssupplied/, 'Try to call return_well with no well';
throws_ok{ $plate->add_well('well') } qr/method\srequires\sa\sLabWare::Well\sobject/, 'try to add String';
my $tmp_mock_plate = Test::MockObject->new();
$tmp_mock_plate->set_isa('Labware::Plate');
throws_ok{ $plate->add_well('$tmp_mock_plate') } qr/method\srequires\sa\sLabWare::Well\sobject/, 'try to add non Well object';

# add several wells
my @wells;
for ( my $i = 3; $i < 12; $i+=3 ){
    my $well_id = 'A' . $i;
    my $well = Labware::Well->new(
        plate_type => '96',
        position => $well_id,
        contents => $well_id,
    );
    push @wells, $well;
}
# 12 tests
ok( $plate->add_wells( \@wells ), 'Add multiple wells' );
for ( my $i = 3; $i < 12; $i+=3 ){
    my $id = 'A' . $i;
    my $well_id = $id;
    substr( $well_id, 1, 0, '0');
    is( $plate->return_well($id)->position, $well_id, 'add several wells - Position of returned well');
    is( $plate->return_well($id)->plate_type, '96', 'add several wells - Plate type of returned well');
    is( $plate->return_well($id)->contents, $id, 'add several wells - contents of returned well');
}

throws_ok { $plate->add_wells( @wells ) } qr/This\smethod\srequires\san\sArrayRef\sas\sinput/, 'Fail to supply arrayref to add_wells';

# try to add a well to an already filled well
throws_ok { $plate->add_well( $well ) } qr/Well is not empty!/, 'Attempt to fill an already filled well';

# add column of wells
@wells = ();
foreach ( qw( A B C D E F G H ) ){
    my $well_id = $_ . '05';
    my $well = Labware::Well->new(
        plate_type => '96',
        position => $well_id,
        contents => $well_id,
    );
    push @wells, $well;
}
# 7 tests
ok( $plate->add_wells( \@wells ), 'Add column of wells');
foreach ( qw( A D H ) ){
    my $well_id = $_ . '05';
    is( $plate->return_well($well_id)->position, $well_id, 'add column of wells - Position of returned well');
    is( $plate->return_well($well_id)->contents, $well_id, 'add column of wells - contents of returned well');
}


my @stuff = qw{ stuffb1 stuffc1 stuffd1 stuffe1 };

# fill single well - 5 tests
ok( $plate->fill_well( $stuff[0], 'B01' ), 'fill single well');
is( $plate->return_well('B01')->position, 'B01', 'fill single well - Position of returned well B01');
is( $plate->return_well('B01')->plate_type, '96', 'fill single well - Plate type of returned well B01');
is( $plate->return_well('B01')->contents, 'stuffb1', 'fill single well - contents of returned well B01');
throws_ok { $plate->fill_well( $stuff[0], ) } qr/Method\sfill_well\srequires\sa\swell\sid/, 'Try to fill well without specifying well id';

# fill several wells - 13 tests
my @list_of_contents = @stuff[1..3];
ok( $plate->fill_wells_from_starting_well( \@list_of_contents, 'C01' ), 'fill several wells');
is( $plate->return_well('D01')->position, 'D01', 'fill several wells - Position of returned well D01');
is( $plate->return_well('D01')->plate_type, '96', 'fill several wells - Plate type of returned well D01');
is( $plate->return_well('D01')->contents, 'stuffd1', 'fill several wells - contents of returned well D01');

throws_ok { $plate->fill_wells_from_starting_well( \@list_of_contents,); }
    qr/Method\sfill_wells_from_starting_well\srequires\sa\sstarting\swell\sid/, 'Try to fills wells without a starting well';
throws_ok { $plate->fill_wells_from_starting_well(  ); }
    qr/Method\sfill_wells_from_starting_well\srequires\san\sArrayRef\sof\scontents/, 'Try to fills wells without any contents';
throws_ok { $plate->fill_wells_from_starting_well( @list_of_contents, ); }
    qr/The\ssupplied\slist\sof\scontents\smust\sbe\san\sArrayRef/, 'Try to fills wells with an array not arrayref';
throws_ok { $plate->fill_wells_from_starting_well( {} ); }
    qr/The\ssupplied\slist\sof\scontents\smust\sbe\san\sArrayRef/, 'Try to fills wells with a hashref';
throws_ok { $plate->fill_wells_from_starting_well( \@list_of_contents, 'H12'); }
    qr/Reached\sthe\send\sof\sthe\splate\sand\sstill\shave\scontents\sleft/, 'Try to fills wells with too much stuff';

@list_of_contents = qw{ row-wise-a1 row-wise-a2 row-wise-a3 row-wise-a4 row-wise-a5 row-wise-a6
row-wise-a7 row-wise-a8 row-wise-a9 row-wise-a10 row-wise-a11 row-wise-a12 };
ok( $plate_2->fill_wells_from_starting_well( \@list_of_contents, 'A01' ), 'Fill wells row-wise');
is( $plate_2->return_well('A04')->position, 'A04', 'Fill wells row-wise - Position of returned well A04');
is( $plate_2->return_well('A04')->plate_type, '96', 'Fill wells row-wise - Plate type of returned well A04');
is( $plate_2->return_well('A04')->contents, 'row-wise-a4', 'Fill wells row-wise - contents of returned well A04');

# find next empty well id - 2 tests
is( $plate->first_empty_well_id, 'F01', 'Get first empty well id');
is( $plate_2->first_empty_well_id, 'B01', 'Get first empty well id row-wise');

# fill wells from first empty well - 4 tests
@list_of_contents = qw( stuff-1 stuff-2 stuff-3 );
$plate->fill_wells_from_first_empty_well( \@list_of_contents );
is( $plate->return_well('F01')->contents, 'stuff-1', 'fill single well - contents of returned well F01');
is( $plate->return_well('G01')->contents, 'stuff-2', 'fill single well - contents of returned well G01');
is( $plate->return_well('H01')->contents, 'stuff-3', 'fill single well - contents of returned well H01');
is( $plate->first_empty_well_id, 'A02', 'Get first empty well id');

my $plate_4 = Labware::Plate->new(
    plate_name => 'CR-000004a',
    plate_type => '96',
    fill_direction => 'column',
);
my $plate_5 = Labware::Plate->new(
    plate_name => 'CR-000004a',
    plate_type => '96',
    fill_direction => 'row',
);
my @list;
for ( 1..96 ){
    push @list, $_;
}
$plate_4->fill_wells_from_first_empty_well( \@list );
$plate_5->fill_wells_from_first_empty_well( \@list );
$returned_wells_2 = $plate_4->return_all_wells;
$returned_wells_3 = $plate_5->return_all_wells;
my $wrong = 0;
my @row_names = qw{A B C D E F G H};
my @column_names = qw{ 01 02 03 04 05 06 07 08 09 10 11 12 };
my ( $rowi, $coli );
# 96 * 4 tests
for ( 1..96 ){
    my $well = shift @{$returned_wells_2};
    ( $rowi, $coli ) = $plate_4->_well_number_to_indices( $_ );
    is( $well->position, $row_names[$rowi] . $column_names[$coli], "well $_ position - column-wise" );
    is( $well->contents, $_, "well $_ contents - column-wise" );
    
    my $well_2 = shift @{$returned_wells_3};
    ( $rowi, $coli ) = $plate_5->_well_number_to_indices( $_ );
    is( $well_2->position, $row_names[$rowi] . $column_names[$coli], "well $_ position - row-wise" );
    is( $well_2->contents, $_, "well $_ contents - row-wise" );
}

# fill half a plate - 4 tests
my @list_2;
for ( 1..24 ){
    push @list_2, $_;
}

my $plate_6 = Labware::Plate->new(
    plate_name => 'CR-000004a',
    plate_type => '96',
    fill_direction => 'column',
);
my $plate_7 = Labware::Plate->new(
    plate_name => 'CR-000004a',
    plate_type => '96',
    fill_direction => 'row',
);
$plate_6->fill_wells_from_first_empty_well( \@list_2 );
$plate_6->fill_wells_from_starting_well( \@list_2, 'A07' );

$plate_7->fill_wells_from_first_empty_well( \@list_2 );
$plate_7->fill_wells_from_starting_well( \@list_2, 'E1' );

$returned_wells_4 = $plate_6->return_all_wells;
$returned_wells_5 = $plate_6->return_all_non_empty_wells;
# test size of array
is( scalar @{$returned_wells_4}, 96, 'Return all wells column-wise, check number of returned wells');
is( scalar @{$returned_wells_5}, 48, 'Return all non-empty wells column-wise, check number of returned wells');

#map {print join("\t", $_->position, $_->contents || 'EMPTY' ), "\n"} @{$returned_wells_4};

$returned_wells_6 = $plate_7->return_all_wells;
$returned_wells_7 = $plate_7->return_all_non_empty_wells;
# test size of array
is( scalar @{$returned_wells_6}, 96, 'Return all wells row-wise, check number of returned wells');
is( scalar @{$returned_wells_7}, 48, 'Return all non-empty wells row-wise, check number of returned wells');

# test some internal methods - 4 tests
throws_ok { $plate->_check_well_is_empty( 'A', 1 ) } qr/Indexes\smust\sbe\sintegers/, '_check_well_is_empty with string row index';
throws_ok { $plate->_check_well_is_empty( 2, 'B' ) } qr/Indexes\smust\sbe\sintegers/, '_check_well_is_empty with string column index';

throws_ok { $plate->_increment_indices( 'A', 1 ) } qr/Indexes\smust\sbe\sintegers/, '_increment_indices with string row index';
throws_ok { $plate->_increment_indices( 2, 'B' ) } qr/Indexes\smust\sbe\sintegers/, '_increment_indices with string column index';
