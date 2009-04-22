use strict;
use warnings;

use Test::More tests => 27;
use FindBin;
use lib "$FindBin::Bin/../lib";

my $class;
BEGIN {
	use_ok $class = 'Vend::URLPatterns';
	eval "use Vend::URLPattern";
	eval "use Vend::Action::Standard";
}

# Instantiate registration object URLPatterns
my $patterns_reg = $class->new();

# Make sure its a URLPatterns Object
ok(defined $patterns_reg,  'new() returned something');
ok($patterns_reg->isa($class), 'returned a URLPatterns Object');

# Test urlpattern registration process
my $first_url_pattern = Vend::URLPattern->new({ 
	pattern => 'userview/(\d{2})/',
	package => 'IC::UserView',
	method  => 'get_user'
});

my $second_url_pattern = Vend::URLPattern->new({
	pattern => 'userview/(\d{2})/(\d{4})/',
	package => 'IC::UserView',
	method  => 'save_user'
});

$patterns_reg->register( $first_url_pattern );
is_deeply(
	$patterns_reg->url_patterns,
	[ $first_url_pattern ],
	'register() first pattern',
);

$patterns_reg->register( $second_url_pattern );
is_deeply(
	$patterns_reg->url_patterns,
	[ $first_url_pattern, $second_url_pattern ],
	'register() second pattern',
);

$patterns_reg->register( { pattern => 'foo', package => 'blah', method => 'me' } );
is_deeply(
	[ map { pattern_transform($_) } @{$patterns_reg->url_patterns} ],
	[	pattern_transform($first_url_pattern),
		pattern_transform($second_url_pattern),
	  	{ pattern => 'foo', package => 'blah', method => 'me' },
    ],
	'register() third pattern -- auto-vivify from hash',
);

$patterns_reg = $class->new;
my ($a, %b);
$patterns_reg->register(
	$a = {
		method => 'method_a',
		package => 'package_a',
		pattern => 'pattern_a',
	},
	$first_url_pattern,
	$b = {
		method => 'method_b',
		package => 'package_b',
		pattern => 'pattern_b',
	},
	$second_url_pattern,
);

is_deeply(
	[ map { pattern_transform($_) } @{ $patterns_reg->url_patterns } ],
	[ $a, pattern_transform($first_url_pattern), $b, pattern_transform($second_url_pattern) ],
	'register() list of mixed structures',
);
my $third_url_pattern = Vend::URLPattern->new({
	pattern => 'userview/(\d{2})/(\d{4})/',
	package => 'IC::UserView',
	method  => 'update_user',
});

my $fourth_url_pattern = Vend::URLPattern->new({
	pattern => 'userview/(\d{2})/(\d{4})/',
	package => 'IC::ProductDetail',
	method  => 'save_user',
});

my $fifth_url_pattern = Vend::URLPattern->new({ 
	pattern => 'userview/(\d{2})/(\d{4})/',
	package => 'IC::UserView',
	method  => 'get_user',
});

my $sixth_url_pattern = Vend::URLPattern->new({
	pattern => 'userview/(\d{2})/(\d{4})/',
	package => 'IC::UserView',
	method  => 'update_user',
});

# Make some Standard actionmap objects
my $action_obj = Vend::Action::Standard->new({
	name    => 'product_detail',
	routine => sub { my ($product_id) = @_; return 1; }
});


my $seventh_url_pattern = Vend::URLPattern->new({
	pattern => 'product_detail/.*',
	package => 'IC::ProductDetail',
	method  => 'product_detail',
#action  => $action_obj,
});

$patterns_reg = $class->new;
# Register the patterns
$patterns_reg->register(
	$first_url_pattern,
	$second_url_pattern,
	$third_url_pattern,
	$fourth_url_pattern,
	$fifth_url_pattern,
	$sixth_url_pattern,
	$seventh_url_pattern,
);
# Test url_patterns() method
my $patterns = $patterns_reg->url_patterns();
#is($patterns->[0]->{'catalog_id'}, 'IC', 'returned URLPattern catalog_id from URLPatterns array');
ok($patterns->[0]->isa('Vend::URLPattern'), 'returned URLPattern object from URLPatterns array');
is($patterns->[0]->pattern(), 'userview/(\d{2})/', 'returned URLPattern URL from URLPatterns array');
is($patterns->[0]->package(), 'IC::UserView', 'returned URLPattern Module from URLPatterns array');
is($patterns->[0]->method(), 'get_user', 'returned URLPattern Method from URLPatterns array');

# Test generate_path()
my %params = (
	'package'    => 'IC::UserView',
	'method'     => 'save_user',
    'parameters' => ['32', '2004']
);

my $generated_path = $patterns_reg->generate_path(\%params);

is($generated_path, 'userview/32/2004/', 'Path generated properly:' . $generated_path);

%params = (
	'package'    => 'IC::UserView',
	'method'     => 'save_user',
    'parameters' => ['foo', 'bar']
);

$generated_path = $patterns_reg->generate_path(\%params);
is($generated_path, undef, 'generate_path() returned undef given non-matching params');

# Test parse_path() method
my $path = "userview/32/";
my $result = $patterns->[0]->parse_path($path);
my $param = $result->{parameters}[0];
is($param, '32', 'First registered patterns parameter parsed successfully');

$path = "userview/32/2003/";
my $found_url_pattern_obj = $patterns_reg->parse_path($path);
ok($found_url_pattern_obj->isa('Vend::URLPattern'), 'parse_path() - returned a URLPattern Object');
is($found_url_pattern_obj->pattern(), 'userview/(\d{2})/(\d{4})/', 'parse_path() - returned URLPattern URL from URLPatterns array');
is($found_url_pattern_obj->package(), 'IC::UserView', 'parse_path() - returned URLPattern Module from URLPatterns array');
is($found_url_pattern_obj->method(), 'save_user', 'returned URLPattern Method from URLPatterns array');

$path = "userview/32/";
$found_url_pattern_obj = $patterns_reg->parse_path($path);
ok($found_url_pattern_obj->isa('Vend::URLPattern'), 'parse_path() - returned a URLPattern Object');
is($found_url_pattern_obj->pattern(), 'userview/(\d{2})/', 'parse_path() - returned URLPattern URL from URLPatterns array');
is($found_url_pattern_obj->package(), 'IC::UserView', 'parse_path() - returned URLPattern Module from URLPatterns array');
is($found_url_pattern_obj->method(), 'get_user', 'returned URLPattern Method from URLPatterns array');

my $found_params = $patterns_reg->parse_path($path)->parameters;
print "Params: " . $found_params->[0] . "\n";



$path = "product_detail/SKU01283/The-North-Face-DenaliJacket.html";
$found_url_pattern_obj = $patterns_reg->parse_path($path);
ok($found_url_pattern_obj->isa('Vend::URLPattern'), 'parse_path() - returned a URLPattern Object');
is($found_url_pattern_obj->pattern(), 'product_detail/.*', 'parse_path() - returned URLPattern URL from URLPatterns array');
is($found_url_pattern_obj->package(), 'IC::ProductDetail', 'parse_path() - returned URLPattern Module from URLPatterns array');
#ok($found_url_pattern_obj->action()->isa('Vend::Action::Standard'), 'URL::Pattern instance has an action attribute defined');
is($found_url_pattern_obj->method, 'product_detail', 'parse_path() - URLPattern object has appropriate method');
#$found_params = $patterns_reg->parse_path($path)->parameters;
#print "Params: " . $found_params->[0] . "\n";

# Make sure a non match returns 0
$path = "userview/word/";
$found_url_pattern_obj = $patterns_reg->parse_path($path);
is($found_url_pattern_obj, undef, 'pattern_for_path() returned 0 properly for an unmatched path');

sub pattern_transform {
	my $o = shift;
	return {} unless ref($o) eq 'Vend::URLPattern';
	return {
		pattern => $o->pattern,
		method => $o->method,
		package => $o->package,
	};
}

