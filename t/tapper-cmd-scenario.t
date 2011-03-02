#!perl

use strict;
use warnings;

use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use 5.010;

use Test::More;

use Tapper::Cmd::Scenario;
use Tapper::Model 'model';


# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $scen = Tapper::Cmd::Scenario->new();
isa_ok($scen, 'Tapper::Cmd::Scenario', '$scenario');

my $retval  = $scen->add({type => 'interdep'});
my $scen_rs = model('TestrunDB')->resultset('Scenario')->find($retval);
isa_ok($scen_rs, 'Tapper::Schema::TestrunDB::Result::Scenario', 'Insert scenario / scenario id returned');

$retval  = $scen->del($scen_rs->id);
is($retval, 0, 'Delete scenario');
$scen_rs = model('TestrunDB')->resultset('Scenario')->find($scen_rs->id);

done_testing();

