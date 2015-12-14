#!/usr/bin/env perl
use v5.14;
use strict;
use warnings;
use Time::HiRes qw(sleep time);
use Plack::Request;
use Plack::Response;
use JSON;
use YAML;

sub build_response {
    state $JSON = JSON->new->utf8->allow_blessed->allow_unknown;

    my ($res_data) = @_;
    my $res = Plack::Response->new(200);
    if ($res_data->{format}) {
        if ($res_data->{format} eq 'json') {
            $res->content_type("application/json");
            $res->body("". $JSON->encode($res_data->{body}));
        }
        elsif ($res_data->{format} =~ /\A ya?ml \z/x) {
            $res->content_type("text/yaml");
            $res->body("". YAML::Dump($res_data->{body}));
        }
    } else {
        $res->content_type("text-html");
        my $res_body = "<html><head><meta charset=\"utf8\"></head><body>"
        . join( "<br>\n",
                (map { ($_, $res_data->{$_} //"") } sort keys %{$res_data->{body}})
           ) ."</body></html>";
        $res->body($res_body);
    }
    return $res->finalize;
}

sub dispatch_and_fleshen_res_data {
    my ($tx) = @_;

    state $action = {
        "/dumpenv" => sub {
            my ($tx) = @_;
            $tx->{res_data}{body}{env} = $tx->{env};
        }
    };

    if (my $act = $action->{$tx->{res_data}{path}}) {
        $act->($tx);
    }
}

sub {
    my $env = shift;
    my $start_time = time;
    my $req = Plack::Request->new($env);
    my $res_data = { header => {}, body => {}, format => undef };

    my ($path, $format) = split(qr{[.?]}, $req->path_info);

    if (defined($format)) {
        $format = lc($format);
    }
    $res_data->{format} = $format;
    $res_data->{path}   = $path;

    dispatch_and_fleshen_res_data({ res_data => $res_data, req => $req, env => $env });

    if (my $t = $req->query_parameters->{'it-takes-time'}) {
        if ($t =~ /\A( [1-9][0-9]* | [0-9]\.[0-9]+ )\z/x) {
            sleep $t;
            $res_data->{body}{start_time} = $start_time;
            $res_data->{body}{end_time}   = time;
        }
    }

    return build_response($res_data);
}

__END__
curl 'http://localhost:5000/path/to/whatever/?it-takes-time=2.5'
