package Net::DAAP::Client::Auth::Protocol::vAny;
use strict;
use warnings;
use base qw( Net::DAAP::Client::Auth::Protocol );

sub _md5_thingy { "foo" }

sub _do_get {
    my $self = shift;
    my $url  = shift;
    # XXX - we'd return a dummy DMAP response here, but currently
    # Net::DAAP::DMAP doesn't generate DMAP packets (fuckers!)
    return 42 if $url =~ m{update};
    return $self->SUPER::_do_get( $url, @_ );
}

1;

