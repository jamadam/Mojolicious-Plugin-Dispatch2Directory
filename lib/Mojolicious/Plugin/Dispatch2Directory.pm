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
        $options->{handler}         ||= 'ep';
        
        $app->static->paths([$options->{document_root}]);
        $app->renderer->paths([$options->{document_root}]);
        
        my $default_route_set;
        my $handler_re;

        $app->hook('around_dispatch' => sub {
            my ($next, $c) = @_;
            
            ### Auto-fill path
            my $path = $c->req->url->path;
            my $path_org = $path->clone;
            if ($path->trailing_slash || ! @{$path->parts}) {
                push(@{$path->parts}, $options->{default_file});
                $path->trailing_slash(0);
            }
            
            ### set default route
            if (! $default_route_set) {
                $handler_re =
                    '(?:'. join('|', keys %{$c->app->renderer->handlers}). ')';
                $c->app->routes->route('(*template).(*format)')->to(cb => sub {
                    my $c = shift;
                    $c->render(handler => $options->{handler});
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
            
            my $code = $c->res->code;
            
            if ($code && $code == 404 && $path_org !~ qr{/$}
                && -d File::Spec->catfile($options->{document_root}, $path_org)) {
                $c->tx->res(Mojo::Message::Response->new);
                $c->redirect_to($path. '/');
                $c->tx->res->code(301);
            }
        });
    }

1;
__END__

=head1 NAME

Mojolicious::Plugin::Dispatch2Directory - Dispatch to directory Hierarchie

=head1 SYNOPSIS

    plugin Dispatch2Directory => {
        document_root   => 'public_html',
        handler         => 'ep',
    };

=head1 DESCRIPTION

This is a plugin for dispatching paths to directory hierarchie.

Given document_root path would be assigned to both static and renderer roots
and the dispatcher decides how to handle paths by file extensions.

With this plugin, you can enhance static pages in directory hierarchie
by adding extra extension such as .html.ep and can embed dynamic contents
into them as if PHPers do or SSI fans do.

=over

=item Template parse

    GET /path/to/file.html

The request above results the following file to render.

    $app->home->rel_dir('public_html/path/to/file.html.ep')

=back

=over

=item Static file

    GET /path/to/image.png

The request above results the following file to serve.

    $app->home->rel_dir('public_html/path/to/image.png')

=back

=head1 OPTIONS

=head2 document_root => String

This option sets root directory for templates and static files. Following
example is default setting.

    plugin Dispatch2Directory => {
        document_root => app->home->rel_dir('public_html')
    };

=head2 handler => String

This option overrides auto detection.

    plugin Dispatch2Directory => {
        handler => 'ep'
    };

=head2 default_file => String

This option sets default file name for searching file in directory when
the request path doesn't ended with /. 

    plugin Dispatch2Directory => {
        default_file => 'index.html',
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
