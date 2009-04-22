package Vend::URLPatterns::Registry;

use Vend::URLPatterns;

use strict;
use warnings;

my %registry = ();

sub patterns_for {
    my ($self, $catalog_id) = @_;
    return $registry{$catalog_id};
}

sub register_patterns {
    my $self = shift;
	my $catalog_id = shift;

    my $url_patterns = $self->patterns_for($catalog_id) || $self->_initialize_patterns_for($catalog_id);
	return $url_patterns->register(@_);
}

sub _initialize_patterns_for {
	my ($self, $catalog_id) = @_;

    my $url_patterns_obj = Vend::URLPatterns->new();
    if($catalog_id) {
	    $registry{$catalog_id} = $url_patterns_obj;
	}
	else {
        $registry{''} = $url_patterns_obj;
	}
	return $url_patterns_obj;
}

1;

=pod

=head1 NAME 

Vend::URLPattern::Registry - a class used for registering Vend::URLPattern instances.

=head1 SYSOPSIS

use Vend::URLPatterns::Registry;

my $url_obj = Vend::URLPattern->new( { pattern => '^userview/(\d+{2})/$',
                                       object  => 'IC::UserVIew' });

=head1 DESCRIPTION 

=over 

A class used to register Vend::URLPatterns objects globally or to specific catalogs. This class interfaces diretly with Vend::URLPatterns. 

=back 

=head1 METHODS

=over 

=item patterns_for(CATALOG_ID)

A method used to retrive Vend::URLPatterns instances from the private hash when given a catalog ID.  Undef is returned if no instances are found.

=item _initialize_patterns_for(CATALOG_ID)

A private method that instantiates an empty Vend::URLPatterns object for a specific catalog ID and places it in the private hash. If no CATALOG_ID is passed a global key=>value pair is created.

=item register_patterns(CATALOG_ID, PATTERNS_ARRAY)

A method responsible for adding the given PATTERNS_ARRAY Vend::URLPatterns instances within the private hash. It first checks to see if there is a 
Vend::URLPatterns instance for the given CATALOG_ID.  If nothing is found it will then create one in the hash. 

=back

=cut
