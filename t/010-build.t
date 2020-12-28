use strict;
use Test::More;
use FindBin qw/$Bin/;
use Audio::TinySoundFont;

use autodie;
use Try::Tiny;

my $sf2_file = "$Bin/tiny.sf2";
open my $sf2_fh, '<', $sf2_file;
my $sf2 = do { local $/; <$sf2_fh> };
$sf2_fh->seek(0,0);

# Scalar (file name)
SKIP:
{
  my $tsf = try { Audio::TinySoundFont->new($sf2_file) };

  isnt( $tsf, undef, 'Can create a new object' );

  my $preset = $tsf->preset('');
  isnt( $preset, undef, 'Can get a preset' );
}

# Scalar ref (file contents)
SKIP:
{
  my $tsf = try { Audio::TinySoundFont->new(\$sf2) } catch { note $_ ; undef };

  isnt( $tsf, undef, 'Can create a new object from scalar ref' );

  my $preset = try { $tsf->preset('') };
  isnt( $preset, undef, 'Can get a preset' );
}

# Glob (real filehandle)
{
  my $tsf = try { Audio::TinySoundFont->new($sf2_fh) } catch { note $_ ; undef };
  $sf2_fh->seek(0,0);

  isnt( $tsf, undef, 'Can create a new object from file handle' );

  my $preset = try { $tsf->preset('') };
  isnt( $preset, undef, 'Can get a preset' );
}

# Glob (perl filehandle)
{
  open my $sf2_glob, '<', \$sf2;
  my $tsf = try { Audio::TinySoundFont->new($sf2_glob) } catch { note $_ ; undef };;

  isnt( $tsf, undef, 'Can create a new object from glob' );

  my $preset = try { $tsf->preset('') };
  isnt( $preset, undef, 'Can get a preset' );
}

done_testing;
