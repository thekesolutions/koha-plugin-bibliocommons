# koha-plugin-bibliocommons

At this stage, this is a toy project for creating a __useful__ API for Koha. It is
focused on retrieving information from Koha.

__Important__: If you think something could be improved, please share your thoughts by filing
an issue [here](https://github.com/thekesolutions/koha-plugin-bibliocommons/issues). THAT'S THE
WHOLE POINT OF THIS!

## Implemented endpoints

* /biblios/:biblio_id
* /biblios/:biblio_id/holds/count
* /biblios/:biblio_id/items
* /biblios/ids
* /items/:item_id
* /items/:item_id/holds/count
* /items/ids
* /libraries

## Install

Download the latest _.kpz_ file from the [releases](https://github.com/thekesolutions/koha-plugin-bibliocommons/releases) page.
Install it as any other plugin following the general [plugin install instrucions](https://wiki.koha-community.org/wiki/Koha_plugins).

Caveat: If you want to try this endpoints, you will need to do it on top of the [Koha master branch](https://gitlab.com/koha-community/Koha)
adding the patches from [bug 21116](https://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=21116).