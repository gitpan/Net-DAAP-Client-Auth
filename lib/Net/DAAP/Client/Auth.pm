package Net::DAAP::Client::Auth;
use strict;
use warnings;
our $VERSION = 0.01;
use Carp;
use Digest::MD5 qw( md5_hex );
use HTTP::Request::Common;
use base qw( Net::DAAP::Client );

=head1 NAME

Net::DAAP::Client::Auth - Extend Net::DAAP::Client to do iTunes authorisation

=head1 SYNOPSIS

  # see Net::DAAP::Client;
  use Net::DAAP::Client::Auth;


=head1 DESCRIPTION

Subclasses Net::DAAP::Client and overrides methods to allow the module
to provide suitable authentication tokens for iTunes 4.2.

=cut



# XXX - this is less subclassing as a huge copy-and-paste job, taking
# the original ~50 line long _do_get from Net::DAAP::Client and adding
# about 20 more lines since the original _do_get could do with a chunk
# of refactoring


# for the v2.0 auth
my $validation_salt;
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

    # since we only ever Client-DAAP-Access-Index 1 we don't need the
    # full weight of the original libopendaap routine as translated at
    # http://unixbeard.net/svn/richardc/misc/iTunes_hasher
    $validation_salt ||= uc md5_hex( join(
        '',
        "user-agent", "Authorization", "Accept-Encoding", "daap.songartist",
        "daap.songdatemodified", "daap.songdisabled", "revision-number",
        "session-id" ));

    my $request = HTTP::Request::Common::GET(
        $url,
        "Client-DAAP-Version" => '2.0',
        "Client-DAAP-Validation" => uc md5_hex(
            $path. "Copyright 2003 Apple Computer, Inc." . $validation_salt),
        "Client-DAAP-Access-Index" => 1,
       );

    if ($file) {
        $res = $ua->request($request, $file);
    } else {
        $res = $ua->request($request);
    }

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

__END__

=head1 TODO

Incorporate the daap version 3 authentication, as used by iTunes 4.5,
and switch models appropriately.

I've already figured out the hasher, it's just a SMOP to detect iTunes
4.5 and act appropriately.
http://unixbeard.net/svn/richardc/misc/iTunes45_hasher

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright 2004 Richard Clamp.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.


=head1 BUGS

None known.

Bugs should be reported to me via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net::DAAP::Client::Auth>.


=head1 SEE ALSO

L<Net::DAAP::Client>,
L<libopendaap|http://craz.net/programs/itunes/libopendaap.html> from
which the auth code is adapted.

=cut
