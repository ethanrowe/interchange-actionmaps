use strict;
use warnings;

use Test::More tests => 11;
use FindBin;
use lib "$FindBin::Bin/../lib";

my $class;
BEGIN {
	use_ok $class = 'Vend::URLPatterns::Registry';
	eval 'use Vend::Action::Standard';
	eval 'use Vend::URLPattern';
}

# Test Catalog Specific registration
my $catalog_id = "IC";
my @patterns;
my $url_obj = Vend::URLPattern->new({
	pattern => '^userview/(\d+{2})/$',
	package => 'IC::UserView',
	method  => 'get_user',
});
push(@patterns, $url_obj);

$url_obj = Vend::URLPattern->new({
	pattern => '^userview/(\d+{2})/$',
	package => 'IC::UserView',
	method  => 'save_user',
});
push(@patterns, $url_obj);

$url_obj = Vend::URLPattern->new({
	pattern => '^product_detail/(\d+{3})(\w+{4})/$',
	package => 'IC::ProductDetail',
	method  => 'get_product',
});
push(@patterns, $url_obj);

my $result = $class->register_patterns($catalog_id, @patterns);
is($result, scalar(@patterns), 'register_patterns(): Successfully registered patterns');

my $url_patterns = $class->patterns_for($catalog_id);
ok(defined $url_patterns,  'patterns_for(): returned something defined');
ok($url_patterns->isa('Vend::URLPatterns'), 'returned a URLPatterns Object');

is($url_patterns->url_patterns()->[0]->method(), 'get_user', 'First URLPattern method returned correctly');
is($url_patterns->url_patterns()->[1]->method(), 'save_user', 'Second URLPattern method returned correctly');
is($url_patterns->url_patterns()->[2]->method(), 'get_product', 'Third URLPattern method returned correctly');

# Test Global registration (catalog_id undef)
@patterns = ();
$url_obj = Vend::URLPattern->new({
	pattern => '^contact/$',
	package => 'IC::Contact',
	method  => 'get_contact_info',
});
push(@patterns, $url_obj);

$url_obj = Vend::URLPattern->new({
	pattern => '^product_detail/(\d+{3})(\w+{4})/$',
	package => 'IC::ProductDetail',
	method  => 'get_product',
});
push(@patterns, $url_obj);

$result = $class->register_patterns('', @patterns);
is($result, scalar(@patterns), 'register_patterns(): Successfully registered patterns');

$url_patterns = $class->patterns_for('');

is($url_patterns->url_patterns()->[0]->method(), 'get_contact_info', 'First Global URLPattern method returned correctly');
is($url_patterns->url_patterns()->[1]->method(), 'get_product', 'Second Global URLPattern method returned correctly');

# Test edge-case where the catalog should not be found
$url_patterns = $class->patterns_for('store');
is($url_patterns, undef, 'patterns_for(): Returned undef for no patterns found');
