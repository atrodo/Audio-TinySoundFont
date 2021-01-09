package Audio::TinySoundFont::Builder;

use v5.14;
use warnings;
our $VERSION = '0.01';

use Carp;

use Moo;
use Types::Standard qw/ArrayRef HashRef InstanceOf/;

has soundfont => (
  is       => 'ro',
  isa      => InstanceOf ['Audio::TinySoundFont'],
  required => 1,
);

has play_script => (
  is      => 'rwp',
  isa     => ArrayRef,
  default => sub { [] },
  coerce  => \&_coerce_play_script,
);

*SAMPLE_RATE = \&Audio::TinySoundFont::XS::SAMPLE_RATE;

sub _coerce_play_script
{
  my $new_script = shift;

  croak "play_script requires an ArrayRef"
      if ref $new_script ne 'ARRAY';

  my @result;
  foreach my $item (@$new_script)
  {
    croak "Script items must be a HashRef, not: " . ref $item
        if ref $item ne 'HASH';

    push @result, {
      in_seconds => ( $item->{in_seconds} // 1 ) + 0,
      at         => ( $item->{at}         // 0 ) + 0,
      for        => ( $item->{for}        // 1 ) + 0,
      note       => ( $item->{note}       // 60 ) + 0,
      vel        => ( $item->{vel}        // 0.5 ) + 0,
      preset     => ( $item->{preset}     // '' ),
    };
  }

  return \@result;
}

sub clear
{
  my $self = shift;

  $self->set( [] );

  return;
}

sub set
{
  my $self   = shift;
  my $script = shift;

  $self->_set_play_script($script);

  return;
}

sub add
{
  my $self   = shift;
  my $script = shift;

  croak "add requires an ArrayRef"
      if ref $script ne 'ARRAY';

  my $old_script = $self->play_script;
  $self->_set_play_script( [ @$old_script, @$script ] );

  return;
}

sub render
{
  my $self = shift;
  my %args = @_;

  my $vol = $args{volume} // $self->soundfont->db_to_vol( $args{db} );

  my $old_vol;
  if ( defined $vol )
  {
    $old_vol = $self->soundfont->volume;
    $self->soundfont->volume($vol);
  }

  my $script = $self->play_script;
  my $SR     = $self->SAMPLE_RATE;
  my $result = '';

  croak "Cannot process play_script when TinySoundFont is active"
      if $self->soundfont->is_active;

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
    push @insrs, [ int $at, 'note_on',  @$item{qw/preset note vel/} ];
    push @insrs, [ int $to, 'note_off', @$item{qw/preset note vel/} ];
  }

  @insrs = sort { $a->[0] <=> $b->[0] } @insrs;

  my $current_ts = 0;
  my $soundfont  = $self->soundfont;
  my $tsf        = $soundfont->_tsf;
  foreach my $i ( 0 .. $#insrs )
  {
    my ( $ts, $fn, @args ) = @{ $insrs[$i] };
    $result .= $tsf->render( $ts - $current_ts );
    $soundfont->$fn(@args);
    $current_ts = $ts;
  }

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

sub render_unpack
{
  my $self = shift;

  return unpack('s<*', $self->render(@_) );
}

1;
__END__

=encoding utf-8

=head1 NAME

Audio::TinySoundFont -

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
