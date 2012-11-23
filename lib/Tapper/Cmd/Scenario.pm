package Tapper::Cmd::Scenario;
BEGIN {
  $Tapper::Cmd::Scenario::AUTHORITY = 'cpan:TAPPER';
}
{
  $Tapper::Cmd::Scenario::VERSION = '4.1.3';
}
use Moose;

use Tapper::Model 'model';

use parent 'Tapper::Cmd';





sub add {
        my ($self, $args) = @_;
        my %args = %{$args};    # copy
        my $scenario = model('TestrunDB')->resultset('Scenario')->new(\%args);
        $scenario->insert;
        return $scenario->id;
}




sub del {
        my ($self, $id) = @_;
        my $scenario = model('TestrunDB')->resultset('Scenario')->find($id);
        $scenario->delete();
        return 0;
}

1; # End of Tapper::Cmd::Testrun

__END__
=pod

=encoding utf-8

=head1 NAME

Tapper::Cmd::Scenario

=head1 SYNOPSIS

This project offers backend functions for all projects for manipulation the
database on a higher level than that offered by Tapper::Schema.

    use Tapper::Cmd::Scenario;

    my $bar = Tapper::Cmd::Scenario->new();
    $bar->add($scenario);
    ...

=head1 NAME

Tapper::Cmd::Scenario - Backend functions for manipulation of scenario in the database

=head1 FUNCTIONS

=head2 add

Add a new scenario to database.

=head2 add

Add a new scenario to database

@param hash ref - options for new scenario

@return success - scenario id
@return error   - undef

=head2 del

Delete a testrun with given id. Its named del instead of delete to
prevent confusion with the buildin delete function.

@param int - testrun id

@return success - 0
@return error   - error string

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

