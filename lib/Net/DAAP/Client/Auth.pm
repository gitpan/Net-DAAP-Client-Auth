package Net::DAAP::Client::Auth;
use strict;
use warnings;
use Net::DAAP::Client::Auth::Protocol::vAny;
use Net::DAAP::Client::Auth::Protocol::v2;
use Net::DAAP::Client::Auth::Protocol::v3;
use base qw( Net::DAAP::Client );
our $VERSION = '0.13';

=head1 NAME

Net::DAAP::Client::Auth - Extend Net::DAAP::Client to do iTunes authorisation

=head1 SYNOPSIS

  # see Net::DAAP::Client;
  use Net::DAAP::Client::Auth;


=head1 DESCRIPTION

Subclasses Net::DAAP::Client and overrides methods to allow the module
to provide suitable authentication tokens for iTunes 4.2 and 4.5.

=cut


# cheesy - rebless based on the iTunes reported version
sub _do_get {
    my $self = shift;

    my $response = LWP::UserAgent->new->get(
        "http://" . $self->{SERVER_HOST} . ":" . $self->{SERVER_PORT} .
          "/server-info");

    my $server = $response->headers->header('DAAP-Server') || '';
    if ( $server =~ m{iTunes/4\.[56]} ) {
        bless $self, __PACKAGE__."::Protocol::v3";
    }
    elsif ( $server =~ m{iTunes} ) {
        bless $self, __PACKAGE__."::Protocol::v2";
    }
    else {
        bless $self, __PACKAGE__."::Protocol::vAny";
    }
    $self->_do_get( @_ );
}


1;

__END__

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
