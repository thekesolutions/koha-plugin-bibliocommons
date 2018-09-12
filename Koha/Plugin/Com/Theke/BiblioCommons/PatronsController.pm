package Koha::Plugin::Com::Theke::BiblioCommons::PatronsController;

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

use C4::Auth qw(checkpw_hash);
use C4::Context;
use Koha::Patrons;

=head1 Koha::Plugin::Com::Theke::BiblioCommons::PatronsController

A class implementing the controller methods for the patron-related endpoints

=head2 Class Methods

=head3 validate_credentials

Method that validates a patron's password

=cut

sub validate_credentials {
    my $c = shift->openapi->valid_input or return;

    my $body        = $c->validation->param('body');
    my $card_number = $body->{card_number};
    my $password    = $body->{password};

    if (   !defined $cardnumber
        or !defined $password )
    {
        return $c->render( status => 400, openapi => { error => 'Invalid parameters' } );
    }

    my $patron = Koha::Patrons->find( { cardnumber => $card_number } );

    unless ($patron) {
        return $c->render( status => 404, openapi => { error => 'Object not found.' } );
    }

    my $result
        = ( checkpw_hash( $password, $patron->password ) )
        ? Mojo::JSON->true
        : Mojo::JSON->false;

    return $c->render( status => 200, openapi => $result );
}

1;
