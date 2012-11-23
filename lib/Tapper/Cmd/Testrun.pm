package Tapper::Cmd::Testrun;
BEGIN {
  $Tapper::Cmd::Testrun::AUTHORITY = 'cpan:TAPPER';
}
{
  $Tapper::Cmd::Testrun::VERSION = '4.1.3';
}
use Moose;
use Tapper::Model 'model';
use DateTime;
use Perl6::Junction qw/any/;
use Hash::Merge::Simple qw/merge/;

use parent 'Tapper::Cmd';
use Tapper::Cmd::Requested;
use Tapper::Cmd::Precondition;




sub find_matching_hosts
{
        return;
}



sub create
{
        my ($self, $plan, $instance) = @_;
        my $cmd           = Tapper::Cmd::Precondition->new();
        my @preconditions = $cmd->add($plan->{preconditions});
        my %args          = map { lc($_) => $plan->{$_} } grep { lc($_) eq any('topic', 'queue')} keys %$plan;

        my @testruns;
        foreach my $host (@{$plan->{requested_hosts_all} || [] }) {
                my $merged_arguments = merge \%args, {precondition    => $plan->{preconditions},
                                                      requested_hosts => $host,
                                                      testplan_id     => $instance,
                                                     };
                my $testrun_id = $self->add($merged_arguments);
                $self->assign_preconditions($testrun_id, @preconditions);
                push @testruns, $testrun_id;
        }
        if ($plan->{requested_hosts_any}) {
                my $merged_arguments = merge \%args, {precondition    => $plan->{preconditions},
                                                      requested_hosts => $plan->{requested_hosts_any},
                                                      testplan_id     => $instance};
                my $testrun_id = $self->add($merged_arguments );
                $self->assign_preconditions($testrun_id, @preconditions);
                push @testruns, $testrun_id;
        }
        foreach my $host ($self->find_matching_hosts($plan->{requested_features_all})) {
                my $merged_arguments = merge \%args, {precondition    => $plan->{preconditions},
                                                      requested_hosts => $host,
                                                      testplan_id     => $instance};
                my $testrun_id = $self->add($merged_arguments );
                $self->assign_preconditions($testrun_id, @preconditions);
                push @testruns, $testrun_id;
        }
        if ($plan->{requested_features_any}) {
                my $merged_arguments = merge \%args, {precondition       => $plan->{preconditions},
                                                      requested_features => $plan->{requested_features_any},
                                                      testplan_id        => $instance};
                my $testrun_id = $self->add($merged_arguments );
                $self->assign_preconditions($testrun_id, @preconditions);
                push @testruns, $testrun_id;
        }
        return @testruns;
}




sub add {
        my ($self, $received_args) = @_;
        my %args = %{$received_args}; # copy

        $args{notes}                 ||= '';
        $args{shortname}             ||= '';

        $args{topic_name}              = $args{topic}    || 'Misc';
        my $topic = model('TestrunDB')->resultset('Topic')->find_or_create({name => $args{topic_name}});

        $args{earliest}              ||= DateTime->now;
        $args{owner}                 ||= $ENV{USER} || 'nobody';
        $args{owner_id}              ||= Tapper::Model::get_or_create_owner( $args{owner} );

        if ($args{requested_hosts} and not $args{requested_host_ids}) {
                foreach my $host (@{ref $args{requested_hosts} eq 'ARRAY' ? $args{requested_hosts} : [ $args{requested_hosts} ]}) {
                        my $host_result = model('TestrunDB')->resultset('Host')->search({name => $host}, {rows => 1})->first;
                        push @{$args{requested_host_ids}}, $host_result->id if $host_result;
                }
        }

        if (not $args{queue_id}) {
                $args{queue}   ||= 'AdHoc';
                my $queue_result = model('TestrunDB')->resultset('Queue')->search({name => $args{queue}});
                die qq{Queue "$args{queue}" does not exists\n} if not $queue_result->count;
                $args{queue_id}  = $queue_result->search({}, {rows => 1})->first->id;
        }
        my $testrun_id = model('TestrunDB')->resultset('Testrun')->add(\%args);

        if ($args{requested_features}) {
                foreach my $feature (@{ref $args{requested_features} eq 'ARRAY' ?
                                         $args{requested_features} : [ $args{requested_features} ]}) {
                        my $request = model('TestrunDB')->resultset('TestrunRequestedFeature')->new({testrun_id => $testrun_id, feature => $feature});
                        $request->insert();
                }
        }
        return $testrun_id;
}



sub update {
        my ($self, $id, $args) = @_;
        my %args = %{$args};    # copy

        my $testrun = model('TestrunDB')->resultset('Testrun')->find($id);

        $args{owner_id} = $args{owner_id} || Tapper::Model::get_or_create_owner( $args{owner} ) if $args{owner};

        return $testrun->update_content(\%args);
}


sub del {
        my ($self, $id) = @_;
        my $testrun = model('TestrunDB')->resultset('Testrun')->find($id);
        if ($testrun->testrun_scheduling) {
                return "Running testruns can not be deleted. Try freehost or wait till the testrun is finished."
                  if $testrun->testrun_scheduling->status eq 'running';
                if ($testrun->testrun_scheduling->requested_hosts->count) {
                        foreach my $host ($testrun->testrun_scheduling->requested_hosts->all) {
                                $host->delete();
                        }
                }
                if ($testrun->testrun_scheduling->requested_features->count) {
                        foreach my $feat ($testrun->testrun_scheduling->requested_features->all) {
                                $feat->delete();
                        }
                }
        }

        $testrun->delete();
        return 0;
}


sub rerun {
        my ($self, $id, $args) = @_;
        my %args = %{$args || {}}; # copy
        my $testrun = model('TestrunDB')->resultset('Testrun')->find( $id );
        return $testrun->rerun(\%args);
}




1; # End of Tapper::Cmd::Testrun

__END__
=pod

=encoding utf-8

=head1 NAME

Tapper::Cmd::Testrun

=head1 SYNOPSIS

This project offers backend functions for all projects that manipulate
testruns or preconditions in the database. This module handles the testrun part.

    use Tapper::Cmd::Testrun;

    my $bar = Tapper::Cmd::Testrun->new();
    $bar->add($testrun);
    ...

=head1 NAME

Tapper::Cmd::Testrun - Backend functions for manipluation of testruns in the database

=head1 FUNCTIONS

=head2 find_matching_hosts

=head2 create

Create new testruns from one element of a test plan (actually a test
plan instance) that contains all information including requested hosts
and features. If the new testruns belong to a test plan instance the
function expects the id of this instance as second parameter. If the
instance id is empty the function can also be used to create testruns
from a testplan like layout without actually using test plan features,
i.e. without creating a link between the new testruns and a test plan
(instance).

@param hash ref - test plan element
@param instance - test plan instance id

@return array   - testrun ids

=head2 add

Add a new testrun. Owner/owner_id and requested_hosts/requested_host_ids
allow to specify the associated value as id or string which will be converted
to the associated id. If both values are given the id is used and the string
is ignored. The function expects a hash reference with the following options:
-- optional --
* requested_host_ids - array of int
or
* requested_hosts    - array of string

* notes - string
* shortname - string
* topic - string
* date - DateTime
* instance - int

* owner_id - int
or
* owner - string

@param hash ref - options for new testrun

@return success - testrun id)
@return error   - exception

@throws exception without class

=head2 update

Changes values of an existing testrun. The function expects a hash reference with
the following options (at least one should be given):

* hostname  - string
* notes     - string
* shortname - string
* topic     - string
* date      - DateTime
* owner_id - int
or
* owner     - string

@param int      - testrun id
@param hash ref - options for new testrun

@return success - testrun id
@return error   - undef

=head2 del

Delete a testrun with given id. Its named del instead of delete to
prevent confusion with the buildin delete function.

@param int - testrun id

@return success - 0
@return error   - error string

=head2 rerun

Insert a new testrun into the database. All values not given are taken from
the existing testrun given as first argument.

@param int      - id of original testrun
@param hash ref - different values for new testrun

@return success - testrun id
@return error   - exception

@throws exception without class

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

