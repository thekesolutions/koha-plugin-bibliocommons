package Koha::Plugin::Com::Theke::BiblioCommons::LibrariesController;

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

use Koha::Libraries;

=head1 Koha::Plugin::Com::Theke::BiblioCommons::LibrariesController

A class implementing the controller methods for the items-related API

=head2 Class Methods

=head3 list_ids

Method that lists items ids based on the filters

=cut

sub list_libraries {
    my $c = shift->openapi->valid_input or return;

    my @libraries = map { { library_id => $_->branchcode, name => $_->branchname } }
        Koha::Libraries->search->as_list;

    return $c->render( status => 200, openapi => \@libraries );
}

1;
