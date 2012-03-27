package Template_Basic;
use strict;
use warnings;
use lib 'lib';
use Test::More;
use Test::Mojo;
use utf8;
use Encode;
use Encode::Guess;

    my $backup = $ENV{MOJO_MODE} || '';
    
	use Test::More tests => 25;
	
    {
        $ENV{MOJO_MODE} = 'production';
        my $t = Test::Mojo->new('TestCase1');
        $t->get_ok('/')
			->status_is(200)
			->content_like(qr{<title>Index of /</title>})
			->content_like(qr{4B})
			->content_like(qr{1.6KB})
			->content_unlike(qr{<a class="dir" href="./">})
			->content_like(qr{<a class="dir" href="some_dir/">some_dir/</a>})
			->content_like(qr{\d\d\d\d-\d\d-\d\d \d\d:\d\d})
			->content_like(qr{日本語})
			->content_like(qr{<a class="image" href="image.png">image.png</a>});
		$t->get_ok('/some_dir/')
			->status_is(200)
			->content_like(qr{<a class="dir" href="../">../</a>})
			->content_like(qr{test.html});
        $t->get_ok('/some_dir2/')
			->status_is(200)
			->content_is(q{index file exists});
        $t->get_ok('/some_dir3/file_list.css')
			->status_is(200)
			->content_is(q{file_list.css});
        $t->get_ok('/static/file_list.css')
			->status_is(200)
			->content_like(qr{\@charset "UTF\-8"});
		$t->get_ok('/some_dir/not_exists.html')
			->status_is(404);
    }
		{
			package TestCase1;
			use strict;
			use warnings;
			use base 'Mojolicious';
			
			sub startup {
				my $self = shift;
				$self->plugin(Dispatch2Directory => {
					document_root => 't/public_html_index',
					indexes => 1,
				});
			}
		}
	
	$ENV{MOJO_MODE} = $backup;

__END__
