package Audio::TinySoundFont::Preset;

use v5.14;
use warnings;
our $VERSION = '0.01';

use autodie;
use Carp;
use Try::Tiny;
use Moo;
use Types::Standard qw/Int Str InstanceOf/;

has _tsf => (
  is       => 'ro',
  isa      => InstanceOf ['Audio::TinySoundFont::XS'],
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
  builder => sub {
    my $self = shift;
    $self->_tsf->get_presetname( $self->index ) // '';
  },
);

sub render
{
  my $self = shift;
  my %args = @_;

  my $tsf = $self->_tsf;

  die "Cannot render a preset when TinySoundFont is active"
      if $tsf->is_active;

  my $SR      = $tsf->SAMPLE_RATE;
  my $seconds = $args{seconds};
  my $samples = ( $seconds * $SR ) || $args{samples} // $SR;
  my $note    = $args{note} // 60;
  my $vel     = $args{vel} // 0.5;

  if ( $vel < 0 || $vel > 1 )
  {
    carp
        qq{Velocity of "$vel" should be between 1 and 0, adjusting to 0..127};
    $vel /= 127;
  }

  warn $samples;
  $tsf->note_on( $self->index, $note, $vel );
  $DB::single = 1;
  my $result = $tsf->render($samples);

  #use Devel::Peek;
  $tsf->note_off( $self->index, $note );
  my $cleanup_samples = 512;
  for ( 1 .. 100 )
  {
    warn length $result;
    last
        if !$tsf->is_active;
    $result .= $tsf->render($cleanup_samples);
  }
  warn length $result;
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
