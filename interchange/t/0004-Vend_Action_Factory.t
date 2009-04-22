use warnings;
use strict;

use Test::More tests => 16;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Vend::Action::Factory;
use Class::MOP::Class;

my $global_module = "ProductView";
my $catalog_module = "MyAccount";
my $actionmap_name = 'my_account';
my $catalog = 'IC';


# TODO - test global runtime namespace and package name creation

# Unit test for action_class_for() for Catalog specific package
my $package_name = Vend::Action::Factory->action_class_for( $catalog, $actionmap_name );
is(
	$package_name,
	"Vend::Runtime::Catalogs::${catalog}::Actions::$actionmap_name",
	'action_class_for catalog action',
);

# Unit test for action_class_for() for global package (catalog is undef)
$package_name = Vend::Action::Factory->action_class_for(
	undef,
	$actionmap_name,
);

is(
	$package_name,
	"Vend::Runtime::Global::Actions::$actionmap_name",
	'action_class_for global action',
);

# Test complete use of create_action() with a Global package
my %global_module_parameters = ( product_id => '2');

my $method = sub {
	my $params= shift;
	return $$params[0];
};

my %global_parameters = (
	name     => $global_module,
	routine  => $method
);

my $product_view = Vend::Action::Factory->create_action(%global_parameters);

ok(defined $product_view,  'new() returned something');
is(
	$product_view,
	"Vend::Runtime::Global::Actions::ProductView",
	'create_action returned new package name',
);
$product_view = eval { $product_view->new };
isa_ok(
	$product_view,
	'Vend::Action::Standard',
);
isa_ok(
	$product_view,
	'Vend::Runtime::Global::Actions::ProductView',
);
cmp_ok(
	$product_view->routine,
	'==',
	$method,
	'routine() returns correct subref',
);

my %catalog_param = (
	name	=> 'catalog_action',
	routine	=> sub { return $method->(@_) },
	catalog => 'deathdogs',
);
$package_name = Vend::Action::Factory->create_action(%catalog_param);
is(
	$package_name,
	"Vend::Runtime::Catalogs::$catalog_param{catalog}::Actions::$catalog_param{name}",
	'create_action for catalog action',
);
my $result = eval {$package_name->new};
isa_ok(
	$result,
	'Vend::Action::Standard',
);
isa_ok(
	$result,
	$package_name,
);
cmp_ok(
	$result->routine,
	'==',
	$catalog_param{routine},
	'routine() set appropriately for catalog action',
);

# Test complete use of create_action() which calls action_class_for()
my %module_parameters = ( user_id  => '12',
                          view_all => '1' );

my $user_view = Vend::Action::Factory->create_action(
	name     => $catalog_module,
	catalog  => $catalog,
	routine  => sub { return eval "$method->(@_)" },
); 

my $final_path = 'MyAccount';
my $url_patterns = Vend::URLPatterns::Registry->patterns_for($catalog);
my $catalog_url_pattern = $url_patterns->parse_path($final_path);; 
is(
	$catalog_url_pattern->package,
	$user_view,
	'create_action configures default path as expected (bare path)',
);

is(
	Vend::URLPatterns::Registry->patterns_for($catalog)->parse_path('MyAccount/aardvark')->package,
	$user_view,
	'create_action default path configuration handles arbitrary length',
);

# Test use of create_action() when given a pattern
$method = sub {
	my $params= shift;
	return ++$$params[0];
};


$package_name = Vend::Action::Factory->create_action(
	name    => 'product_detail',
	catalog => $catalog,
	routine => $method,
	pattern => 'oofguef/(\d+)',
); 

$final_path = 'oofguef/23';
$url_patterns = Vend::URLPatterns::Registry->patterns_for($catalog);
$catalog_url_pattern = $url_patterns->parse_path($final_path);
is(
	$catalog_url_pattern->package,
	$package_name,
	'create_action uses custom pattern when specified',
);

$package_name = Vend::Action::Factory->create_action(
	name    => 'u_wanna_git_some_akshun',
	catalog => $catalog,
	routine => $method,
	pattern => 'akshun/(is|isnt)/good_for/(mr|mrs|ms|miss)/(froggy|piggy)',
	parameters => [qw( verb_to_be title animal )],
);
$catalog_url_pattern = Vend::URLPatterns::Registry->patterns_for($catalog)->parse_path(
	'akshun/isnt/good_for/mrs/froggy'
);
is(
	$catalog_url_pattern->package,
	$package_name,
	'create_action uses custom pattern when specified, with positional parameter names',
);
is_deeply(
	{ @{ $catalog_url_pattern->parameters } },
	{
		verb_to_be => 'isnt',
		title      => 'mrs',
		animal     => 'froggy',
	},
	'create_action registers positional parameter names appropriately',
);
