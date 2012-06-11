#!perl

use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use 5.010;

use warnings;
use strict;

use Test::More;

use Tapper::Cmd::User;
use Tapper::Model 'model';


# -----------------------------------------------------------------------------------
construct_fixture( schema  => reportsdb_schema,  fixture => 't/fixtures/reportsdb/report.yml' );
# -----------------------------------------------------------------------------------

my $cmd = Tapper::Cmd::User->new();
isa_ok($cmd, 'Tapper::Cmd::User');


#######################################################
#
#   check add method
#
#######################################################

my $content = {login => "anton2",
               name  => 'Anton Gorodetzky',
               contacts => [{
                             protocol => 'Mail',
                             address  => 'anton@nightwatch.ru',
                            }]
              };

my $user_id = $cmd->add($content);
ok(defined($user_id), 'Adding user');

my @users = $cmd->list();
my $expected_users = [
                      {
                       id=> 1,
                       contacts => [{ address => "anton\@mail.net", protocol => "mail" }],
                       login => "anton",
                       name => "Anton Gorodezki",
                      },
                      { id => 2, contacts => [], login => "alissa", name => "Alissa Donnikowa" },
                      {
                       id => 3,
                       contacts => [{ address => "anton\@nightwatch.ru", protocol => "Mail" }],
                       login => "anton2",
                       name => "Anton Gorodetzky",
                      },
                     ];
is_deeply(\@users, $expected_users, 'Get users as expected');

$cmd->contact_add('anton2', {protocol => 'Jabber', address => 'anton@jabber.ru'});
@users = $cmd->list();

$expected_users = [
                   {
                    id=> 1,
                    contacts => [{ address => "anton\@mail.net", protocol => "mail" }],
                    login => "anton",
                    name => "Anton Gorodezki",
                   },
                   {
                    id => 2, contacts => [], login => "alissa", name => "Alissa Donnikowa" },
                   {
                    id => 3,
                    contacts => [{ address => "anton\@nightwatch.ru", protocol => "Mail" },
                                 {
                                  address => "anton\@jabber.ru", protocol => "Jabber"   }],
                    login => "anton2",
                    name => "Anton Gorodetzky",
                   },
                  ];
is_deeply(\@users, $expected_users, 'Contact information added');


$cmd->del($user_id);
@users = $cmd->list();
$expected_users = [
                      {
                       id => 1,
                       contacts => [{ address => "anton\@mail.net", protocol => "mail" }],
                       login => "anton",
                       name => "Anton Gorodezki",
                      },
                      { id => 2, contacts => [], login => "alissa", name => "Alissa Donnikowa" },
                     ];
is_deeply(\@users, $expected_users, 'Expected users after deleting');

done_testing();
