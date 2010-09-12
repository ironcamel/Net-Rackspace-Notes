package Net::Rackspace::Notes;
use Moose;

our $VERSION = '0.0100';

use HTTP::Request;
use JSON qw(to_json from_json);
use LWP::UserAgent;

has email => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has password => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has agent => (
    is => 'ro',
    isa => 'LWP::UserAgent',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $agent = LWP::UserAgent->new();
        $agent->credentials('apps.rackspace.com:80', 'webmail',
            $self->email, $self->password);
        $agent->default_header(Accept => 'application/json');
        return $agent;
    },
);

has base_uri => (
    is => 'ro',
    isa => 'Str',
    default => 'http://apps.rackspace.com/api/',
);

has base_uri_notes => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    builder => '_build_base_uri_notes',
);

has notes => (
    is => 'ro',
    isa => 'ArrayRef[HashRef[Str]]',
    lazy => 1,
    builder => '_build_notes',
);

sub _build_base_uri_notes {
    my ($self) = @_;

    my ($response, $data);

    #$response = $self->get($self->base_uri);
    #$data = from_json $response->content;
    #print Dumper $data;

    #$response = $self->get($data->{versions}[0]);
    $response = $self->agent->get($self->base_uri . "/0.9.0");
    my $status = $response->status_line;
    die "Response was $status. Check your email and password.\n"
        unless $status =~ /^2\d\d/;
    $data = from_json $response->content;

    $response = $self->agent->get($data->{usernames}[0]);
    $data = from_json $response->content;

    return $data->{data_types}{notes}{uri};
}

sub _build_notes {
    my ($self) = @_;
    my $response = $self->agent->get($self->base_uri_notes);
    my $data = from_json $response->content;

    my @children;
    foreach my $uri (map $_->{uri}, @{$data->{notes}}) {
        my $pid = open my $p, '-|';
        if ($pid) { # parent
            push @children, [ $p, $uri ];
        } else { # child
            $response = $self->agent->get($uri);
            print $response->content;
            exit;
        }
    }

    my @notes;
    foreach my $child (@children) {
        my ($p, $uri) = @$child;
        my $json = do { local $/; <$p> };
        close $p;
        $data = from_json($json)->{note};
        $data->{uri} = $uri;
        push @notes, $data;
    }

    return \@notes;
}

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
    my $response = $self->agent->request($req);
    return $response;
}

sub delete_note {
    my ($self, $num) = @_;
    my $uri = $self->notes->[$num]->{uri};
    my $req = HTTP::Request->new(DELETE => $uri);
    $req->header(Content_Type => 'application/json');
    my $response = $self->agent->request($req);
    #splice(@{notes()}, $num, 1) if ($response->is_success);
    return $response;
}

=head1 NAME

Net::Rackspace::Notes - A way to interface with your Rackspace Email Notes.

=head1 VERSION

Version 0.0100

=head1 SYNOPSIS

This class implements the functionality needed to 
interact with the Rackspace Email Notes API.
Most likely, the racknotes script will be what you want to use instead of this.

Example usage:

    use Net::Rackspace::Notes qw(add_note delete_note notes);
    Net::Rackspace::Notes::init(
        email  => 'bob@foo.com',
        password => 'foo'
    );

    for my $note (@{notes()}) {
        print "$note->{subject}: $note->{content}\n";
    }

    # Add a new note with the given subject and content
    add_note('some subject', 'some important note');

    # Delete notes()->[3]
    delete_note(3);


=head1 FUNCTIONS

=head2 add_note

=head2 delete_note

=head2 notes

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
