package Tapper::Cmd::Init;
BEGIN {
  $Tapper::Cmd::Init::AUTHORITY = 'cpan:TAPPER';
}
{
  $Tapper::Cmd::Init::VERSION = '4.1.3';
}
# ABSTRACT: Tapper - Backend functions for initially setting up Tapper

use 5.010;
use strict;
use warnings;

use Moose;
use Tapper::Cmd::DbDeploy;
use Tapper::Config;
use Tapper::Model 'model';
use File::ShareDir 'module_file', 'module_dir';
use File::Copy::Recursive 'dircopy';
use File::Slurp 'slurp';
use DBI;

extends 'Tapper::Cmd';



sub mint_file {
        my ($init_dir, $basename) = @_;

        my $HOME = $ENV{HOME};
        my $USER = $ENV{USER} || 'nobody';

        my $file = "$init_dir/$basename";
        if (-e $file) {
                say "SKIP    $file - already exists";
        } else {
                my $content = slurp module_file('Tapper::Cmd::Init', $basename);
                $content =~ s/__HOME__/$HOME/g;
                $content =~ s/__USER__/$USER/g;
                open my $INITCFG, ">", $file or die "Can not create file $file.\n";
                print $INITCFG $content;
                close $INITCFG;
                say "CREATED $file";
        }
}


sub copy_subdir {
        my ($init_dir, $dirname) = @_;

        my $dir = "$init_dir/$dirname";
        if (-d $dir) {
                say "SKIP    $dir/ - already exists";
        } else {
                dircopy(module_dir('Tapper::Cmd::Init')."/$dirname", $dir);
                say "CREATED $dir";
        }
}


sub make_subdir {
        my ($dir) = @_;
        if (-d $dir) {
                say "SKIP    $dir - already exists";
        } else {
                mkdir $dir or die "Can not create $dir\n";
                say "CREATED $dir/";
        }
}


sub dbdeploy
{
        Tapper::Config::_switch_context; # reload config

        foreach my $db (qw(TestrunDB ReportsDB)) {
                my $dsn = Tapper::Config->subconfig->{database}{$db}{dsn};
                my ($scheme, $driver, $attr_string, $attr_hash, $driver_dsn) = DBI->parse_dsn($dsn)
                 or die "Can't parse DBI DSN '$dsn'";
                if ($driver eq "SQLite") {
                        my ($dbname) = $driver_dsn =~ /dbname=(.*)/;
                        if (! -e $dbname) {
                                my $cmd = Tapper::Cmd::DbDeploy->new;
                                $cmd->dbdeploy($db);
                        } else {
                                say "SKIP    $dbname - already exists";
                        }
                }
        }
}


sub init
{
        my ($self, $options) = @_;
        my $db = $options->{db};

        my $HOME = $ENV{HOME};
        die "No home directory found.\n" unless $HOME && -d $HOME;

        make_subdir my $init_dir     = "$HOME/.tapper";
        make_subdir my $run_dir      = "$HOME/.tapper/run";
        make_subdir my $log_dir      = "$HOME/.tapper/logs";
        make_subdir my $out_dir      = "$HOME/.tapper/output";
        make_subdir my $repo_dir     = "$HOME/.tapper/repository";
        make_subdir my $img_dir      = "$HOME/.tapper/repository/images";
        make_subdir my $pkg_dir      = "$HOME/.tapper/repository/packages";
        make_subdir my $prg_dir      = "$HOME/.tapper/testprogram";
        make_subdir my $testplan_dir = "$HOME/.tapper/testplans";
        make_subdir my $localdata_dir = "$HOME/.tapper/localdata";
        copy_subdir ($init_dir, "hello-world");
        copy_subdir ($init_dir, "testplans/topic");
        copy_subdir ($init_dir, "testplans/include");
        mint_file ($init_dir, "tapper.cfg");
        mint_file ($init_dir, "log4perl.cfg");
        mint_file ($init_dir, "tapper-mcp-messagereceiver.conf");

        dbdeploy;
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Tapper::Cmd::Init - Tapper - Backend functions for initially setting up Tapper

=head1 SYNOPSIS

This module provides functions to initially set up Tapper in C<$HOME/.tapper/>.

    use Tapper::Cmd::Init;
    my $cmd = Tapper::Cmd::Init->new;
    $cmd->init($options);
    ...

=head1 METHODS

=head2 mint_file ($init_dir, $basename)

Create file taken from sharedir into user's ~/.tapper/,
inclusive rewriting values dedicated for the user.

=head2 copy_subdir ($init_dir, $dirname)

Create subdir taken from sharedir into user's ~/.tapper/.

=head2 make_subdir($dir)

Create a subdirectory with some log output.

=head2 dbdeploy

Initialize databases in $HOME/.tapper/

=head2 init($defaults)

Initialize $HOME/.tapper/

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

