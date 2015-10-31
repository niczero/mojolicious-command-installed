use Mojo::Base -strict;
use Test::More;

use Mojolicious::Command::installed;

my $cmd = Mojolicious::Command::installed->new(quiet => 1);
my $out = $cmd->run(qw(--all-paths));
ok $out, 'got something';
like $out, qr/^Mojolicious$/m, 'found package';

$out = $cmd->run(qw(--all-paths --show-versions));
like $out, qr/^Mojolicious\@[\d\.]+$/m, 'found version';

$out = $cmd->run(qw(--all-paths --show-paths));
like $out, qr/^Mojolicious\t# \S+?\/Mojolicious.pm$/m, 'found path';

$out = $cmd->run(qw(--all-paths --show-versions --show-paths));
like $out, qr/^Mojolicious\@[\d\.]+\t# \S+?\/Mojolicious.pm$/m, 'found both';

done_testing();
