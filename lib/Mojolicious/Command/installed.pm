package Mojolicious::Command::installed;
use Mojolicious::Commands -base;

our $VERSION = 0.021;

use Cwd 'abs_path';
use File::Find;
use File::Spec::Functions 'catfile';
use Getopt::Long qw(GetOptionsFromArray :config no_auto_abbrev no_ignore_case);
use Mojo::Util 'dumper';
use Mojolicious::Plugin::JSONConfig;
use open ':locale';

sub run {
  my ($self, @args) = @_;
  GetOptionsFromArray \@args,
    'all-paths' => \(my $all_paths),
    'show-paths' => \(my $show_paths),
    'show-versions' => \(my $show_versions);

  my %meta;
  for my $prefix (@INC) {
    next if $prefix =~ m{^/} and not $all_paths;

    # Parse perllocal.pod
    my $file = catfile $prefix, 'perllocal.pod';
    if (-f $file) {
      die "$file is unreadable" unless -r $file;
      open my $fh, '<', $file;
      local $_;
      while (defined($_ = <$fh>)) {
        next unless /^=head2 /;
        warn "Failed to parse ($_)" and next unless /C<Module> L<([^\|]+)\|/;
        my ($module, $filename) = ($1, $self->_file_for($1));
        next if $meta{$module};

        eval "require $module; 1" or next;
        my $version = $module->VERSION;

        $meta{$module} = {
          name => $module,
          path => $INC{$filename}
        };
        $meta{$module}{version} = $version if defined $version;
      }
      close $fh;
    }

    # Parse .meta/*/*.json
    my %configs;  # files to be read
    find({no_chdir => 1, wanted => sub {
      return unless m{\.meta/[^/]+/[^/]+\.json$};
      $configs{abs_path $_} ||= $_;
    }}, $prefix);
    for (keys %configs) {
      # Slurp json
      local $/ = undef;
      open my $fh, '<', $_ or die $!;
      my $content = <$fh>;
      close $fh;

      # Parse json
      my $parsed = Mojolicious::Plugin::JSONConfig->parse(
          $content, $_, undef, $self->app);
      ($parsed->{name} //= '') =~ s/-/::/g;
      if (my $name = $parsed->{name}) {
        $meta{$name} = { %{$parsed // {}}, %{$meta{$name} // {}} };  # merge
        unless ($meta{$name}{path}) {
          # Do not yet know where it resides
          eval "require $name; 1" or next;
          my $version = $name->VERSION;
          $meta{$name}{version} //= $version if defined $version;
          $meta{$name}{path} = $INC{$self->_file_for($name)};
        }
      }
      else {
        die sprintf 'Bizarre json (%s)', Mojo::Util::dumper($parsed);
      }
    }
  }

  # Output
  my $out = '';
  for my $module (sort keys %meta) {
    my $entry = $meta{$module};
    my $line = $entry->{name};
    $line .= '@'. $entry->{version}
      if $show_versions and defined $entry->{version};
    $line .= '	# '. $entry->{path} if $show_paths;
    $out .= $line ."\n";
  }
  print($out) unless $self->quiet;
  return $out;
}

sub _file_for {
  my ($self, $module) = @_;
  return unless $module;
  my $file = catfile split /::/, $module;
  $file .= '.pm' unless $module =~ /\./;
  return $file;
}

1;
__END__

=head1 NAME

Mojolicious::Command::installed - List locally installed packages.

=head1 SYNOPSIS

  Usage: APPLICATION installed [OPTIONS]

  Options:
    -h, --help       Show this summary of available options
    --all-paths      Walk all paths, including absolute paths
    --show-paths     Show module base paths
    --show-versions  Show module versions

=head1 DESCRIPTION

L<Mojolicious::Command::installed> walks the list of relative paths in the
application's C<@INC> module path, listing all the packages installed there.
Optionally it can walk all paths, including absolute paths, it can show the path
where each module was first found, and it can show the version of the module
found.

This is only focused on version management, so considers only the main module
within each package.

=head1 CAVEATS

Some packages thwart perllocal.pod by structuring their call to WriteMakefile in
a difficult-to-parse way (eg
L<https://metacpan.org/source/MIKO/String-Util-1.24/Makefile.PL>).  This should
not matter as long as they deposit at least one JSON installation file under
.meta.

The output will only prove useful if you invoke it using the same C<PERL5LIB> as
that used by your code so that the resulting C<@INC> is the same.

The output is in dictionary order; listing them in dependency order is beyond my
current time limits.

=head1 RATIONALE

Managing installations via App::cpanminus is wonderful -- it makes the important
task of managing per-project dependencies a breeze.  But as far as I can tell
there is no easy means to list what is currently installed.  Anyway, for an app,
you want the app to tell you, so that it uses any configured path setup.

I periodically replace and rebuild each project's dependencies dir by piping
this command into cpanm.  The C<--show-versions> option is intended to make
creation of 'cpanfile' easier, and the C<--show-paths> option is intended to
make some debugging puzzles easier.

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2015 Nic Sandfield.  All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.
