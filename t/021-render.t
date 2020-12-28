use strict;
use Test::More;
use FindBin qw/$Bin/;
use List::Util qw/sum/;
use Audio::TinySoundFont;

my $tsf = Audio::TinySoundFont->new("$Bin/tiny.sf2");
isnt( $tsf, undef, 'Can create a new object' );

my $preset = $tsf->preset('');
isnt( $preset, undef, 'Can get a preset' );

my $snd
    = $preset->render( seconds => 5, note => 59, vel => 0.7, volume => .3 );
isnt( $snd, undef, 'Render works' );
note( 'Length of $snd: ' . length $snd );
cmp_ok( length($snd), '>=', 2 * 44_100 * 5, 'Rendering is over 5 seconds' );
cmp_ok(
  length($snd), '<=', 2 * 44_100 * 6,
  'Rendering is also under 6 seconds'
);
unlike( $snd, qr/^\0*$/, 'Sample was not empty' );

{
  my $ld_snd
      = $preset->render( seconds => 5, note => 59, vel => 0.7, volume => .5 );
  is( length $ld_snd, length $snd, 'A rerender causes an identical length' );
  unlike( $snd, qr/^\0*$/, 'Sample was not empty' );

  my @snds = reverse sort unpack 's<*', $snd;
  splice( @snds, int( @snds * .1 ) );
  my $sndp10 = sum(@snds) / scalar(@snds);

  my @ld_snds = reverse sort unpack 's<*', $ld_snd;
  splice( @ld_snds, int( @ld_snds * .1 ) );
  my $ld_sndp10 = sum(@ld_snds) / scalar(@ld_snds);
  cmp_ok(
    $ld_sndp10, '>', $sndp10,
    'A higher volume creates a louder render'
  );
}

done_testing;
