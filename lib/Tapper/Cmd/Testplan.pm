package Tapper::Cmd::Testplan;

use Moose;
use Tapper::Model 'model';
use YAML::Syck;
use 5.010;

use parent 'Tapper::Cmd';

=head1 NAME

Tapper::Cmd::Testplan - Backend functions for manipluation of testplan instances in the database

=head1 SYNOPSIS

This project offers functions to add, delete or update testplan
instances in the database.

    use Tapper::Cmd::Testplan;

    my $cmd = Tapper::Cmd::Testplan->new();
    my $plan_id = $cmd->add($plan);
    $cmd->update($plan_id, $new_plan);
    $cmd->del($plan_id);

    ...

=head1 FUNCTIONS

=cut

=head2 get_module_for_type

Get the name of the Tapper::Cmd module that is reponsible for a given
type. The name of the module is optimized for the Tapper developer but
the type given in the testplan should be telling for the testplan user.

@param string - type

@return string - name of the responsible module

=cut

sub get_module_for_type
{
        my ($self, $type) = @_;
         given (lc($type)){
                when('multitest') { return "Tapper::Cmd::Testrun"; }
                default           { $type = ucfirst($type); return "Tapper::Cmd::$type"; }
        }
}


=head2 add

Add a new testplan instance to database and create the associated
testruns. The function expects a string containing the evaluated test
plan content and a path.

@param    string - plan content
@param    string - path
@optparam string - name

@return int - testplan instance id

=cut

sub add {
        my ($self, $plan_content, $path, $name) = @_;

        my $instance = model('TestrunDB')->resultset('TestplanInstance')->new({evaluated_testplan => $plan_content, 
                                                                               path => $path, 
                                                                               name => $name,
                                                                              });
        $instance->insert;

        my @testrun_ids;

        my @plans = YAML::Syck::Load($plan_content);
        foreach my $plan (@plans) {
                my $module = $self->get_module_for_type($plan->{type});
                eval "use $module";
                my $handler = "$module"->new();
                my @new_ids = $handler->create($plan->{description}, $instance->id);
                push @testrun_ids, @new_ids;
        }
        return $instance->id;
}


=head2 update


=cut

sub update {
        my ($self, $id, $args) = @_;
}

=head2 del


=cut

sub del {
        my ($self, $id) = @_;
        my $testplan = model('TestrunDB')->resultset('TestplanInstance')->find($id);
        $testplan->delete();
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

1; # End of Tapper::Cmd::Testplan
