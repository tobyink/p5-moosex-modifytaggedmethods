use strict;
use warnings;
use Test::More tests => 5;
use Test::NoWarnings;

{
	package Local::Fu;
	use Moose;
	use Sub::Talisman qw( MyTag );
	sub foo :MyTag { 1 }
}

{
	package Local::Fu2;
	use Moose;
	extends qw( Local::Fu );
	use MooseX::ModifyTaggedMethods;
	around methods_tagged('MyTag') => sub { 2 };
};

{
	package Local::Fu3;
	use MooseX::RoleQR;
	use MooseX::ModifyTaggedMethods;
	around methods_tagged('MyTag') => sub { 3 };
}

{
	package Local::Fu4;
	use Moose;
	extends qw( Local::Fu2 );
	with qw( Local::Fu3 );
}

{
	package Local::Fu5;
	use Moose::Role;
	with qw( Local::Fu3 );
}

{
	package Local::Fu6;
	use Moose::Role;
	with qw( Local::Fu5 );
}

my $x;
{
	package Local::Fu7;
	use Moose;
	with qw( Local::Fu3 );
	use MooseX::ModifyTaggedMethods;
	use Sub::Talisman qw( MyTag OtherTag );
	sub foo :MyTag :OtherTag { 4 }
	before methods_tagged('OtherTag') => sub { ++$x };
}


is(
	Local::Fu2->foo,
	2,
);

is(
	Local::Fu4->foo,
	3,
);

is(
	Local::Fu7->foo,
	3,
);

ok $x;