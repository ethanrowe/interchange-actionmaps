package Vend::Action::Factory;

use strict;
use warnings;
use Vend::URLPatterns::Registry;
use Vend::Action::Standard;

sub create_action {
    my ($self, %parameter) = @_;

	my $catalog = $parameter{catalog};
	$catalog = '' unless defined($catalog) and length($catalog);

    my $package = $self->action_class_for( $catalog, $parameter{name} );

 	my $action_class = Moose::Meta::Class->create(
		$package => (
			superclasses => ['Vend::Action::Standard'],
  			attributes => [
  				Moose::Meta::Attribute->new(
  					routine => (
  						default => sub { $parameter{routine} },
  					),
				)
  			],
		)
	);

	my $pattern = $parameter{pattern};
	$pattern = $self->default_pattern_for($parameter{name})
		unless defined($pattern);

	my $opt = {
		pattern => $pattern,
		package => $package,
		method  => 'action',
	};

	$opt->{parameter_names} = $parameter{parameters}
		if defined($parameter{parameters}) and @{$parameter{parameters}};

    Vend::URLPatterns::Registry->register_patterns($catalog, $opt);

	return $package;
}

sub default_pattern_for {
	my ($self, $action) = @_;
	return $action . '((?:/|$|.+))';
}

sub action_class_for {
    my ($self, $catalog, $name) = @_;

	return "Vend::Runtime::Catalogs::${catalog}::Actions::$name"
		if defined($catalog) and length($catalog);

	return "Vend::Runtime::Global::Actions::$name";
}

1;

=pod

=head1 NAME 

Vend::Action::Factory

=head1 SYSOPSIS

# Parameters for the actual module that Factory will create the object for
my %module_parameters = ( user_id  => '12',
                          view_all => '1' );

my $module_name = "UserView";
my $catalog = "IC";

my %parameters = ( module_name       => $module_name,
                   catalog        => $catalog,
                   module_parameters => \%module_parameters);

my $user_view = Vend::Action::Factory->create_action(\%parameters);
my $user_id = $user_view->user_id();

=head1 DESCRIPTION 

This module is a factory class used to create objects during runtime that live in the Vend::Runtime namespace.  This module 
generally takes a catalog for catalog specific classes in Vend::Runtime::Catalogs:: otherwise it assumes  you want a 
global and attempts to create_action a global runtime object from Vend::Runtime::Global::Actions

=head1 PARAMETERS 

NONE 

=head1 METHODS

=head2 create_action(%parameters)

This method takes a hashref of parameters: module_name, catalog, and module_parameters. An attempt is then made to create
an object of the given module_name and catalog

=head3 %parameters

=over 

=item B<module_name> - The name of the module for the object you want created

=item B<catalog> - The catalog id for the catalog that owns the module.  If not supplied global action is assumed

=item B<module_parameters> - A hash ref to a list of parameters to be passed to the module for the object created.  These will vary depending
on the module you are having Factory create

=back

=head2 action_class_for($module, $catalog)

A method used to return the proper package name given a module name and a catalog.  If catalog is not given
it assumes global and returns a global package name.

=over

=item B<module> - name of the module used to create a package name

=item B<catalog> - The name of the catalog used to look in an appropiate namespace 

=back
