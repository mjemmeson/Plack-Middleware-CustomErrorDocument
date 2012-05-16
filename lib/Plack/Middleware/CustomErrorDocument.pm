package Plack::Middleware::CustomErrorDocument;
use strict;
use warnings;
use parent qw(Plack::Middleware);
use Plack::MIME;
use Plack::Util;
use Plack::Util::Accessor qw( subrequest );

use HTTP::Status qw(is_error);

sub call {
    my $self = shift;
    my $env  = shift;

    my $r = $self->app->($env);

    $self->response_cb(
        $r,
        sub {
            my $r = shift;
            unless ( is_error( $r->[0] ) && exists $self->{ $r->[0] } ) {
                return;
            }

            my $path = $self->{ $r->[0] }->($env);

            my $h = Plack::Util::headers( $r->[1] );
            $h->remove('Content-Length');

            $h->set( 'Content-Type', Plack::MIME->mime_type($path) );    #

            open my $fh, "<", $path or die "$path: $!";
            if ( $r->[2] ) {
                $r->[2] = $fh;
            } else {
                my $done;
                return sub {
                    unless ($done) {
                        return join '', <$fh>;
                    }
                    $done = 1;
                    return defined $_[0] ? '' : undef;
                };
            }
        }
    );
}

1;
