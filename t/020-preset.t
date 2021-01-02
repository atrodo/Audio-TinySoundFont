use strict;
use Test::More;
use FindBin qw/$Bin/;
use List::Util qw/sum/;
use Audio::TinySoundFont;

my $tsf = Audio::TinySoundFont->new("$Bin/tiny.sf2");
isnt( $tsf, undef, 'Can create a new object' );

my $preset = $tsf->preset('test');
isnt( $preset, undef, 'Can get a preset' );
is( $preset->name, 'test', 'Name is retrieved' );

done_testing;
