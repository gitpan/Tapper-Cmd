package Tapper::Cmd::Notification;
BEGIN {
  $Tapper::Cmd::Notification::AUTHORITY = 'cpan:TAPPER';
}
{
  $Tapper::Cmd::Notification::VERSION = '4.1.7';
}
use Moose;

use Tapper::Model 'model';
use YAML::Syck;

use parent 'Tapper::Cmd';



sub get_user
{
        my ($self, $data) = @_;
        if (not $data->{owner_id}) {
                my $login = $data->{owner_login} || $ENV{USER};
                my $owner = model('ReportsDB')->resultset('Owner')->search({login => $login}, {rows => 1})->first;
                if (not $owner) {
                        die "User '$login' does not exist in the database. Please create this user first.\n";
                }

                $data->{owner_id} = $owner->id;
                delete $data->{owner_login};
        }
        return $data;
}




sub add {
        my ($self, $data) = @_;

        $data = $self->get_user($data);

        my $notification = model('ReportsDB')->resultset('Notification')->new($data);
        $notification->insert;

        return $notification->id;
}


sub list
{
        my ($self, $search) = @_;
        return model('ReportsDB')->resultset('Notification')->search($search, { result_class => 'DBIx::Class::ResultClass::HashRefInflator' });
}



sub update {
        my ($self, $id, $data) = @_;

        my $notification = model('ReportsDB')->resultset('Notification')->find($id);
        die "Notification subscription with id $id not found\n" if not $notification;
        die "Did not get a hash with data for updating notification subscription with id '$id'" unless ref $data eq 'HASH';

        $data = $self->get_user($data);


        foreach my $key (keys %$data) {
                $notification->$key($data->{$key});
        }
        $notification->update;
        return $notification->id;
}



sub del {
        my ($self, $id) = @_;
        my $notification = model('ReportsDB')->resultset('Notification')->find($id);
        die qq(No notification subscription with id "$id" found) if not $notification;;
        $notification->delete();
        return 0;
}




1; # End of Tapper::Cmd::Testrun

__END__

=pod

=encoding utf-8

=head1 NAME

Tapper::Cmd::Notification

=head1 SYNOPSIS

This project offers backend functions for all projects that manipulate
notification subscriptions.

    use Tapper::Cmd::Notification;

    my $subscription = Tapper::Cmd::Notification->new();

    my $details = {event      => "testrun_finished",
                   filter  => "testrun('id') == 23",
                   comment    => "Get back to work, testrun 23 is finished",
                   persist    => 0,
                   owner_login => 'anton',
                  };
    my $id = $subscription->add($details);
    $details->{filter} = "testrun('id') == 24";
    my $error = $subscription->update($id, $details);
    $error = $subscription->delete($id);

=head1 NAME

Tapper::Cmd::Notification - Backend functions for manipluation of notification subscriptions in the database

=head1 FUNCTIONS

=head2 get_user

Make sure the user is given as user id.

@param hash ref - data for notification subscription

@param success - updated hash ref

@throws die

=head2 add

Add a new notification subscription. Expects all details as a hash reference.

@param string    - preconditions in YAML format OR
@param hash ref  - notification subscrition data

@return success - subscrition id
@return error   - undef

@throws Perl die

=head2 list

Return a DBIC resultset object that contains a list of notification
subscriptions.

=head2 update

Update a given notification subscription. The given data has to be a
complete hash of what the subscription should look like after the
update.

@param int      - subscription id
@param hash ref - subscription as it should be

@return success - subscription id

@throws die

=head2 del

Delete a notification subscription with given id. Its named del instead of delete to
prevent confusion with the buildin delete function.

@param int - notification id

@return success - 0

@throws die

=head1 AUTHOR

AMD OSRC Tapper Team, C<< <tapper at amd64.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012 AMD OSRC Tapper Team, all rights reserved.

This program is released under the following license: freebsd

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
