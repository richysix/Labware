# well.t

use Test::More;
use Test::Exception;
use Test::Warn;
use Test::MockObject;

plan tests => 13 + 8 + 4 + 2 + 4 + 2;

use Labware::Well;

# make a mock Plate object
my $mock_96_plate = Test::MockObject->new();
$mock_96_plate->mock('plate_name', sub { return 'Plate_1a' } );
$mock_96_plate->mock('plate_type', sub { return '96' } );
$mock_96_plate->set_isa('Labware::Plate');

# make a mock Plate object
my $mock_384_plate = Test::MockObject->new();
$mock_384_plate->mock('plate_name', sub { return 'Plate_1a' } );
$mock_384_plate->mock('plate_type', sub { return '384' } );
$mock_384_plate->set_isa('Labware::Plate');

# make a well object with 96 well plate
my $well = Labware::Well->new(
    plate => $mock_96_plate,
    position => 'A01',
    contents => 'String contents',
);

# make a well object with 96 well plate
my $well_2 = Labware::Well->new(
    position => 'A01',
    contents => 'String contents',
);

# make a well object with 384 well plate
my $well_3 = Labware::Well->new(
    plate => $mock_384_plate,
    position => 'A01',
    contents => 'String contents',
);

# check method calls (including methods from WellMethods.pm) 13 tests
my @methods = qw( plate_type position contents _row_name_for _row_names
number_of_rows number_of_columns check_well_id_validity _split_well_id _check_row_name_validity
_check_column_name_validity _row_name_to_index _col_name_to_index 
);

foreach my $method ( @methods ) {
    can_ok( $well, $method );
}

# attributes
# position - 8 tests
is( $well->position, 'A01', 'Get well id 1');
throws_ok { $well->position('B01') } qr/read-only accessor/, 'try changing ro position';

# invalid column
throws_ok { Labware::Well->new(
                position => 'A13',
                contents => 'String contents',
            ); } qr/Column id/, 'invalid column id in position';

throws_ok { Labware::Well->new(
                position => 'A00',
                contents => 'String contents',
            ); } qr/Column id/, 'invalid column id in position';

# invalid row
throws_ok { Labware::Well->new(
                position => 'I11',
                contents => 'String contents',
            ); } qr/Row name/, 'invalid row name in position';

# 384 plate, invalid column
throws_ok { Labware::Well->new(
                plate => $mock_384_plate,
                position => 'A30',
            ); } qr/Column id/, 'invalid column id in position in 384 plate';

# 384 plate, invalid row
throws_ok { Labware::Well->new(
                plate => $mock_384_plate,
                position => 'Z12',
            ); } qr/Row name/, 'invalid row name in position in 384 plate';

my $tmp_well = Labware::Well->new( position => 'A1' );
is( $tmp_well->position, 'A01', 'convert A1 to A01');


# plate_type - 4 tests
is( $well->plate_type, '96', 'Get plate_type 1');
throws_ok { $well->plate_type('384') } qr/read-only accessor/, 'try changing ro plate_type';
is( $well_2->plate_type, '96', 'Get default plate_type');
is( $well_3->plate_type, '384', 'Get 384 plate type');

# contents - 2 tests
is( $well->contents, 'String contents', 'Get contents 1');
is( $well->contents('Another String'), 'Another String', 'Set contents 1' );

# other methods - 4 tests
# number_of_columns
is( $well->number_of_columns, 12, 'Get num columns 96');
is( $well_3->number_of_columns, 24, 'Get num columns 384');

is( $well->number_of_rows, 8, 'Get num rows 96');
is( $well_3->number_of_rows, 16, 'Get num rows 384');

# check is_empty - 2 tests
is( $well->is_empty, 0, 'check is_empty on non-empty well');
is( Labware::Well->new( position => 'A01' )->is_empty, 1, 'check is_empty on non-empty well');

