package Mojolicious::Command::installed;
use Mojolicious::Commands -base;

our $VERSION = 0.001;

use File::Spec::Functions 'catfile';
use Getopt::Long qw(GetOptionsFromArray :config no_auto_abbrev no_ignore_case);
use open ':locale';

sub run {
  my ($self, @args) = @_;
  GetOptionsFromArray \@args,
    'all-paths' => \(my $all_paths),
    'show-paths' => \(my $show_paths),
    'show-versions' => \(my $show_versions);

  my (%paths, %versions, @modules);
  for my $path (@INC) {
    my $file = catfile $path, 'perllocal.pod';
    if (($all_paths or $path !~ m{^/}) and -f $file) {
      die "$file is unreadable" unless -r $file;
      open my $fh, '<', $file;
      local $_;
      while (defined($_ = <$fh>)) {
        next unless /^=head2 /;
        warn "Failed to parse ($_)" and next unless /C<Module> L<([^\|]+)\|/;

        my $module = $1;
        next if $paths{$module};  # already seen

        my $version;
        eval "require $module; 1" and $version = $module->VERSION
          if $show_versions;
        $paths{$module} = $path;
        $versions{$module} = $version;
        push @modules, $module;
      }
      close $fh;
    }
  }
  for my $module (@modules) {
    my $line = $module;
    $line .= '@'. $versions{$module}
      if $show_versions and defined $versions{$module};
    $line .= '	# '. $paths{$module} if $show_paths;
    say $line;
  }
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
application's C<@INC> module path and lists in order each package recorded in
perllocal.pod.

=head1 CAVEATS

Some packages thwart perllocal.pod by structuring their call to WriteMakefile in
a difficult-to-parse way (eg
L<https://metacpan.org/source/MIKO/String-Util-1.24/Makefile.PL>) and so will
not be picked up by this command.
