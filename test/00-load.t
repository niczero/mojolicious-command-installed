use Mojo::Base -strict;
use Test::More;

use_ok 'Mojolicious::Command::installed';
diag 'Testing Mojolicious::Command::installed'
    ." $Mojolicious::Command::installed::VERSION, Perl $], $^X";

done_testing();
