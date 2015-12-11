#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(sleep time);
use Plack::Request;
use Plack::Response;
use JSON;
use YAML;

sub build_response {
    my ($res_data) = @_;
    my $res = Plack::Response->new(200);
    if ($res_data->{format}) {
        if ($res_data->{format} eq 'json') {
            $res->content_type("application/json");
            $res->body("". JSON->new->utf8->encode($res_data));
        }
        elsif ($res_data->{format} =~ /\A ya?ml \z/x) {
            $res->content_type("text/yaml");
            $res->body("". JSON->new->utf8->encode($res_data));
        }
    } else {
        $res->content_type("text-html");
        my $res_body = "<html><head><meta charset=\"utf8\"></head><body>"
        . join( "<br>\n",
                (map { ($_, $res_data->{$_} //"") } sort keys %$res_data)
           ) ."</body></html>";
        $res->body($res_body);
    }
    return $res->finalize;
}

sub {
    my $env = shift;
    my $start_time = time;
    my $req = Plack::Request->new($env);
    my $res_data = {};

    if (my $t = $req->query_parameters->{'it-takes-time'}) {
        if ($t =~ /\A( [1-9][0-9]* | [0-9]\.[0-9]+ )\z/x) {
            sleep $t;
            $res_data->{start_time} = $start_time;
            $res_data->{end_time}   = time;
        }
    }
    ($res_data->{format}) = $req->path_info =~ m/\.(json|ya?ml)\z/i and $res_data->{format} = lc($res_data->{format});

    return build_response($res_data);
}

__END__
curl 'http://localhost:5000/path/to/whatever/?it-takes-time=2.5'
