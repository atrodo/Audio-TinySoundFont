package Audio::TinySoundFont;

use v5.14;
use warnings;
our $VERSION = '0.01';

use autodie;
use Carp;
use Try::Tiny;
use Moo;
use Types::Standard qw/ArrayRef HashRef GlobRef Str Int Bool InstanceOf/;

use Audio::TinySoundFont::XS;
use Audio::TinySoundFont::Preset;

has _tsf => (
  is       => 'ro',
  isa      => InstanceOf ['Audio::TinySoundFont::XS'],
  required => 1,
);

has preset_count => (
  is  => 'lazy',
  isa => Int,
);

has presets => (
  is  => 'lazy',
  isa => HashRef,
);

my %ref_build = (
  '' => sub
  {
    my $file = shift;
    carp qq{File "$file" doesn't exist}
        if !-e $file;
    return try { Audio::TinySoundFont::XS->load_file($file) }
    catch { carp $_ };
  },
);

sub BUILDARGS
{
  my $class = shift;
  my $file  = shift;
  my $args  = Moo::Object::BUILDARGS( $class, @_ );

  my $build_fn = $ref_build{ ref $file };
  carp "Cannot load soundfont file, unknown ref: " . ref($file)
      if !defined $build_fn;
  my $tsf = $build_fn->($file);

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
    $result{$name} = Audio::TinySoundFont::Preset->new( _tsf => $self->_tsf,
      index => $i );
  }

  return \%result;
}

sub preset
{
  my $self = shift;
  my $name = shift;

  my $preset = $self->presets->{$name};

  die qq{Could not find preset "$name"}
      if !defined $preset;

  return $preset;
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
