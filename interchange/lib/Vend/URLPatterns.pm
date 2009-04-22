package Vend::URLPatterns;

use strict;
use warnings;

use Vend::URLPattern;
use Moose;

has 'url_patterns' => (
	is  => 'rw',
	isa => 'ArrayRef',
	lazy => 1,
	default => sub { [] },
);

no Moose;

sub register {
    my $self = shift;

	$self->_add_pattern($_) for @_;
	return scalar(@_);
}

sub _add_pattern {
	my ($self, $pattern) = @_;
	push @{$self->url_patterns}, $self->_transform_input($pattern);
}
 
sub _transform_input {
	my ($self, $parameter) = @_;

	$parameter = Vend::URLPattern->new(%$parameter) if ref($parameter) eq 'HASH';
	die 'Invalid input structure for ' . __PACKAGE__
		unless UNIVERSAL::isa($parameter, 'Vend::URLPattern');
	
	return $parameter;
}

sub generate_path {
    my ($self, $parameters) = @_;

    for my $url_pattern (@{ $self->url_patterns() }) {
		my $result = $url_pattern->generate_path($parameters);
		return $result if $result;
	}

    return;
}


sub parse_path {
    my ($self, $path) = @_;

    for my $url_pattern (@{ $self->url_patterns() }) {
		my $result = $url_pattern->parse_path($path);
		return $result if $result;
	}
    return;
}

1;

sub _is_valid_regexp {
    my ($self, $url_pattern_obj) = @_;
    return 1;
}

=pod

=head1 NAME 

Vend::URLPatterns -acts as a registery for URL path patterns for indivudual catalogs and across Interchange entirely

=head1 SYNOPSIS

 use Vend::URLPatterns;
 my $patterns = Vend::URLPatterns->new;

 # register some patterns
 $patterns->register(
     # with a Vend::URLPattern object
     Vend::URLPattern->new(
         pattern => 'userview/(\d+)',
         package => 'MyApp::User',
         method  => 'view_user',
     ),
     # with a Vend::URLPattern-like hashref
     {
         pattern => 'user_edit/(\d+)',
         package => 'MyApp::User',
         method  => 'edit_user',
     },
 );

 # should return 'user_edit/12'' 
 $patterns->generate_path(
     package    => 'MyApp::User',
     method     => 'edit_user',
     parameters => [ 12 ],
 );
 
 # should return a duplicate of the first pattern object, with parameter set of [12]
 $patterns->parse_path('view_user/12');
 
 # should both return undef, as no pattern matches these
 $patterns->parse_path('consume/meats/aardvark');
 $patterns->generate_path(
     package    => 'MyApp::User',
     method     => 'consume',
     parameters => [ 'meat', 'aardvark' ],
 );

=head1 DESCRIPTION 

A collection class used as a registery for all Vend::URLPattern objects.  This class is filled with patterns and can later be used to check URL
patterns against the path patterns in each object.  Should one match that object's package can be used to instantiate said package.thus matching
the URL to an object with the proper parameters.

=head1 METHODS

=over 

=item register( @patterns )

This method is used to register any number of Vend::URLPattern-like structures within the B<Vend::URLPatterns>
collection instance.

Each member of I<@patterns> can be one of:

=over

=item *

An instance of B<Vend::URLPattern>

=item *

A hashref from which a B<Vend::URLPattern> instance can be autovivified.

=back  

The I<register> method may be called any number of times on a given collection object.  The order of
pattern registration is crucial; this determines each pattern's priority when parsing and generating
paths.  Parsing and generation are done in the order of registration, with the first successful
parse or generate call winning.  Consequently, patterns with a wide-range of uses should be registered
later, while more specific patterns should be registered earlier; if a specific pattern represents information
that is potentially a logical subset of a more general pattern, then the specific pattern must be registered
first if it is to ever be used within the collection.

=item generate_path()

A method that will loop through the collection of Vend::URLPattern objects and attempt to find a result
using the encapsulated Vend::URLPattern::generate_path() method.  Undef is returned if no matches are found

The arguments to I<generate_path> are identical to those of the same method in B<Vend::URLPattern>; see
discussion about registration order in the I<register> method above.

=item parse_path( $path )

Logically equivalent to the I<parse_path> method of B<Vend::URLPattern>, with each pattern object within the
collection checked in order of registration; the first object to successfully match the I<$path> "wins" and its
result (from B<Vend::URLPattern-E<gt>parse_path>) returned.

The result is undefined if no match is found in the collection.

=begin comment

=item _is_valid_regexp()

A private method used to validate the regular expression within the object Vend::URLPattern.  

The following rules apply to regular expressions registered in Vend::URLPattern
* No nested groups/matches
* No pattern matching that isn't being used as a parameter

=end comment

=back

=cut
