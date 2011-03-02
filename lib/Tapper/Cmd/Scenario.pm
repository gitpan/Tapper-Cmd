package Tapper::Cmd::Scenario;
use Moose;

use Tapper::Model 'model';

use parent 'Tapper::Cmd';


=head1 NAME

Tapper::Cmd::Scenario - Backend functions for manipulation of scenario in the database

=head1 SYNOPSIS

This project offers backend functions for all projects for manipulation the
database on a higher level than that offered by Tapper::Schema.

    use Tapper::Cmd::Scenario;

    my $bar = Tapper::Cmd::Scenario->new();
    $bar->add($scenario);
    ...

=head1 FUNCTIONS


=head2 add

Add a new scenario to database.

=cut


=head2 add

Add a new scenario to database

@param hash ref - options for new scenario

@return success - scenario id
@return error   - undef

=cut

sub add {
        my ($self, $args) = @_;
        my %args = %{$args};    # copy
        my $scenario = model('TestrunDB')->resultset('Scenario')->new(\%args);
        $scenario->insert;
        return $scenario->id;
}
        


=head2 del

Delete a testrun with given id. Its named del instead of delete to
prevent confusion with the buildin delete function.

@param int - testrun id

@return success - 0
@return error   - error string

=cut

sub del {
        my ($self, $id) = @_;
        my $scenario = model('TestrunDB')->resultset('Scenario')->find($id);
        $scenario->delete();
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
