package Audio::TinySoundFont::Preset;

use v5.14;
use warnings;
our $VERSION = '0.01';

use autodie;
use Carp;
use Try::Tiny;
use Moo;
use Types::Standard qw/Int Str InstanceOf/;

has soundfont => (
  is       => 'ro',
  isa      => InstanceOf ['Audio::TinySoundFont'],
  required => 1,
);

has index => (
  is       => 'ro',
  isa      => Int,
  required => 1,
);

has name => (
  is      => 'ro',
  isa     => Str,
  lazy => 1,
  builder => sub {
    my $self = shift;
    $self->soundfont->_tsf->get_presetname( $self->index ) // '';
  },
);

sub render
{
  my $self = shift;
  my %args = @_;

  my $tsf = $self->soundfont->_tsf;

  croak "Cannot render a preset when TinySoundFont is active"
      if $tsf->active_voices;

  my $SR      = $tsf->SAMPLE_RATE;
  my $seconds = $args{seconds} // 0;
  my $samples = ( $seconds * $SR ) || $args{samples} // $SR;
  my $note    = $args{note} // 60;
  my $vel     = $args{vel} // 0.5;
  my $vol     = $args{volume};

  if ( !defined $vol && defined $args{db} )
  {
    # Volume is a float 0.0-1.0, db is in dB -100..0, so adjust it to a float
    my $db
        = $args{db} > 0    ? 0
        : $args{db} < -100 ? -100
        :                    $args{db};
    $vol = 10**( $db / 20 );
  }

  my $old_vol;
  if ( defined $vol )
  {
    $old_vol = $self->soundfont->volume;
    $self->soundfont->volume($vol);
  }

  my $vel_msg = qq{Velocity of "$vel" should be between 0 and 1};
  if ( $vel < 0 )
  {
    carp qq{$vel_msg, setting to 0};
    $vel = 0;
  }

  if ( $vel > 1 )
  {
    carp qq{$vel_msg, setting to 1};
    $vel = 1;
  }

  my $note_msg = qq{Note "$note" should be between 0 and 127};
  if ( $note < 0 )
  {
    carp qq{$note_msg, setting to 0};
    $note = 0;
  }

  if ( $note > 127 )
  {
    carp qq{$note_msg, setting to 127};
    $note = 127;
  }

  $tsf->note_on( $self->index, $note, $vel );

  my $result = $tsf->render($samples);
  $tsf->note_off( $self->index, $note );

  my $cleanup_samples = 4096;
  for ( 1 .. 256 )
  {
    last
        if !$tsf->active_voices;
    $result .= $tsf->render($cleanup_samples);
  }

  if ( defined $old_vol )
  {
    $self->soundfont->volume($old_vol);
  }
  return $result;
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
