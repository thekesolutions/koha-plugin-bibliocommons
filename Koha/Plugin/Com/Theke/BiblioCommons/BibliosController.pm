package Koha::Plugin::Com::Theke::BiblioCommons::BibliosController;

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

use Koha::Biblio::Metadatas;

=head1 Koha::Plugin::Com::Theke::BiblioCommons::BibliosController

A class implementing the controller methods for the biblios-related API

=head2 Class Methods

=head3 list_ids

Method that lists biblios ids based on the filters

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
        Koha::Biblio::Metadatas->search( $filter, $attributes )->as_list;

    return $c->render( status => 200, openapi => \@ids );
}

=head2 Internal methods

=head3 to_id_object

Helper class to convert Koha::Biblio::Metadata objects into biblio id result objects

=cut

sub _to_id_object {
    my ($biblio_metadata) = @_;

    my $id_object = {
        id     => $biblio_metadata->biblionumber,
        _links => {
            self => {
                href => '/api/v1/contrib/bibliocommons/biblios/' . $biblio_metadata->biblionumber
            }
        }
    };

    return $id_object;
}

1;
