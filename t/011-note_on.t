use strict;
use Test::More;
use FindBin qw/$Bin/;
use Audio::TinySoundFont;

use autodie;
use Try::Tiny;

{
  my $tsf = Audio::TinySoundFont->new("$Bin/tiny.sf2");

  is( $tsf->is_active, '', 'Fresh instance is inactive' );

  $tsf->note_on('');
  is( $tsf->is_active, 1, 'note_on makes it active' );

  $tsf->note_off('');
  is( $tsf->is_active, 1, 'note_off immedietely does not makes it inactive' );

  $tsf->render( seconds => 5 );
  is( $tsf->is_active, '', 'note_off after 5 seconds does make it inactive' );
}

done_testing;
