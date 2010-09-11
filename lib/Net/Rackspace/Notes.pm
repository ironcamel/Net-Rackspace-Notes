use MooseX::Declare;

class Net::Rackspace::Notes extends LWP::UserAgent
{
    use Data::Dumper;
    use HTTP::Request;
    use JSON::XS qw/encode_json decode_json/;
    use MooseX::NonMoose; # Need this since LWP::UserAgent is non moose.

	our $VERSION = '0.0002';

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

    method BUILD($args) {
        $self->default_header(Accept => 'application/json');
    }

    method _build_base_uri_notes() {
        my ($response, $data);

        #$response = $self->get($self->base_uri);
        #$data = decode_json $response->content;
        #print Dumper $data;

        #$response = $self->get($data->{versions}[0]);
        $response = $self->get($self->base_uri . '/0.9.0');
        $data = decode_json $response->content;

        $response = $self->get($data->{usernames}[0]);
        $data = decode_json $response->content;

        return $data->{data_types}{notes}{uri};
    }

    # This method is blocking.  The new way is asynchronous and faster.
    method _build_notes_old() {
        my $response = $self->get($self->base_uri_notes);
        my $data = decode_json $response->content;

        my @notes;
        foreach my $note (@{$data->{notes}}) {
            $response = $self->get($note->{uri});
            $data = decode_json($response->content)->{note};
            $data->{uri} = $note->{uri};
            push @notes, $data;
        }
        return \@notes;
    }

    method _build_notes() {
        my $response = $self->get($self->base_uri_notes);
        my $data = decode_json $response->content;

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
            $data = decode_json($json)->{note};
            $data->{uri} = $uri;
            push @notes, $data;
        }

        return \@notes;
    }

    override get_basic_credentials($realm, $uri, $isproxy) {
        return $self->login, $self->password;
    }

    method add_note(Str $subject, Str $body) {
        my $req = HTTP::Request->new(POST => $self->base_uri_notes);
        $req->header(Content_Type => 'application/json');
        my $json = encode_json {
            note => {
                subject => $subject,
                content => $body,
            }
        };
        $req->content($json);
        my $response = $self->request($req);
        return $response;
    }

    method delete_note(Int $num) {
        my $index = $num - 1;
        my $uri = $self->notes->[$index]->{uri};
        my $req = HTTP::Request->new(DELETE => $uri);
        $req->header(Content_Type => 'application/json');
        my $response = $self->request($req);
        splice(@{$self->notes}, $index, 1) if ($response->is_success);
        return $response;
    }

    method content(Int $num) { $self->notes->[$num - 1]->{content} }

    method note(Int $num) { $self->notes->[$num - 1] }

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

=head2 delete_note

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
