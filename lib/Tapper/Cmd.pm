package Tapper::Cmd;

=head1 NAME

Tapper::Cmd - Tapper - Backend functions for CLI and Web

=cut
use Moose;

use Tapper::Model 'model';

our $VERSION = '3.000002';

=head1 SYNOPSIS

This project offers backend functions for all projects that manipulate
testruns or preconditions in the database. This module is the base module that
contains common functions of all modules in the project. No such functions
exist yet.

    use Tapper::Cmd::Testrun;
    use Tapper::Cmd::Precondition;

    my $foo = Tapper::Cmd::Precondition->new();
    $foo->add($precondition);

    my $bar = Tapper::Cmd::Testrun->new();
    $bar->add($testrun);
    ...

=head1 FUNCTIONS

=cut 



=head2 assign_preconditions

Assign a list of preconditions to a testrun. Both have to be given as valid
ids.

@param int - testrun id
@param array of int - precondition ids

@return success - 0
@return error   - error string

=cut

sub assign_preconditions
{
        my ($self, $testrun_id, @preconditions) = @_;
        my $testrun = model('TestrunDB')->resultset('Testrun')->find($testrun_id);
        return $testrun->assign_preconditions(@preconditions);

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

1; # End of Tapper::Cmd
