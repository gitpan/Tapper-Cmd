package Tapper::Cmd::Queue;
use Moose;

use DateTime;

use Tapper::Model 'model';

extends 'Tapper::Cmd';


=head1 NAME

Tapper::Cmd::Queue - Backend functions for manipluation of queues in the database

=head1 SYNOPSIS

This project offers backend functions for all projects that manipulate
queues in the database. This module handles the testrun part.

    use Tapper::Cmd::Queue;

    my $bar = Tapper::Cmd::Queue->new();
    $bar->add($testrun);
    ...

=head1 FUNCTIONS

=head2 add

Add a new queue to database.

=cut


=head2 add

Add a new queue.
-- required --
* name - string
* priority - int

@param hash ref - options for new queue

@return success - queue id
@return error   - undef

=cut

sub add {
        my ($self, $args) = @_;
        my %args = %{$args};    # copy

        my $q = model('TestrunDB')->resultset('Queue')->new(\%args);
        $q->insert;
        my $all_queues = model('TestrunDB')->resultset('Queue');
        foreach my $queue ($all_queues->all) {
                $queue->runcount($queue->priority);
                $queue->update;
        }
        return $q->id;
}


=head2 update

Changes values of an existing queue. 

@param int      - queue id
@param hash ref - overwrite these options

@return success - queue id
@return error   - undef

=cut

sub update {
        my ($self, $id, $args) = @_;
        my %args = %{$args};    # copy

        my $queue = model('TestrunDB')->resultset('Queue')->find($id);
        my $retval = $queue->update_content(\%args);

        my $all_queues = model('TestrunDB')->resultset('Queue');
        foreach my $queue ($all_queues->all) {
                $queue->runcount($queue->priority);
                $queue->update;
        }

        return $retval;
}

=head2 del

Delete a queue with given id. Its named del instead of delete to
prevent confusion with the buildin delete function.

@param int - queue id

@return success - 0
@return error   - error string

=cut

sub del {
        my ($self, $id) = @_;
        my $testrun = model('TestrunDB')->resultset('Queue')->find($id);
        $testrun->delete();
        return 0;
}



=head1 AUTHOR

AMD OSRC Tapper Team, C<< <tapper at amd64.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<osrc-sysin at elbe.amd.com>, or through
the web interface at L<https://osrc/bugs>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 COPYRIGHT & LICENSE

Copyright 2008-2011 AMD OSRC Tapper Team, all rights reserved.

This program is released under the following license: freebsd

=cut

1; # End of Tapper::Cmd::Testrun
