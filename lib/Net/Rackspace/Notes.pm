package Net::Rackspace::Notes;
use Moose;
use MooseX::NonMoose;
extends 'LWP::UserAgent';

our $VERSION = '0.0002';

use HTTP::Request;
use JSON qw(to_json from_json);

has login => (
    isa => 'Str',
    is => 'ro',
    required => 1
);

has password => (
    isa => 'Str',
    is => 'ro',
    required => 1
);

has base_uri => (
    isa => 'Str',
    is => 'ro',
    default => "http://apps.rackspace.com/api/",
);

has base_uri_notes => (
    isa => 'Str',
    is => 'ro',
    lazy_build => 1,
);

has notes => (
    isa => 'ArrayRef[HashRef[Str]]',
    is => 'ro',
    lazy_build => 1,
    auto_deref => 1,
);

sub BUILD {
    my ($self) = @_;
    $self->default_header(Accept => 'application/json');
}

sub _build_base_uri_notes {
    my ($self) = @_;
    my ($response, $data);

    #$response = $self->get($self->base_uri);
    #$data = from_json $response->content;
    #print Dumper $data;

    #$response = $self->get($data->{versions}[0]);
    $response = $self->get($self->base_uri . '/0.9.0');
    $data = from_json $response->content;

    $response = $self->get($data->{usernames}[0]);
    $data = from_json $response->content;

    return $data->{data_types}{notes}{uri};
}

# This method is blocking.  The new way is asynchronous and faster.
sub _build_notes_old {
    my ($self) = @_;
    my $response = $self->get($self->base_uri_notes);
    my $data = from_json $response->content;

    my @notes;
    foreach my $note (@{$data->{notes}}) {
        $response = $self->get($note->{uri});
        $data = from_json($response->content)->{note};
        $data->{uri} = $note->{uri};
        push @notes, $data;
    }
    return \@notes;
}

sub _build_notes {
    my ($self) = @_;
    my $response = $self->get($self->base_uri_notes);
    my $data = from_json $response->content;

    my @children;
    foreach my $uri (map $_->{uri}, @{$data->{notes}}) {
        my $pid = open my $p, '-|';
        if ($pid) { # parent
            push @children, [ $p, $uri ];
        } else { # child
            $response = $self->get($uri);
            print $response->content;
            exit;
        }
    }

    my @notes;
    foreach my $child (@children) {
        my ($p, $uri) = @$child;
        my $json;
        { local $/; $json = <$p>; }
        close $p;
        $data = from_json($json)->{note};
        $data->{uri} = $uri;
        push @notes, $data;
    }

    return \@notes;
}

override get_basic_credentials => sub {
    my ($self, $realm, $uri, $isproxy) = @_;
    return $self->login, $self->password;
};

sub add_note {
    my ($self, $subject, $body) = @_;
    my $req = HTTP::Request->new(POST => $self->base_uri_notes);
    $req->header(Content_Type => 'application/json');
    my $json = to_json {
        note => {
            subject => $subject,
            content => $body,
        }
    };
    $req->content($json);
    my $response = $self->request($req);
    return $response;
}

sub delete_note {
    my ($self, $num) = @_;
    my $index = $num - 1;
    my $uri = $self->notes->[$index]->{uri};
    my $req = HTTP::Request->new(DELETE => $uri);
    $req->header(Content_Type => 'application/json');
    my $response = $self->request($req);
    splice(@{$self->notes}, $index, 1) if ($response->is_success);
    return $response;
}

sub content {
    my ($self, $num) = @_;
    $self->notes->[$num - 1]->{content}
}

sub note {
    my ($self, $num) = @_;
    shift->notes->[$num - 1]
}


=head1 NAME

Net::Rackspace::Notes - A way to interface with your Rackspace Email Notes.

=head1 VERSION

Version 0.0002

=head1 SYNOPSIS

This class implements the functionality needed to 
interact with the Rackspace Email Notes API.
Most likely, the racknotes script will be what you want to use instead of this.

Example usage:

    use Net::Rackspace::Notes;

    my $n = Net::Rackspace::Notes->new();
    ...

=head1 FUNCTIONS

=head2 add_note

=head2 append_to_note

=head2 delete_note

=head2 list_notes

=head2 show_note

=head1 AUTHOR

Naveed Massjouni, C<< <naveedm9 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-rackspace-notes at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Rackspace-Notes>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Rackspace::Notes

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Rackspace-Notes>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Rackspace-Notes>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Rackspace-Notes>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Rackspace-Notes/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Naveed Massjouni.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

'Net::Rackspace::Notes'
