package Net::DAAP::Client::Auth::Protocol;
use strict;
use warnings;
use Carp;
use HTTP::Request::Common;
use base qw( Net::DAAP::Client );

# XXX - this is less subclassing as a huge copy-and-paste job, taking
# the original ~50 line long _do_get from Net::DAAP::Client and adding
# a call out to HTTP::Request::Common::GET to add in extra headers

sub _do_get {
    my ($self, $req, $file) = @_;
    my $server_url = sprintf("http://%s:%d",
                             $self->{SERVER_HOST},
                             $self->{SERVER_PORT});

    if (!defined wantarray) { carp "_do_get's result is being ignored" }

    my $id = $self->{ID};
    my $revision = $self->{REVISION};
    my $ua = $self->{UA};

    my $url = "$server_url/$req";
    my $res;

    # append session-id and revision-number query args automatically
    if ($self->{ID}) {
        if ($req =~ m{ \? }x) {
            $url .= "&";
        } else {
            $url .= "?";
        }
        $url .= "session-id=$id";
    }

    if ($revision && $req ne 'logout') {
        $url .= "&revision-number=$revision";
    }

    # fetch into memory or save to disk as needed
    $self->_debug($url);

    my $path = $url;
    $path =~ s{http://.*?/}{/};

    # form the request ourself so we have magic headers.
    my $reqid = $self->{REQUEST_ID};
    my $request = HTTP::Request::Common::GET(
        $url,
        "Client-DAAP-Version"      => '3.0',
        "Client-DAAP-Access-Index" => 2,
        $reqid ? ( "Client-DAAP-Request-ID" => $reqid ) : (),
        "Client-DAAP-Validation"   => $self->_md5_thingy( $path, 2, $reqid ),
       );

    #print ">>>>\n", $request->as_string, ">>>>>\n";
    if ($file) {
        $res = $ua->request($request, $file);
    } else {
        $res = $ua->request($request);
    }
    #print "<<<<\n", $res->headers->as_string, "<<<<\n";

    # complain if the server sent back the wrong response
    if (! $res->is_success) {
        $self->error("$url\n".$res->as_string);
        return;
    }

    my $content_type = $res->header("Content-Type");
    if ($req ne 'logout' && $content_type !~ /dmap/) {
        $self->error("Broken response (content type $content_type) on $url");
        return;
    }

    if ($file) {
        return $res;           # return obj to avoid copying huge string
    } else {
        return $res->content;
    }
}

1;
