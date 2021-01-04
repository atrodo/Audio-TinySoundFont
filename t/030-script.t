use strict;
use Test::More;
use FindBin qw/$Bin/;
use Audio::TinySoundFont;

use autodie;
use Try::Tiny;

{
  my $tsf      = Audio::TinySoundFont->new("$Bin/tiny.sf2");
  my $SR       = $tsf->SAMPLE_RATE;
  my @script_a = (
    {
      preset => '',
      note   => 59,
    },
    {
      preset => '',
      note   => 60,
    },
  );
  my @script_b = (
    {
      preset => '',
      note   => 61,
      at     => 1,
      for    => 3,
    },
    {
      preset => '',
      note   => 62,
      at     => 2,
      for    => 0.5
    },
  );
  my @script_c = (
    {
      preset     => '',
      note       => 63,
      at         => 5 * $SR,
      for        => 1 * $SR,
      in_seconds => 0,
    },
  );

  my $script = $tsf->new_script([@script_a]);
  is( scalar @{ $script->play_script }, 2,     'new with items did add items' );
  isnt( $script->play_script->[0], $script_a[0], 'play_script[0] is not a ref to the original' );
  isnt( $script->play_script->[1], $script_a[1], 'play_script[1] is not a ref to the original' );

  $script = $tsf->new_script;
  is( scalar @{ $script->play_script }, 0,     'new without items did not add items' );

  my $error;
  try { $script->set_script( [] ) } catch { $error = $_ };
  is( $error,                        undef, 'set_script with empty script without error' );
  is( scalar @{ $script->play_script }, 0,     'set_script did not add items' );

  try { $script->set_script( [@script_a] ) } catch { $error = $_ };
  is( $error,                        undef, 'set_script with simple script without error' );
  is( scalar @{ $script->play_script }, 2,     'set_script did not add items' );

  try { $script->add_script( [@script_b] ) } catch { $error = $_ };
  is( $error,                        undef, 'add_script with simple script without error' );
  is( scalar @{ $script->play_script }, 4,     'add_script added items' );

  isnt( $script->play_script->[0], $script_a[0], 'play_script[0] is not a ref to the original' );
  isnt( $script->play_script->[1], $script_a[1], 'play_script[1] is not a ref to the original' );
  isnt( $script->play_script->[2], $script_a[2], 'play_script[2] is not a ref to the original' );
  isnt( $script->play_script->[3], $script_a[3], 'play_script[3] is not a ref to the original' );

  try { $script->clear_script } catch { $error = $_ };
  is( $error,                        undef, 'clear_script with simple script without error' );
  is( scalar @{ $script->play_script }, 0,     'clear_script cleared items' );

  $script->add_script( [@script_a] );
  $script->add_script( [@script_b] );
  $script->add_script( [@script_c] );
  is( scalar @{ $script->play_script }, 5, 'add_script added items' );

  my $all_snd = $script->render_script;
  is( scalar @{ $script->play_script }, 5, 'render_script did not remove items' );
  is( $tsf->active_voices,           0, 'render_script ends with no active voices' );

  $script->clear_script;
  $script->add_script( [@script_c] );
  my $c_snd = $script->render_script;

  is( length $all_snd, length $c_snd, 'Using the last script item only produces an identical length' );
}

# Check script errors
{
  my $tsf = Audio::TinySoundFont->new("$Bin/tiny.sf2");
  my $script = $tsf->new_script( [ { preset => '' } ] );
  $tsf->note_on('');
  my $error;
  my $snd = try { $script->render_script } catch { $error = $_; undef };
  is( $snd, undef, 'A render_script when there are active voices fails' );
  like( $error, qr/is active/, 'Error is about TSF being active' );

  $script->clear_script;
  undef $error;
  try { $script->add_script( {} ) } catch { $error = $_ };
  note $error;
  isnt( $error, undef, 'Error adding anything but an ArrayRef script items' );
  like( $error, qr/requires an ArrayRef/, 'Error refers to an ArrayRef' );

  undef $error;
  my $playscript_tsf
      = try { Audio::TinySoundFont->new( "$Bin/tiny.sf2", play_script => [] ) } catch { $error = $_; undef };
  isnt( $playscript_tsf, undef, 'Trying to add a play_script at construction works' );

  undef $error;
  my $error_tsf = try { Audio::TinySoundFont->new( "$Bin/tiny.sf2", play_script => {} ) } catch { $error = $_; undef };
  is( $error_tsf, undef, 'Trying to add an non-ArrayRef play_script at construction does not works' );
  note $error;
  isnt( $error, undef, 'Got an error trying to set non-ArrayRef play_script' );
  like( $error, qr/requires an ArrayRef/, 'Error refers to an ArrayRef' );
}

done_testing;
