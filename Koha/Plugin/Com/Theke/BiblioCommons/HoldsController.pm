package Koha::Plugin::Com::Theke::BiblioCommons::HoldsController;

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# This program comes with ABSOLUTELY NO WARRANTY;

use Modern::Perl;

use Mojo::Base 'Mojolicious::Controller';

use Koha::Biblios;
use Koha::Holds;
use Koha::Items;

=head1 Koha::Plugin::Com::Theke::BiblioCommons::HoldsController

A class implementing the controller methods for the holds-related API

=head2 Class Methods

=head3 add_biblio_hold

Method to add biblio-level holds

=cut

sub add_biblio_hold {
    my $c = shift->openapi->valid_input or return;

    my $biblio_id = $c->validation->param('biblio_id');
    my $biblio    = Koha::Biblios->find($biblio_id);

    unless ($biblio) {
        return $c->render( status => 404, openapi => { error => "Object not found." } );
    }

    my $body = $c->validation->param('body');

    my $expiration_date   = $body->{expiration_date};
    my $hold_date         = $body->{hold_date};
    my $item_type_id      = $body->{item_type_id};
    my $notes             = $body->{notes};
    my $patron_id         = $body->{patron_id};
    my $pickup_library_id = $body->{pickup_library_id};
    my $priority          = $body->{priority};
    my $status            = $body->{status} // 'pending';

    my $found
        = ( $status eq 'waiting' ) ? 'W'
        : ( $status eq 'in_transit' ) ? 'T'
        :                               undef;    # ( $status eq 'pending' )

    my $hold_id = AddReserve(
        $pickup_library_id,
        $patron_id,
        $biblio_id,
        undef,                                    # $bibitems
        $priority,
        $hold_date,
        $expiration_date,
        $notes,
        ($biblio) ? $biblio->title : undef,
        undef,
        $found,
        $item_type_id
    );

    my $hold = Koha::Holds->find($hold_id);

    return $c->render( status => 200, openapi => to_compound_object($hold) );
}

=head3 get_biblio_holds

=cut

sub get_biblio_holds {
    my $c = shift->openapi->valid_input or return;

    my $biblio_id = $c->validation->param('biblio_id');
    my $biblio    = Koha::Biblios->find($biblio_id);

    unless ($biblio) {
        return $c->render( status => 404, openapi => { error => "Object not found." } );
    }

    my @holds
        = map { to_compound_object($_) } Koha::Holds->search( { biblionumber => $biblio_id } );

    return $c->render( status => 200, openapi => \@holds );
}

=head3 get_biblio_holds_count

=cut

sub get_biblio_holds_count {
    my $c = shift->openapi->valid_input or return;

    my $biblio_id = $c->validation->param('biblio_id');
    my $biblio    = Koha::Biblios->find($biblio_id);

    unless ($biblio) {
        return $c->render( status => 404, openapi => { error => "Object not found." } );
    }

    my $holds = Koha::Holds->search( { biblionumber => $biblio_id } );

    return $c->render( status => 200, openapi => $holds->count );
}

=head3 add_item_hold

Method to add item-level holds

=cut

sub add_item_hold {
    my $c = shift->openapi->valid_input or return;

    my $item_id = $c->validation->param('item_id');
    my $item    = Koha::Items->find($item_id);

    unless ($item) {
        return $c->render( status => 404, openapi => { error => "Object not found." } );
    }

    my $body = $c->validation->param('body');

    my $expiration_date   = $body->{expiration_date};
    my $hold_date         = $body->{hold_date};
    my $notes             = $body->{notes};
    my $patron_id         = $body->{patron_id};
    my $pickup_library_id = $body->{pickup_library_id};
    my $priority          = $body->{priority};
    my $status            = $body->{status} // 'pending';

    my $found
        = ( $status eq 'waiting' ) ? 'W'
        : ( $status eq 'in_transit' ) ? 'T'
        :                               undef;    # ( $status eq 'pending' )

    my $biblio = $item->biblio;

    my $hold_id = AddReserve(
        $pickup_library_id,
        $patron_id,
        undef,                                    # $biblio_id
        undef,                                    # $bibitems
        $priority,
        $hold_date,
        $expiration_date,
        $notes,
        ($biblio) ? $biblio->title : undef,
        $item_id,
        $found,
        undef                                     # $item_type_id
    );

    my $hold = Koha::Holds->find($hold_id);

    return $c->render( status => 200, openapi => to_compound_object($hold) );
}

=head3 get_item_holds

=cut

sub get_item_holds {
    my $c = shift->openapi->valid_input or return;

    my $item_id = $c->validation->param('item_id');
    my $item    = Koha::Items->find($item_id);

    unless ($item) {
        return $c->render( status => 404, openapi => { error => "Object not found." } );
    }

    my @holds = map { to_compound_object($_) } Koha::Holds->search( { itemnumber => $item_id } );

    return $c->render( status => 200, openapi => \@holds );
}

=head3 get_item_holds_count

=cut

sub get_item_holds_count {
    my $c = shift->openapi->valid_input or return;

    my $item_id = $c->validation->param('item_id');
    my $item    = Koha::Biblios->find($item_id);

    unless ($item) {
        return $c->render( status => 404, openapi => { error => "Object not found." } );
    }

    my $holds = Koha::Holds->search( { itemnumber => $item_id } );

    return $c->render( status => 200, openapi => $holds->count );
}

=head2 Internal methods

=head3 to_id_object

Helper class to convert Koha::Hold objects into hold id result objects

=cut

sub _to_id_object {
    my ($hold_id) = @_;

    my $id_object = {
        id     => $hold_id,
        _links => { self => { href => '/api/v1/contrib/bibliocommons/holds/' . $hold_id } }
    };

    return $id_object;
}

=head3 to_compound_object

=cut

sub to_compound_object {
    my ($hold) = @_;

    my $unblessed = to_api( $hold->TO_JSON );
    $unblessed->{_links}->{self}->{href} = '/api/v1/contrib/bibliocommons/holds/' . $hold->id;

    return $unblessed;
}

=head3 to_api

Helper function that maps unblessed (TO_JSON) Koha::Hold objects into REST api
attribute names.

=cut

sub to_api {
    my $hold = shift;

    # Rename attributes
    foreach my $column (
        keys %{$Koha::Plugin::Com::Theke::BiblioCommons::HoldsController::to_api_mapping} )
    {
        my $mapped_column
            = $Koha::Plugin::Com::Theke::BiblioCommons::HoldsController::to_api_mapping->{$column};
        if ( exists $hold->{$column}
            && defined $mapped_column )
        {
            # key != undef
            $hold->{$mapped_column} = delete $hold->{$column};
        }
        elsif ( exists $hold->{$column}
            && !defined $mapped_column )
        {
            # key == undef
            delete $hold->{$column};
        }
    }

    return $hold;
}

=head2 Global variables

=head3 $to_api_mapping

=cut

our $to_api_mapping = {
    reserve_id       => 'hold_id',
    borrowernumber   => 'patron_id',
    reservedate      => 'hold_date',
    biblionumber     => 'biblio_id',
    branchcode       => 'pickup_library_id',
    notificationdate => undef,
    reminderdate     => undef,
    cancellationdate => 'cancellation_date',
    reservenotes     => 'notes',
    found            => 'status',
    itemnumber       => 'item_id',
    waitingdate      => 'waiting_date',
    expirationdate   => 'expiration_date',
    lowestPriority   => 'lowest_priority',
    suspend          => 'suspended',
    suspend_until    => 'suspended_until',
    itemtype         => 'item_type'
};

1;
