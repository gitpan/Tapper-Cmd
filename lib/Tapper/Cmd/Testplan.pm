package Tapper::Cmd::Testplan;
BEGIN {
  $Tapper::Cmd::Testplan::AUTHORITY = 'cpan:AMD';
}
{
  $Tapper::Cmd::Testplan::VERSION = '4.0.1';
}

use Moose;
use Tapper::Model 'model';
use YAML::Syck;
use 5.010;
use Try::Tiny;

use parent 'Tapper::Cmd';



sub get_module_for_type
{
        my ($self, $type) = @_;
         given (lc($type)){
                when('multitest') { return "Tapper::Cmd::Testrun"; }
                default           { $type = ucfirst($type); return "Tapper::Cmd::$type"; }
        }
}



sub add {
        my ($self, $plan_content, $path, $name) = @_;

        my @plans = YAML::Syck::Load($plan_content);
        # use Data::Dumper;
        # print STDERR "plans: ".Dumper($plan_content);
        # print STDERR "plans: ".Dumper(\@plans);

        my $instance = model('TestrunDB')->resultset('TestplanInstance')->new({evaluated_testplan => $plan_content,
                                                                               path => $path,
                                                                               name => $name,
                                                                              });
        $instance->insert;

        my @testrun_ids;
        foreach my $plan (@plans) {
                die "Missing plan type for the following testplan: \n".Dump($plan) unless $plan->{type};
                my $module = $self->get_module_for_type($plan->{type});

                try {
                        eval "use $module";
                } catch {
                        die "Can not load '$module' to handle testplan of type $plan->{type}: $!";
                };

                my $handler = "$module"->new();
                my @new_ids = $handler->create($plan->{description}, $instance->id);
                push @testrun_ids, @new_ids;
        }
        return $instance->id;
}



sub update {
        my ($self, $id, $args) = @_;
}


sub del {
        my ($self, $id) = @_;
        my $testplan = model('TestrunDB')->resultset('TestplanInstance')->find($id);
        $testplan->delete();
        return 0;
}

1; # End of Tapper::Cmd::Testplan

__END__
=pod

=encoding utf-8

=head1 NAME

Tapper::Cmd::Testplan

=head1 SYNOPSIS

This project offers functions to add, delete or update testplan
instances in the database.

    use Tapper::Cmd::Testplan;

    my $cmd = Tapper::Cmd::Testplan->new();
    my $plan_id = $cmd->add($plan);
    $cmd->update($plan_id, $new_plan);
    $cmd->del($plan_id);

    ...

=head1 NAME

Tapper::Cmd::Testplan - Backend functions for manipluation of testplan instances in the database

=head1 FUNCTIONS

=head2 get_module_for_type

Get the name of the Tapper::Cmd module that is reponsible for a given
type. The name of the module is optimized for the Tapper developer but
the type given in the testplan should be telling for the testplan user.

@param string - type

@return string - name of the responsible module

=head2 add

Add a new testplan instance to database and create the associated
testruns. The function expects a string containing the evaluated test
plan content and a path.

@param    string - plan content
@param    string - path
@optparam string - name

@return int - testplan instance id

@throws die()

=head2 update

=head2 del

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

