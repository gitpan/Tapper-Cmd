package Tapper::Cmd::Testplan;
BEGIN {
  $Tapper::Cmd::Testplan::AUTHORITY = 'cpan:TAPPER';
}
{
  $Tapper::Cmd::Testplan::VERSION = '4.1.8';
}

use 5.010;
use Moose;

use Cwd;
use Try::Tiny;
use YAML::Syck;
use Tapper::Model 'model';
use Tapper::Reports::DPath::TT;

extends 'Tapper::Cmd';



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




sub del {
        my ($self, $id) = @_;
        my $testplan = model('TestrunDB')->resultset('TestplanInstance')->find($id);
        foreach my $testrun ($testplan->testruns->all) {
                if ($testrun->testrun_scheduling->status eq 'running') {
                        my $message = model('TestrunDB')->resultset('Message')->new({testrun_id => $testrun->id,
                                                                                     type       => 'state',
                                                                                     message    => {
                                                                                                    state => 'quit',
                                                                                                    error => 'Testplan cancelled'
                                                                                                   }});
                        $message->insert();
                }
                $testrun->testrun_scheduling->testrun->testplan_id(undef);
                $testrun->testrun_scheduling->testrun->update;
                $testrun->testrun_scheduling->status('finished');
                $testrun->testrun_scheduling->update;
        }
        $testplan->delete();
        return 0;
}


sub rerun
{
        my ($self, $id) = @_;

        my $testplan = model('TestrunDB')->resultset('TestplanInstance')->find($id);
        die "No testplan with ID $id\n" unless $testplan;

        return $self->add($testplan->evaluated_testplan, $testplan->path, $testplan->name);
}


sub parse_path
{
        my ($self, $filename) = @_;
        $filename = Cwd::abs_path($filename);
        my $basedir = Tapper::Config->subconfig->{paths}{testplan_path};
        # splitting filename at basedir returns an array with the empty
        # string before and the path after the basedir
        my $path = (split $basedir, $filename)[1];
        return $path;
}


sub get_shortname{
        my ($self, $plan, $name) = @_;
        return $name if $name;

        foreach my $line (split "\n", $plan) {
                if ($line =~/^###\s*(?:short)?name\s*:\s*(.+)$/i) {
                        return $1;
                }
        }
        return;
}


sub testplannew {
        my ($self, $opt) = @_;

        use File::Slurp 'slurp';

        my $file = $opt->{file};

        my $plan = slurp($file);
        $plan = $self->apply_macro($plan,
                                   {
                                    HOME => $ENV{HOME},
                                    %{$opt->{D} || {}},
                                   },
                                   $opt->{include});

        if ($opt->{guide}) {
                my $guide = $plan;
                my @guide = grep { m/^###/ } split (qr/\n/, $plan);
                say "Self-documentation:";
                say map { my $l = $_; $l =~ s/^###/ /; "$l\n" } @guide;
                return 0;
        }

        my $cmd = Tapper::Cmd::Testplan->new;
        my $path = $opt->{path} || $self->parse_path($opt->{file});
        my $shortname = $self->get_shortname($plan, $opt->{name});

        if ($opt->{dryrun}) {
                say $plan;
                return 0;
        }

        my $plan_id = $cmd->add($plan, $path, $shortname);
        die "Plan not created" unless defined $plan_id;

        if ($opt->{verbose}) {
                my $url = Tapper::Config->subconfig->{base_url} || 'http://tapper/tapper';
                say "Plan created";
                say "  id:   $plan_id";
                say "  url:  $url/testplan/id/$plan_id";
                say "  path: $path";
                say "  file: ".$opt->{file};
        } else {
                say $plan_id;
        }
        return 0;
}


sub apply_macro
{
        my ($self, $macro, $substitutes, $includes) = @_;

        my @include_paths = (Tapper::Config->subconfig->{paths}{testplan_path});
        push @include_paths, @{$includes || [] };
        my $include_path_list = join ":", @include_paths;

        my $tt = Tapper::Reports::DPath::TT->new(include_path => $include_path_list,
                                                 substitutes  => $substitutes,
                                                );
        return $tt->render_template($macro);
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

=head2 del

Delete testrun with given id from database. Please not that this does
not remove the associated testruns.

@param int - testplan instance id

@return success - 0
@return error - exception

@throws die()

=head2 rerun

Reapply the evaluated testplan of the given testplan instance.

@param int - testplan instance id

@return success - new testplan id
@return error   - exception

@throws die()

=head2 parse_path

Get the test plan path from the filename. This is a little more tricky
since we do not simply want the dirname but kind of an "un-prefix".

@param string - file name

@return string - test plan path

=head2 get_shortname

Get the shortname for this testplan. The shortname is either given as
command line option or inside the plan text.

@param string - plan text
@param string - value of $opt->{name}

@return string - shortname

=head2 testplannew

Create a testplan instance from a file.

=head2 apply_macro

Process macros and substitute using Template::Toolkit.

@param string  - contains macros
@param hashref - containing substitutions
@optparam string - path to more include files

@return success - text with applied macros
@return error   - die with error string

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
