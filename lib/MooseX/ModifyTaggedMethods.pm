package MooseX::ModifyTaggedMethods;

use 5.010;
use strict;
use warnings;
use utf8;

BEGIN {
	$MooseX::ModifyTaggedMethods::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::ModifyTaggedMethods::VERSION   = '0.001';
}

use attributes ();
use Carp qw( confess );
use List::Util qw( first );
use Moose::Exporter;
use MooseX::RoleQR 0.003 ();

'Moose::Exporter'->setup_import_methods(
	with_meta => [qw/ methods_tagged /],
);

sub methods_tagged
{
	my $meta   = shift;
	my $caller = $meta->name;
	my $test   = [ @_ ];
	
	if ($meta->isa('Moose::Meta::Class'))
	{
		my @matches;
		foreach my $method ($meta->get_all_methods)
		{
			my $sub = ($method->original_method || $method)->body;
			next unless defined(first { $_ ~~ $test } attributes::get($sub));
			push @matches, $method->name;
		}
		return \@matches;
	}
	elsif ($meta->isa('Moose::Meta::Role')
	and    $meta->can('deferred_modifier_class'))
	{
		return sub {
			my ($name, undef, undef, undef, $klass) = @_;
			my $method = $klass->find_method_by_name($name);
			my $sub    = ($method->original_method || $method)->body;
			return defined(first { $_ ~~ $test } attributes::get($sub));
		};
	}
	else
	{
		confess "methods_tagged() can only be used within "
			. "Moose classes and MooseX::RoleQR roles";
	}
}

1;
__END__

=head1 NAME

MooseX::ModifyTaggedMethods - use sub attributes to specify which methods want modifiers

=head1 SYNOPSIS

   {
      package Local::Role::Transactions;
      
      use MooseX::RoleQR;
      use MooseX::ModifyTaggedMethods;
      
      before methods_tagged('Database') => sub {
         my $self = shift;
         $self->dbh->do('BEGIN TRANSACTION');
      };
      
      after methods_tagged('Database') => sub {
         my $self = shift;
         $self->dbh->do('COMMIT');
      };
   }
   
   {
      package Local::BankAccount;
      
      use Sub::Talisman qw( Database );
      use Moose;
      with qw( Local::Role::Transactions );
      
      has dbh => (is => 'ro', isa => 'Object');
      
      sub transfer_funds : Database {
         my ($self, $amount, $destination) = @_;
         
         # lots of database activity
         ...;
      }
      
      sub withdraw : Database { ... }
      sub deposit  : Database { ... }
   }

=head1 DESCRIPTION

Normally Moose classes can specify method modifiers by name, an arrayref
of names, or via a regular expression. Moose roles are more limited, not
allowing regular expressions.

MooseX::RoleQR extends the functionality for roles, allowing them to use
regular expressions to specify method modifiers. MooseX::ModifyTaggedMethods
goes even further, allowing classes and roles to use attributes (in the
L<perlsub> sense of the word) to indicate which methods should be wrapped.

=over

=item C<< methods_tagged(@tags) >>

This module exports a single function C<methods_tagged> which can be used
in conjunction with C<before>, C<after> and C<around> to select methods
for modifying. What exactly it returns is best you don't know, but it
suffices to say that Moose and MooseX::RoleQR (but not plain Moose::Role)
know what to do with it.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-ModifyTaggedMethods>.

=head1 SEE ALSO

L<Moose>,
L<MooseX::RoleQR>.

L<Sub::Talisman>,
L<Sub::Talisman::Struct>,
L<perlsub>,
L<attributes>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

