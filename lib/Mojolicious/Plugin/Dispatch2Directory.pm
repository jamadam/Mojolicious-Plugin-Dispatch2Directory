package Mojolicious::Plugin::Dispatch2Directory;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util 'url_unescape';
use File::Basename 'dirname';
our $VERSION = '0.01';
    
    ### ---
    ### Register
    ### ---
    sub register {
        my ($self, $app, $options) = @_;
        
        $options->{default_file}    ||= 'index.html';
        $options->{static_dir}      ||= 'static';
        $options->{document_root}   ||= $app->home->rel_dir('public_html');
        
        $app->static->paths([$options->{document_root}, _asset()]);
        $app->renderer->paths([$options->{document_root}]);
        
        my $default_route_set;
        my $handler_re;

        ### Auto-fill path
        $app->hook('around_dispatch' => sub {
            my ($next, $c) = @_;
            
            my $path = $c->req->url->path || '/';
            my $trailing_slash = substr($path, -1, 1) eq '/';
            $path =~ s{/$}{/$options->{default_file}};
            $c->req->url->path($path);
            
            ### set default route
            if (! $default_route_set) {
                $handler_re = '(?:'. join('|', keys %{$c->app->renderer->handlers}). ')';
                $c->app->routes->route('(*template).(*format)')->to(cb => sub {
                    my $c = shift;
                    $c->render;
                    $c->res->code || $c->render_not_found;
                });
                $default_route_set = 1;
            }
            
            ### 403 for direct access to template file names
            if ($path =~ qr{\.\w+?\.$handler_re$}) {
                $c->render_exception('Forbidden');
                $c->res->code(403);
                return;
            }
            
            $next->();
            
            if ($options->{indexes} && $trailing_slash && $c->res->code == 404) {
                $c->tx->res(Mojo::Message::Response->new);
                $c->render_text(_indexes($options->{document_root}, dirname($path), $options->{static_dir}));
                $c->res->code(200);
            }
        });
    }
    
    ### ---
    ### Render file list
    ### ---
    sub _indexes {
        my ($root, $path, $static) = @_;
        $path = url_unescape($path);
        utf8::decode($path);
        my $dir = File::Spec->catfile($root, $path);
        
        opendir(my $DIR, $dir);
        my @file = readdir($DIR);
        closedir $DIR;
        
        my @dset = ();
        for my $file (@file) {
            utf8::decode($file);
            $file = url_unescape($file);
            if ($file =~ qr{^\.$} || $file =~ qr{^\.\.$} && $path eq '/') {
                next;
            }
            my $fpath = File::Spec->catfile($dir, $file);
            push(@dset, {
                name        => -f $fpath ? $file : $file. '/',
                timestamp   => _file_timestamp($fpath),
                size        => _file_size($fpath),
                type        => -f $fpath ? _file_to_mime_class($file) : 'dir',
            });
        }
        
        @dset = sort {
            ($a->{type} ne 'dir') <=> ($b->{type} ne 'dir')
            ||
            $a->{name} cmp $b->{name}
        } @dset;
        
        my $mt = Mojo::Template->new;
        return $mt->render_file(_asset('index.html.ep'), $path, \@dset, $static);
    }

    ### ---
    ### Asset directory
    ### ---
    sub _asset {
        my @seed = (dirname(__FILE__), 'Dispatch2Directory', 'Asset');
        if ($_[0]) {
            return File::Spec->catdir(@seed, $_[0]);
        }
        return File::Spec->catdir(@seed);
    }
    
    ### ---
    ### Guess type by file extension
    ### ---
    sub _file_to_mime_class {
        my $name = shift;
        my $ext = ($name =~ qr{\.(\w+)$}) ? $1 : '';
        return (split('/', Mojolicious::Types->type($ext) || 'text/plain'))[0];
    }
    
    ### ---
    ### Get file utime
    ### ---
    sub _file_timestamp {
        my $path = shift;
        my @dt = localtime((stat($path))[9]);
        return sprintf('%d-%02d-%02d %02d:%02d', 1900 + $dt[5], $dt[4] + 1, $dt[3], $dt[2], $dt[1]);
    }
    
    ### ---
    ### Get file size
    ### ---
    sub _file_size {
        my $path = shift;
        return ((stat($path))[7] > 1024)
            ? sprintf("%.1f",(stat($path))[7] / 1024) . 'KB'
            : (stat($path))[7]. 'B';
    }

1;
__END__

=head1 NAME

Mojolicious::Plugin::Dispatch2Directory - Dispatch to directory Hierarchie

=head1 SYNOPSIS

    plugin Dispatch2Directory => {
        document_root => 'public_html',
        indexes => 1,
    };

=head1 DESCRIPTION

This is a plugin for dispatching paths to directory hierarchie and make the
paths to static root and renderer root together. This behavior is similar to
apache with PHP scripts.

=over

=item Template parse

    GET /path/to/file.html

The request above renders following file.

    $app->home->rel_dir('public_html/path/to/file.html.ep')

=back

=over

=item Static file

    GET /path/to/image.png

The request above renders following file.

    $app->home->rel_dir('public_html/path/to/image.png')

=back

Also this plugin provides an ability to serve directory index page like apache's
mod_autoindex.

=head1 OPTIONS

=head2 document_root => String

This option sets root directory for templates and static files. Following
example is default setting.

    plugin Dispatch2Directory => {
        document_root => app->home->rel_dir('public_html')
    };

=head2 default_file => String

This option sets default file name for searching file in directory when
the request path doesn't ended with /. 

    plugin Dispatch2Directory => {
        default_file => 'index.html',
    };

=head2 indexes => Bool

This option emulates apache's indexes option. When the value is 1,
the server generates file list page for directory access. The file list appears
when the default_file resulted 404.

    plugin Dispatch2Directory => {
        indexes => 1,
    };

=head2 static_dir => String

This specifies the static asset path for file list page. Defaults to 'static'.

=head1 METHODS

=head2 $instance->register($app, $options)

This method is internally called.

=head1 SEE ALSO

L<Mojolicious>

L<http://en.wikipedia.org/wiki/Ainu_languages>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
