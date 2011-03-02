#!perl

use strict;
use warnings;

use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use 5.010;

use Test::More;

use Tapper::Cmd::Queue;
use Tapper::Model 'model';


# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $queue = Tapper::Cmd::Queue->new();
isa_ok($queue, 'Tapper::Cmd::Queue', '$queue');

my $queue_id   = $queue->add({name => 'newqueue', priority => 100});
my $queue_rs = model('TestrunDB')->resultset('Queue')->find($queue_id);
isa_ok($queue, 'Tapper::Cmd::Queue', 'Insert queue / queue id returned');

$queue_rs = model('TestrunDB')->resultset('Queue');
foreach my $queue_r ($queue_rs->all) {
        is($queue_r->runcount, $queue_r->priority, "Insert queue / runcount queue ".$queue_r->name);
        $queue_r->runcount(-1);
        $queue_r->update;
}

my $queue_id_updated = $queue->update($queue_id, {priority => 1337});
ok(defined($queue_id_updated), 'Update queue / success');
foreach my $queue_r ($queue_rs->all) {
        is($queue_r->runcount, $queue_r->priority, "Update queue / runcount queue ".$queue_r->name);
}


done_testing();

