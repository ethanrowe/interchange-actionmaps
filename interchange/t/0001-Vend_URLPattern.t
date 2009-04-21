use strict;
use warnings;

use Test::More tests => 41;
use FindBin;
use lib "$FindBin::Bin/../lib";

my $class;
BEGIN {
	use_ok $class = 'Vend::URLPattern';
}

my @named_parameters = qw(user_id group_id);
my %standard_constructor_arg = (
	pattern          => 'userview/(\d{2})/(\d{4})/',
	package          => 'IC::UserView',
	method           => 'get_user',
);

my $url_pattern = $class->new( %standard_constructor_arg, pattern => 'simple');
# Test object instantiation 
ok(defined $url_pattern,  'new() returned something');
ok($url_pattern->isa('Vend::URLPattern'), 'returned a URLPattern Object');
is_deeply($url_pattern->parameter_names, [], 'parameter_names empty by default');
is($url_pattern->package(), 'IC::UserView', 'Catalog ID');
is($url_pattern->method(), 'get_user', 'Method is correct');
is($url_pattern->pattern, 'simple', 'Simple pattern is correct');
my $parser = $url_pattern->parser;
isa_ok($parser, 'Regexp::Parser', 'parser attribute defaults to Regexp::Parser instance');
is($url_pattern->parser, $parser, 'parser value is cached in the object');
my $regex = $url_pattern->regex;
isa_ok($regex, 'Regexp', 'regex attribute defaults to a Regexp object');
cmp_ok($url_pattern->regex, '==', $regex, 'regex attribute value is cached in the object');
$url_pattern->pattern('^some_new_pattern$');
isnt($url_pattern->parser, $parser, 'parser attribute reset when pattern changes');
cmp_ok($url_pattern->regex, '!=', $regex, 'regex attribute reset when pattern changes');

$url_pattern = $class->new( %standard_constructor_arg, pattern => 'simple' );

# simple path parser check
my $result = $url_pattern->parse_path('simple');
isa_ok($result, $class);
ok(!defined($url_pattern->parse_path('not simple')), 'simple non-matching path returns undef (prefix)');
ok(!defined($url_pattern->parse_path('simple not')), 'simple non-matching path returns undef (suffix)');
ok(
	!defined($url_pattern->generate_path({ package	=> 'foo', method => $standard_constructor_arg{method} })),
	'generate_path() returns undef when package does not match',
);
ok(
	!defined($url_pattern->generate_path({ package => $standard_constructor_arg{package}, method => 'blah' })),
	'generate_path() returns undef when method does not match',
);
is(
	$url_pattern->generate_path({
		package	=> $standard_constructor_arg{package},
		method	=> $standard_constructor_arg{method},
	}),
	'simple',
	'generate_path() works for simple case',
);

$url_pattern = $class->new( %standard_constructor_arg );
is($url_pattern->pattern(), 'userview/(\d{2})/(\d{4})/', 'URL');

# Test parse_path() functionality
my $path = "userview/foo/2004";
$result = $url_pattern->parse_path($path);
is($result, undef, 'parse_path: Undef returned as expected.');

$path = "userview/203/2004";
$result = $url_pattern->parse_path($path);
is($result, undef, 'parse_path(): Undef returned as expected.');

$path = "userview/32/2004";
$result = $url_pattern->parse_path($path);
is($result, undef, 'parse_path(): Undef returned as expected.');

$path = "userview/32/2004/";
$result = $url_pattern->parse_path($path);

isa_ok($result, $class);
isnt($result, $url_pattern, 'result object is not the original object');
is($result->pattern, $url_pattern->pattern, 'result object has matching pattern from original object');
is($result->package, $url_pattern->package, 'result object has matching package from original object');
is($result->method, $url_pattern->method, 'result object has matching method from original object');
is_deeply($result->parameter_names, $url_pattern->parameter_names, 'result object has matching parameter names');
is_deeply($result->parameters, [32, 2004], 'result object parameter list is in unnamed list form');

$url_pattern = $class->new(
	%standard_constructor_arg,
	parameter_names => \@named_parameters,
);

is_deeply($url_pattern->parameter_names, \@named_parameters, 'parameter_names set/get');
$result = $url_pattern->parse_path($path);
isa_ok( $result, $class );
is_deeply(
	{ @{$result->parameters} },
	{
		user_id		=> 32,
		group_id	=> 2004,
	},
	'result object has hash-style parameter list when named parameters are present',
);

# Test generate_path() functionality
$url_pattern = $class->new(%standard_constructor_arg);

my %params = ( 
	package    => 'IC::ProductDetail',
	method     => 'get_user',
	parameters => [ '32', '2004']
);

$result = $url_pattern->generate_path(\%params);

is($result, undef, 'generate_path(): Undef returned as expected.');

%params = ( 
	package    => 'IC::UserView',
	method     => 'update_user',
	parameters => [ '32', '2004']
);

$result = $url_pattern->generate_path(\%params);

is($result, undef, 'generate_path(): Undef returned as expected.');

%params = ( 
	package    => 'IC::UserView',
	method     => 'get_user',
	parameters => [ ] 
);

$result = $url_pattern->generate_path(\%params);

is($result, undef, 'generate_path(): Undef returned as expected.');

%params = ( 
	package    => 'IC::UserView',
	method     => 'get_user',
	parameters => [ 'foo', 'bar' ] 
);

$result = $url_pattern->generate_path(\%params);

is($result, undef, 'generate_path(): Undef returned as expected.');

%params = ( 
	package    => 'IC::UserView',
	method     => 'get_user',
	parameters => [ '32', '2000' ] 
);

$result = $url_pattern->generate_path(\%params);

is($result, 'userview/32/2000/', 'generate_path(): Undef returned as expected.');

$url_pattern = $class->new(%standard_constructor_arg, parameter_names => \@named_parameters);
$params{parameters} = {
	user_id		=> 32,
	group_id	=> 2000,
	garbage		=> undef,
};
ok(
	!defined($url_pattern->generate_path(\%params)),
	'generate_path() undefined if parameter hash includes unknown name',
);
delete $params{parameters}->{garbage};
is(
	$url_pattern->generate_path(\%params),
	'userview/32/2000/',
	'generate_path() returns proper path when parameter hash names match with known param names',
);
delete $params{parameters}->{user_id};
ok(
	!defined($url_pattern->generate_path(\%params)),
	'generate_path() undefined when parameter hash is missing a known name that is required',
);

