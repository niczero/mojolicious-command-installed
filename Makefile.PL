use 5.010_001;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Command::installed',
  VERSION_FROM => 'lib/Mojolicious/Command/installed.pm',
  ABSTRACT     => 'List locally installed packages',
  AUTHOR       => 'Nic Sandfield <niczero@cpan.org>',
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    no_index  => {directory => [qw(test)]},
    requires  => {perl => 5.010001},
    resources => {
      homepage   => 'http://niczero.github.io/mojar',
      license    => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository => 'http://github.com/niczero/mojolicious-command-installed',
      bugtracker =>
          'http://github.com/niczero/mojolicious-command-installed/issues'
    }
  },
  BUILD_REQUIRES => {'Test::More' => 0},
  CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => 6.3},
  PREREQ_PM => {Mojolicious => 5},
  EXE_FILES => [],
  test => {TESTS => 'test/*.t'}
);
