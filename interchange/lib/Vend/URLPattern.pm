package Vend::URLPattern;

use strict;
use warnings;

use Regexp::Parser;
use Moose;

has pattern => (
	is  => 'rw', 
	isa => 'Str',
	trigger => sub {
		my $self = shift;
		$self->clear_parser;
		$self->clear_regex;
	},
);

has parser => (
	reader  	=> 'parser',
	clearer		=> 'clear_parser',
	init_arg	=> '_parser',
	default		=> sub { shift->_build_parser },
	lazy		=> 1,
);

has pattern_regex => (
	reader		=> 'regex',
	clearer		=> 'clear_regex',
	init_arg	=> '_regex',
	default		=> sub { shift->_build_regex },
	lazy		=> 1,
);

has package => (
	is  => 'rw', 
	isa => 'Str',
);

has method => (
	is  => 'rw',
	isa => 'Str',
);

has action => (
	is  => 'rw',
	isa => 'Object',
);

has parameter_names => (
	is  => 'rw',
	isa => 'ArrayRef',
	default => sub { [] },
);

has 'parameters' => (
	is  => 'rw',
	isa => 'ArrayRef',
);

sub _build_parser {
	my $p = Regexp::Parser->new( '^' . shift->pattern . '$' );
	$p->parse;
	return $p;
}

sub _build_regex {
	my $rx = shift->parser->qr;
	return qr{($rx)};
}

sub parse_path {
	my ($self, $path) = @_;

	my @url_params = $path =~ $self->regex;
	return unless @url_params;

	shift @url_params;
	my $class = blessed($self);

	return $class->new(
		pattern		=> $self->pattern,
		parameters	=> $self->_transform_matched_parameters(\@url_params),
		method		=> $self->method,
		package		=> $self->package,
		parameter_names	=> [ @{ $self->parameter_names } ],
	);
}

sub _transform_matched_parameters {
	my ($self, $params) = @_;
	my $names = $self->parameter_names;
	return $params unless @$names;
	return [
		map { $_ => shift @$params }
		@$names
	];
}

sub generate_path {
    my ($self, $parameters) = @_;

    if ($self->package() ne $parameters->{package} ||
		$self->method() ne $parameters->{method} ) {
		return;
	}

    my $params = $self->_transform_parameters_for_path($parameters->{parameters} || []);
	return unless defined $params;

    my $pattern = $self->pattern();
    my $path; 
 
	if ($self->_find_pattern_match($params)) {
		# Plug in captured parameters if any exist 
		my $final_str = $pattern;
		$final_str =~ /\((.*?)\)/;

		foreach my $param (@$params) {
			$final_str =~ s//$param/;
		}   
       
		# Remove anchor tags should they exist
		$final_str =~ s/(^\^)|((?:\$|\)$))//g;

		return $final_str;
	}

    return;
}

sub _transform_parameters_for_path {
	my ($self, $params) = @_;
	my $names = $self->parameter_names;
	return $params unless @$names;

	$params = ref($params) eq 'HASH' ? { %$params } : { @$params };
	my $result = [ delete @$params{@$names} ];
	return if %$params;
	return $result;
}

sub _find_pattern_match {
	my ($self, $params) = @_;

	my $r = $self->parser;
	if($r->nparen == @$params) {
		my @capture_params;
		my $i = 0;
		foreach my $capture (@{ $r->captures }) {
			my $capture_visual = '^' . $capture->visual() . '$';

			my $param_value = $params->[$i];
			$param_value = '' unless defined $param_value;

			if($param_value !~ /$capture_visual/) { 
				return;
			}
			push(@capture_params, $capture_visual);
			$i++;
		}
		return $r; 
	}
	return;
}

1;

=pod

=head1 NAME 

Vend::URLPattern - responsible for representing a url path pattern and parameters

=head1 SYSOPSIS

 use IC::UserView;
 my $url_obj = Vend::URLPattern->new( { pattern => '^userview/(\d+{2})/$',
                                        object  => 'IC::UserVIew' });
 
 my $path = "userview/20/";
 $self->parse_path($path);

=head1 DESCRIPTION 

A class used to describe a full url path pattern and its parameters.

Rules for Regexp

=over

=item *

No regular expression syntax that is not being used to capture parameters except for anchor tags.

=item *

No pattern matching that isn't being used as a parameter.

=item *

No nested groups/matches.

=back 

=head1 PARAMETERS 

=over

=item pattern 

This is the regexp pattern that is used to parse against the URL.

=back

=over 

=item named_parameters 

This attribute is a list of named parameters that relate to the pattern supplied.  These parameters
must be in the order they are identified in the pattern.  Each identifier in the pattern must also have a 
name.  Any unamed parameters will throw an error upon object instantiation.

=back

=over 


=item package 

This is the package name that is associated with the pattern provided.  This will be used to instantiate an object.

=back

=head1 METHODS

=over 

=item parse_path()

This method is used to parse the path handed to it and set the objects respective command and parameters attributes.

=back

=cut
