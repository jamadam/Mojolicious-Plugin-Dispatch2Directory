package Template_Basic;
use strict;
use warnings;
use lib 'lib';
use Test::More;
use Test::Mojo;
use Mojolicious::Lite;

use Test::More tests => 31;

plugin 'Dispatch2Directory' => {document_root => 't/public_html'};

get '/hoge' => sub {
    $_[0]->render_text('hoge');
};

my $t = Test::Mojo->new;
$t->get_ok('/nonexists.html')->status_is(404);
$t->get_ok('/')->status_is(200)->content_like(qr{index.html.ep \d+\n});
$t->get_ok('/index.html.ep')->status_is(403);
$t->get_ok('/index.html')->status_is(200)->content_like(qr{index.html.ep \d+\n});
$t->get_ok('/index.txt')->status_is(200)->content_is(qq{static <%= time() %>});
$t->get_ok('/dir1/')->status_is(200)->content_is(qq{dir1/index.html});
$t->get_ok('/dir1/index.html')->status_is(200)->content_is(qq{dir1/index.html});
$t->get_ok('/dir1/dynamic.html')->status_is(200)->content_like(qr{dir1/dynamic.html \d+\n});
$t->get_ok('/dir1/dynamic.json')->status_is(200)->content_is(qq{{"dynamic":"json"}});
$t->get_ok('/dir1/static.json')->status_is(200)->content_is(qq{{"static":"json"}});
$t->get_ok('/hoge')->status_is(200)->content_is(qq{hoge});

__END__
