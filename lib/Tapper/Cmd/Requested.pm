package Tapper::Cmd::Requested;
use Moose;

use Tapper::Model 'model';
use parent 'Tapper::Cmd';


=head1 NAME

Tapper::Cmd::Request - Backend functions for manipluation of requested hosts or features in the database

=head1 SYNOPSIS

This project is offers wrapper around database manipulation functions. These
wrappers handle things like setting default values or id<->name
translation. This module handles requested hosts and features for a
testrequest.

    use Tapper::Cmd::Testrun;

    my $bar = Tapper::Cmd::Testrun->new();
    $bar->add($testrun);
    ...

=head1 FUNCTIONS


=head2 add_host

Add a requested host entry to database.

=cut


=head2 add_host

Add a requested host for a given testrun.

@param int    - testrun id
@param string - hostname

@return success - local id (primary key)
@return error   - undef

=cut

sub add_host {
        my ($self, $id, $hostname) = @_;
        my $hosts = model('TestrunDB')->resultset('Host')->search({name => $hostname});
        return if not $hosts->count;
        my $host_id = $hosts->first->id;
        my $request = model('TestrunDB')->resultset('TestrunRequestedHost')->new({testrun_id => $id, host_id => $host_id});
        $request->insert();
        return $request->id;
}

=head2 add_feature

Add a requested feature for a given testrun.

@param int    - testrun id
@param string - feature

@return success - local id (primary key)
@return error   - undef

=cut

sub add_feature {
        my ($self, $id, $feature) = @_;

        my $request = model('TestrunDB')->resultset('TestrunRequestedFeature')->new({testrun_id => $id, feature => $feature});
        $request->insert();
        return $request->id;
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
