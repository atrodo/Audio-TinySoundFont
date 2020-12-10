use strict;
use Test::More;
use FindBin qw/$Bin/;
use Audio::TinySoundFont;

#my $tsf = Audio::TinySoundFont->new("$Bin/tiny.sf2");
my $tsf = Audio::TinySoundFont->new('/usr/share/sounds/sf2/FluidR3_GM.sf2');
isnt( $tsf, undef, 'Can create a new object');

my $preset = $tsf->preset('Tenor Sax');
isnt($preset, undef, 'Can get a preset');


my $snd = $preset->render(seconds => 5, note => 59, vel => 0.7);
isnt($snd, undef, 'Render works');
note('Length of $snd: ' . length $snd);
cmp_ok(length($snd), '>=', 2 * 44_100 * 5, 'Rendering is over 5 seconds');
cmp_ok(length($snd), '<=', 2 * 44_100 * 6, 'Rendering is also under 6 seconds');
unlike($snd, qr/^\0*$/, 'Sample was not empty');

done_testing;
