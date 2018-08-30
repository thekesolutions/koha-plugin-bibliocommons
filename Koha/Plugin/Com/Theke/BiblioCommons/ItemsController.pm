package Koha::Plugin::Com::Theke::BiblioCommons::ItemsController;

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

use Koha::Items;

=head1 Koha::Plugin::Com::Theke::BiblioCommons::ItemsController

A class implementing the controller methods for the items-related API

=head2 Class Methods

=head3 list_ids

Method that lists items ids based on the filters

=cut

sub list_ids {
    my $c = shift->openapi->valid_input or return;

    my $args = $c->validation->output;
    my $attributes = {};
    my ( $params, $reserved_params ) = $c->extract_reserved_params($args);

    # Merge pagination into query attributes
    $c->dbic_merge_pagination({ filter => $attributes, params => $reserved_params });

    my $timestamp_gte = $params->{'timestamp[gte]'};
    my $timestamp_lte = $params->{'timestamp[lte]'};

    my $filter;

    if ( $timestamp_gte or $timestamp_lte ) {

        # add a filter!
        my @filter_conditions;
        push @filter_conditions, { '>=' => $timestamp_gte }
            if $timestamp_gte;
        push @filter_conditions, { '<=' => $timestamp_lte }
            if $timestamp_lte;

        $filter->{ 'timestamp' } = \@filter_conditions;
    }

    my @ids = map { _to_id_object($_) }
        Koha::Items->search( $filter, $attributes )->get_column('itemnumber');

    return $c->render( status => 200, openapi => \@ids );
}

=head3 get_item

=cut

sub get_item {
    my $c = shift->openapi->valid_input or return;

    my $item_id = $c->validation->param('item_id');
    my $item = Koha::Items->find( $item_id );

    unless ( $item ) {
        return $c->render( status => 404, openapi => { error => "Object not found." } );
    }

    return $c->render( status => 200, openapi => to_api($item->TO_JSON) );
}

=head2 Internal methods

=head3 to_id_object

Helper class to convert Koha::Biblio::Metadata objects into biblio id result objects

=cut

sub _to_id_object {
    my ($item_id) = @_;

    my $id_object = {
        id     => $item_id,
        _links => {
            self => {
                href => '/api/v1/contrib/bibliocommons/items/' . $item_id
            }
        }
    };

    return $id_object;
}

=head3 to_api

Helper function that maps unblessed (TO_JSON) Koha::Item objects into REST api
attribute names.

=cut

sub to_api {
    my $item = shift;

    # Rename attributes
    foreach my $column ( keys %{ $Koha::Plugin::Com::Theke::BiblioCommons::ItemsController::to_api_mapping } ) {
        my $mapped_column = $Koha::Plugin::Com::Theke::BiblioCommons::ItemsController::to_api_mapping->{$column};
        if (    exists $item->{ $column }
             && defined $mapped_column )
        {
            # key != undef
            $item->{ $mapped_column } = delete $item->{ $column };
        }
        elsif (    exists $item->{ $column }
                && !defined $mapped_column )
        {
            # key == undef
            delete $item->{ $column };
        }
    }

    return $item;
}

=head2 Global variables

=head3 $to_api_mapping

=cut

our $to_api_mapping = {
    biblionumber             => 'biblio_id',
    biblioitemnumber         => undef,
    booksellerid             => 'acquisition_source',
    ccode                    => 'collection',
    coded_location_qualifier => undef,
    copynumber               => 'copy_number',
    dateaccessioned          => 'acquisition_date',
    datelastborrowed         => 'last_checkout_date',
    datelastseen             => 'last_seen_date',
    enumchron                => 'serial_enum_chron',
    holdingbranch            => 'holding_library',
    homebranch               => 'home_library',
    issues                   => 'checkout_count',
    itemcallnumber           => 'callnumber',
    itemlost                 => 'lost',
    itemlost_on              => 'lost_on',
    itemnotes                => 'public_notes',
    itemnotes_nonpublic      => 'internal_notes',
    itemnumber               => 'item_id',
    itype                    => 'item_type',
    materials                => 'materials_notes',
    notforloan               => 'notforloan',
    onloan                   => 'due_date',
    paidfor =>
        undef
    , # It is a hardcoded internal note added when a lost item that was charged to a patron is returned
    price                => 'purchase_price',
    renewals             => 'renewals',
    replacementprice     => 'replacement_price',
    replacementpricedate => 'replacement_price_date',
    reserves             => undef,                      # Bug 12530
    stack                => undef,
    stocknumber          => 'inventory_number',
};

1;
