#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(sleep time);
use Plack::Request;

sub {
    my $env = shift;
    my $start_time = time;
    my $req = Plack::Request->new($env);

    if (my $t = $req->query_parameters->{'it-takes-time'}) {
        if ($t =~ /\A( [1-9][0-9]* | [0-9]\.[0-9]+ )\z/x) {
            sleep $t;
        }
    }
    return [200, [], [$start_time, ",", time]];
}

__END__
curl 'http://localhost:5000/path/to/whatever/?it-takes-time=2.5'
