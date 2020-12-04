package Audio::TinySoundFont::XS;

use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load( 'Audio::TinySoundFont', $VERSION );

use parent qw/Exporter/;

1;
