package Tapper::Cmd::DbDeploy;
BEGIN {
  $Tapper::Cmd::DbDeploy::AUTHORITY = 'cpan:TAPPER';
}
{
  $Tapper::Cmd::DbDeploy::VERSION = '4.1.8';
}
# ABSTRACT: Tapper - Backend functions for DB deployment

use 5.010;
use strict;
use warnings;

use Moose;
use Tapper::Config;
use Tapper::Schema::TestrunDB;
use Tapper::Schema::ReportsDB;

extends 'Tapper::Cmd';



sub insert_initial_values
{
        my ($schema, $db) = @_;

        if ($db eq 'TestrunDB')
        {
                # ---------- Topic ----------

                # official topics
                my %topic_description = %Tapper::Schema::TestrunDB::Result::Topic::topic_description;

                foreach my $topic_name(keys %topic_description) {
                        my $topic = $schema->resultset('Topic')->new
                            ({ name        => $topic_name,
                               description => $topic_description{$topic_name},
                             });
                        $topic->insert;
                }
                my $queue = $schema->resultset('Queue')->new
                  ({ name     => 'AdHoc',
                     priority => 1000,
                     active   => 1,
                   });
                $queue->insert;

        }
}


sub dbdeploy
{
        my ($self, $db) = @_;

        local $| =1;

        my $dsn  = Tapper::Config->subconfig->{database}{$db}{dsn};
        my $user = Tapper::Config->subconfig->{database}{$db}{username};
        my $pw   = Tapper::Config->subconfig->{database}{$db}{password};
        my $answer;

        # ----- really? -----
        print "dsn: $dsn\n";
        print "     Really delete all existing content and initialize from scratch (y/N)? ";
        if ( lc substr(<STDIN>, 0, 1) ne 'y') {
                say "Skip.";
                return;
        }

        # ----- delete sqlite file -----
        if ($dsn =~ /dbi:SQLite:dbname/) {
                my ($tmpfname) = $dsn =~ m,dbi:SQLite:dbname=([\w./]+),i;
                unlink $tmpfname;
        }

        my $stderr = '';
        {
                # capture known errors to hide them from printing
                local *STDERR;
                open STDERR, '>', \$stderr;

                my $schema;
                $schema = Tapper::Schema::TestrunDB->connect ($dsn, $user, $pw) if $db eq 'TestrunDB';
                $schema = Tapper::Schema::ReportsDB->connect ($dsn, $user, $pw) if $db eq 'ReportsDB';
                $schema->deploy({ add_drop_table => 1 }); # may fail, does not provide correct order to drop tables
                insert_initial_values($schema, $db);
        }
        say STDERR $stderr if $stderr && $stderr !~ /Please call upgrade on your schema/;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Tapper::Cmd::DbDeploy - Tapper - Backend functions for DB deployment

=head1 SYNOPSIS

This module provides functions to initially set up Tapper in C<$HOME/.tapper/>.

    use Tapper::Cmd::DbDeploy;
    my $cmd = Tapper::Cmd::DbDeploy->new;
    $cmd->dbdeploy("ReportsDB");
    $cmd->dbdeploy("TestrunDB");

=head1 NAME

Tapper::Cmd::DbDeploy - Tapper - Backend functions for deploying databases

=head1 METHODS

=head2 insert_initial_values($schema, $db)

Insert required minimal set of values.

=head2 $self->dbdeploy($db)

Deploy a schema into DB.

$db can be "TestrunDB" or "ReportsDB";

Connection info is determined via Tapper::Config.

TODO: still an interactive tool but interactivity should be migrated back into Tapper::CLI::*.

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
