package Koha::Plugin::Com::Theke::BiblioCommons::AuthoritiesController;

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

use C4::AuthoritiesMarc;
use MARC::Record::MiJ;

=head1 Koha::Plugin::Com::Theke::BiblioCommons::AuthoritiesController

A class implementing the controller methods for the authorities-related API

=head2 Class Methods

=head3 list_ids

Method that lists authorities ids based on the filters

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

        $filter->{ 'modification_time' } = \@filter_conditions;
    }

    my @ids = map { _to_id_object($_) }
        Koha::Authorities->search( $filter, $attributes )->get_column('authid');

    return $c->render( status => 200, openapi => \@ids );
}

=head3 get_authority

=cut

sub get_authority {
    my $c = shift->openapi->valid_input or return;

    my $authority_id = $c->validation->param('authority_id');
    my $record       = C4::AuthoritiesMarc::GetAuthority( $authority_id );

    unless ( $record ) {
        return $c->render( status => 404, openapi => { error => "Object not found." } );
    }

    return
        $c->respond_to(
            marcxml => { status => 200, format => 'marcxml', text => $record->as_xml_record },
            mij     => { status => 200, format => 'mij',     text => $record->to_mij  },
            marc    => { status => 200, format => 'marc',    text => $record->as_usmarc },
            any     => { status => 200, format => 'marcxml', text => $record->as_xml_record }
        );
}

=head2 Internal methods

=head3 to_id_object

Helper class to wrap an authority record id in a HAL-like structure

=cut

sub _to_id_object {
    my ($authority_id) = @_;

    my $id_object = {
        id     => $authority_id,
        _links => {
            self => {
                href => '/api/v1/contrib/bibliocommons/authorities/' . $authority_id
            }
        }
    };

    return $id_object;
}

1;
