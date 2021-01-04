package Audio::TinySoundFont;

use v5.14;
use warnings;
our $VERSION = '0.01';

use autodie;
use Carp;
use Try::Tiny;
use Scalar::Util qw/blessed/;

use Moo;
use Types::Standard qw/ArrayRef HashRef GlobRef Str Int Num InstanceOf/;

use Audio::TinySoundFont::XS;
use Audio::TinySoundFont::Preset;

has _tsf => (
  is       => 'ro',
  isa      => InstanceOf ['Audio::TinySoundFont::XS'],
  required => 1,
);

has volume => (
  is      => 'rw',
  isa     => Num,
  default => 0.3,
  trigger => sub { my $self = shift; $self->_tsf->set_volume(shift) },
);

has preset_count => (
  is  => 'lazy',
  isa => Int,
);

has presets => (
  is  => 'lazy',
  isa => HashRef,
);

has play_script => (
  is      => 'rwp',
  isa     => ArrayRef,
  default => sub { [] },
  coerce  => \&_coerce_play_script,
);

*SAMPLE_RATE = \&Audio::TinySoundFont::XS::SAMPLE_RATE;

my $XS        = 'Audio::TinySoundFont::XS';
my %ref_build = (
  '' => sub
  {
    my $file = shift;
    croak qq{File "$file" doesn't exist}
        if !-e $file;
    return try { $XS->load_file($file) } catch { croak $_ };
  },
  SCALAR => sub
  {
    my $str = shift;
    open my $glob, '<', $str;
    return try { $XS->load_fh($glob) } catch { croak $_ };
  },
  GLOB => sub
  {
    my $fh = shift;
    return try { $XS->load_fh($fh) } catch { croak $_ };
  },
);

sub BUILDARGS
{
  my $class = shift;
  my $file  = shift;
  my $args  = Moo::Object::BUILDARGS( $class, @_ );

  my $build_fn = $ref_build{ ref $file };
  croak "Cannot load soundfont file, unknown ref: " . ref($file)
      if !defined $build_fn;
  my $tsf = $build_fn->($file);
  $args->{volume} = 0.3;

  $args->{_tsf} = $tsf;

  return $args;
}

sub _build_preset_count
{
  my $self = shift;

  return $self->_tsf->presetcount;
}

sub _build_presets
{
  my $self = shift;

  my %result;
  foreach my $i ( 0 .. $self->preset_count )
  {
    my $name     = $self->_tsf->get_presetname($i) // '';
    my $n        = '';
    my $conflict = 1;
    while ( exists $result{"$name$n"} )
    {
      $conflict++;
      $n = "_$conflict";
    }
    $name = "$name$n";
    $result{$name} = Audio::TinySoundFont::Preset->new(
      soundfont => $self,
      index     => $i,
    );
  }

  return \%result;
}

sub preset
{
  my $self = shift;
  my $name = shift;

  my $preset = $self->presets->{$name};

  croak qq{Could not find preset "$name"}
      if !defined $preset;

  return $preset;
}

sub preset_index
{
  my $self  = shift;
  my $index = shift;

  croak qq{Could not find preset "$index"}
      if $index >= $self->preset_count;

  return Audio::TinySoundFont::Preset->new(
    soundfont => $self,
    index     => $index,
  );
}

sub active_voices
{
  my $self = shift;
  return $self->_tsf->active_voices;
}

sub is_active
{
  my $self = shift;
  return !!$self->_tsf->active_voices;
}

sub note_on
{
  my $self   = shift;
  my $preset = shift // croak "Preset is required for note_on";
  my $note   = shift // 60;
  my $vel    = shift // 0.5;

  if ( !blessed $preset )
  {
    $preset = $self->preset($preset);
  }

  ( InstanceOf ['Audio::TinySoundFont::Preset'] )->($preset);

  $self->_tsf->note_on( $preset->index, $note, $vel );
  return;
}

sub note_off
{
  my $self   = shift;
  my $preset = shift // croak "Preset is required for note_off";
  my $note   = shift // 60;

  if ( !blessed $preset )
  {
    $preset = $self->preset($preset);
  }

  ( InstanceOf ['Audio::TinySoundFont::Preset'] )->($preset);

  $self->_tsf->note_off( $preset->index, $note );
  return;
}

sub _coerce_play_script
{
  my $new_script = shift;

  croak "play_script requires an ArrayRef"
      if ref $new_script ne 'ARRAY';

  my @result;
  foreach my $item (@$new_script)
  {
    carp "Script items must be a HashRef, not: " . ref $item
        if ref $item ne 'HASH';

    push @result, {
      in_seconds => ( $item->{in_seconds} // 1 ) + 0,
      at         => ( $item->{at}         // 0 ) + 0,
      for        => ( $item->{for}        // 1 ) + 0,
      note       => ( $item->{note}       // 60 ) + 0,
      vel        => ( $item->{vel}        // 0.5 ) + 0,
      preset => ( $item->{preset} // '' ),
    };
  }

  return \@result;
}

sub clear_script
{
  my $self = shift;

  $self->set_script( [] );

  return;
}

sub set_script
{
  my $self   = shift;
  my $script = shift;

  $self->_set_play_script($script);

  return;
}

sub add_script
{
  my $self   = shift;
  my $script = shift;

  croak "add_script requires an ArrayRef"
      if ref $script ne 'ARRAY';

  my $old_script = $self->play_script;
  $self->_set_play_script( [ @$old_script, @$script ] );

  return;
}

sub render_script
{
  my $self = shift;

  my $script = $self->play_script;
  my $SR     = $self->SAMPLE_RATE;
  my $result = '';

  croak "Cannot process play_script when TinySoundFont is active"
      if $self->is_active;

  # Create a specialized structure to create a rendering:
  # [ timestamp, fn, preset, note, vel ]
  my @insrs;
  foreach my $item (@$script)
  {
    my $at = $item->{at};
    my $to = $at + $item->{for};
    if ( $item->{in_seconds} )
    {
      $at *= $SR;
      $to *= $SR;
    }
    push @insrs, [ $at, 'note_on', @$item{ qw/preset note vel/ } ];
    push @insrs, [ $to, 'note_off', @$item{ qw/preset note vel/ } ];
  }

  @insrs = sort { $a->[0] <=> $b->[0] } @insrs;

  my $current_ts = 0;
  my $tsf = $self->_tsf;
  foreach my $i ( 0 .. $#insrs )
  {
    my ( $ts, $fn, @args ) = @{ $insrs[$i] };
    $result .= $tsf->render( $ts - $current_ts );
    $self->$fn(@args);
    $current_ts = $ts;
  }

  my $cleanup_samples = 4096;
  for ( 1 .. 256 )
  {
    last
        if !$self->is_active;
    $result .= $tsf->render($cleanup_samples);
  }

  return $result;
}

sub render
{
  my $self = shift;
  my %args = @_;

  my $tsf = $self->_tsf;

  my $SR      = $tsf->SAMPLE_RATE;
  my $seconds = $args{seconds} // 0;
  my $samples = ( $seconds * $SR ) || $args{samples} // $SR;

  return $tsf->render($samples);
}

1;
__END__

=encoding utf-8

=head1 NAME

Audio::TinySoundFont - Blah blah blah

=head1 SYNOPSIS

  use Audio::TinySoundFont;

=head1 DESCRIPTION

Audio::TinySoundFont is

=head1 AUTHOR

Jon Gentle E<lt>cpan@atrodo.orgE<gt>

=head1 COPYRIGHT

Copyright 2020- Jon Gentle

=head1 LICENSE

This is free software. You may redistribute copies of it under the terms of the Artistic License 2 as published by The Perl Foundation.

=head1 SEE ALSO

=cut
