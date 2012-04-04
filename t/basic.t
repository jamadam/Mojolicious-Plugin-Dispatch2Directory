package Template_Basic;
use strict;
use warnings;
use lib 'lib';
use Test::More;
use Test::Mojo;
use Mojolicious::Lite;

use Test::More tests => 48;

plugin 'Dispatch2Directory' => {document_root => 't/public_html'};

get '/hoge' => sub {
    $_[0]->render_text('hoge');
};

my $t = Test::Mojo->new;
$t->get_ok('/dir1')
    ->status_is(301)
    ->header_like(Location => qr{/dir1/$});
$t->get_ok('/nonexists.html')
    ->status_is(404);
$t->get_ok('/')
    ->status_is(200)
    ->content_type_is('text/html;charset=UTF-8')
    ->content_like(qr{index.html.ep \d+\n});
$t->get_ok('/index.html.ep')
    ->content_type_is('text/html;charset=UTF-8')
    ->status_is(403);
$t->get_ok('/index.html')
    ->content_type_is('text/html;charset=UTF-8')
    ->status_is(200)
    ->content_like(qr{index.html.ep \d+\n});
$t->get_ok('/index.txt')
    ->content_type_is('text/plain')
    ->status_is(200)
    ->content_is(qq{static <%= time() %>});
$t->get_ok('/dir1/')
    ->content_type_is('text/html;charset=UTF-8')
    ->status_is(200)
    ->content_is(qq{dir1/index.html});
$t->get_ok('/dir1/index.html')
    ->content_type_is('text/html;charset=UTF-8')
    ->status_is(200)
    ->content_is(qq{dir1/index.html});
$t->get_ok('/dir1/dynamic.html')
    ->content_type_is('text/html;charset=UTF-8')
    ->status_is(200)
    ->content_like(qr{dir1/dynamic.html \d+\n});
$t->get_ok('/dir1/dynamic.json')
    ->content_type_is('application/json')
    ->status_is(200)
    ->content_is(qq{{"dynamic":"json"}});
$t->get_ok('/dir1/static.json')
    ->content_type_is('application/json')
    ->status_is(200)
    ->content_is(qq{{"static":"json"}});
$t->get_ok('/hoge')
    ->content_type_is('text/html;charset=UTF-8')
    ->status_is(200)
    ->content_is(qq{hoge});
$t->get_ok('/dynamic.txt')
    ->content_type_is('text/plain')
    ->status_is(200)
    ->content_like(qr{dynamic \d+\n});

__END__
