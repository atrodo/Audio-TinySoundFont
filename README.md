# NAME

Audio::TinySoundFont - Interface to TinySoundFont, a "SoundFont2 synthesizer library in a single C/C++ file"

# SYNOPSIS

    use Audio::TinySoundFont;
    my $tsf = Audio::TinySoundFont->new('soundfont.sf2');
    $tsf->note_on( 'Clarinet', 60, 1.0 );
    my $samples = $tsf->render( seconds => 5 );
    my $preset = $tsf->preset('Clarinet');
    $tsf->note_off( $preset, 60 );
    $samples .= $tsf->render( seconds => 5 );
    
    # Using the Preset object
    my $preset = $tsf->preset('Clarinet');
    my $samples = $preset->render(
      seconds => 5,
      note => 60,
      vel => 0.7,
      volume => .3,
    );
    
    # Using the Builder object
    my $builder = $tsf->new_builder(
      [
        {
          preset => 'Clarinet',
          note   => 59,
          at     => 0,
          for    => 2,
        },
      ]
    );
    $builder->add(
      [
        {
          preset     => $preset,
          note       => 60,
          at         => 44100,
          for        => 44100 * 2,
          in_seconds => 0,
        },
      ]
    );
    my $samples = $builder->render;

# DESCRIPTION

Audio::TinySoundFont is a wrapper around [TinySoundFont](https://github.com/schellingb/TinySoundFont),
a "SoundFont2 synthesizer library in a single C/C++ file". This allows you to
load a SoundFont file and synthesize samples from it.

# CONSTRUCTOR

## new

    my $tsf = Audio::TinySoundFont->new($soundfont_file, %attributes)

Construct a new Audio::TinySoundFont object using the provided `$soundfont_file`
file. It can be a filename, a file handle, or a string reference to the contents
of a SoundFont.

### Attributes

- volume

    Set the initial, global volume. This is a floating point number between 0.0 and
    1.0. The higher the number, the louder the output samples.

# METHODS

## volume

    my $volume = $tsf->volume;
    $tsf->volume( 0.5 );

Get or set the current global volume. This is a floating point number between
0.0 and 1.0. The higher the number, the louder the output samples.

## preset\_count

    my $count = $tsf->preset_count;

The number of presets available in the SoundFont.

## presets

    my %presets = %{ $tsf->presets }

A HashRef of all of the presets in the SoundFont. The key is the name of the
preset and the value is the [Audio::TinySoundFont::Preset](https://metacpan.org/pod/Audio%3A%3ATinySoundFont%3A%3APreset) object for that
preset.

## preset

    my $preset = $tsf->preset('Clarinet');

Get a [Audio::TinySoundFont::Preset](https://metacpan.org/pod/Audio%3A%3ATinySoundFont%3A%3APreset) object by name. This will croak if the
preset name is not found.

## preset\_index

    my $preset = $tsf->preset_index($index);

Get an [Audio::TinySoundFont::Preset](https://metacpan.org/pod/Audio%3A%3ATinySoundFont%3A%3APreset) object by index in the SoundFont. This
will croak if the index is out of range. Note, this will return a different
object than ["preset"](#preset) will, which will return the object from [presets](https://metacpan.org/pod/presets).

## SAMPLE\_RATE

    my $sample_rate = $tsf->SAMPLE_RATE

Returns the sample rate that TinySoundFont is operating on, expressed as hertz
or samples per second. This is currently static and is 44\_100;

## new\_builder

    my $builder = $tsf->new_builder

Create a new [Audio::TinySoundFont::Builder](https://metacpan.org/pod/Audio%3A%3ATinySoundFont%3A%3ABuilder) object. This can be used to
generate a single sample from a script of what notes to play when.

## active\_voices

    my $count = $tsf->active_voices;

Returns the number of currently active voices that TinySoundFont is rendering.
Generally speaking, each ["note\_on"](#note_on) will make one or more voices active.

## is\_active

    my $bool = $tsf->is_active

Returns if TinySoundFont currently has active voices and will output audio
during render.

## note\_on

    $tsf->note_on($preset, $note, $velocity);

Turns a note on for a Preset. `$preset` can either be a
[Audio::TinySoundFont::Preset](https://metacpan.org/pod/Audio%3A%3ATinySoundFont%3A%3APreset) object or the name of a Preset. Both `$note`
and `$velocity` are optional. `$note` is a MIDI note between 0 and 127, with
60 being middle C and the default if it is not given. `$velocity` is a floating
point number between 0.0 and 1.0 with the default being 0.5.

## note\_off

    $tsf->note_off($preset, $note);

Turns a note off for a Preset. `$preset` can either be a
[Audio::TinySoundFont::Preset](https://metacpan.org/pod/Audio%3A%3ATinySoundFont%3A%3APreset) object or the name of a Preset. `$note` is
optional and is the same MIDI note given on ["note\_on"](#note_on). The default is 60.
This will not immediately stop a note from playing, it will begin the note's
release phase.

## render

    my $samples = $tsf->render( seconds => 5 );
    my $samples = $tsf->render( samples => 44_100 );

Returns a string of 16-bit, little endian sound samples using TinySoundFont of
the specified length. The result can be unpacked using `unpack("s<*")` or you
can call ["render\_unpack"](#render_unpack) function to get an array instead. This will return
the exact number of samples requested; calling ["render"](#render) 5 times at 1 second
each is identical to calling ["render"](#render) once for 5 seconds.

- seconds

    This sets how many samples to generate in terms of seconds. The default is 1
    second. If both ["seconds"](#seconds) and ["samples"](#samples) are given, seconds will be used.

- samples

    This sets how many samples to generate in terms of seconds. The default is
    ["SAMPLE\_RATE"](#sample_rate). If both ["seconds"](#seconds) and ["samples"](#samples) are given, seconds will
    be used.

## render\_unpack

    my @samples = $tsf->render_unpack(%options);

Returns an array of of 16-bit sound samples using TinySoundFont. All of the
options are identical to ["render"](#render).

## db\_to\_vol

    my $volume = $tsf->db_to_vol(-10);

Convert from dB to a floating point volume. The dB is expressed as a number
between -100 and 0, and will map logarithmically to 0.0 to 1.0.

# Terminology

The SoundFount terminology can get confusing at times, so I've included a quick
reference to help make sense of these.

- Terminology used directly in Audio::TinySoundFont

    To be able to use Audio::TinySoundFont, you will need to know a couple simple
    terms. They are likely easy to infer, but they are here so that their meaning
    is explicit instead of implicit.

    - SoundFont

        Sometimes referred to as SoundFont2, this is a file format designed to store and
        exchange synthesizer information. This includes the audio samples to create
        the audio, how to generate and modify the samples to sound as expected, and
        generally how to produce audio that the SoundFont creator wanted.

    - Preset

        A Preset is the largest usable building block in a SoundFont and generally
        represents a single instrument. If you've ever sat down to an electric keyboard
        and selected "Electric Guitar", "Violin" or "Synth", you are selecting the
        equivalent of a SoundFont preset.

- Terminology used when talking about SoundFonts

    Reading the entire SoundFont2 specification can be daunting. In short, it is a
    [RIFF](https://en.wikipedia.org/wiki/Resource_Interchange_File_Format) file that
    primarily holds 9 types of data, or "sub-chunks". All of this data ultimately
    describes a Preset that is used in constructing audio by TinySoundFont. It is
    not required to understand these to use Audio::TinySoundFont and will not be
    used in the rest of the documentation.

    - PHDR/PBAG (Preset)

        These are the two sections that describe a Preset. A PHDR record describes a
        Preset like the name, preset number and bank number. The PBAG contains what are
        called Preset Zones which lists the generators and modulators to use for a
        specific preset given a range of notes and velocity. One of those generators is
        which Instrument to use, which has its own set of generators and modulators.

    - INST/IBAT (Instrument)

        An instrument is very similar in structure to a Preset, but provides a layer
        of indirection between the raw samples and the presets. A single Instrument
        can be used in multiple Presets, for instance a single Guitar Instrument can be
        used for a regular guitar as well one with extra reverb.
        These two sections serve the same function as the Preset sections. A INST
        describes an Instrument and the PBAG contains Instrument Zones which lists the
        generators and modulators to use for a given range of notes and velocities. One
        of the generators is the sample to use for this Instrument.

    - PGEN
    - PMOD
    - IGEN
    - IMOD

        Each preset and instrument is composed of one or more generators and modulators.
        The PGEN and PMOD sections are used to construct the Preset Zones, likewise the
        IGEN and IMOD sections are used to construct Instrument Zones.
        They describe a single aspect of how to construct the audio samples, for
        instance adding a low-pass filter or reverb. Some are only available for a
        preset, like what Instrument to use, and some are only available to Instruments
        like what Sample to use.

        Note: TinySoundFont does not currently process modulators.

    - SHDR (Samples)

        This section describes the actual audio samples to be used, including a name,
        the length, the original pitch, pitch correction, and looping configuration.
        The actual audio samples are stored in a different RIFF chunk, but this
        contains the references into that chunk about where to find the data.

# AUTHOR

Jon Gentle <cpan@atrodo.org>

# COPYRIGHT

Copyright 2020- Jon Gentle

# LICENSE

This is free software. You may redistribute copies of it under the terms of the Artistic License 2 as published by The Perl Foundation.

# SEE ALSO

[Audio::TinySoundFont::Preset](https://metacpan.org/pod/Audio%3A%3ATinySoundFont%3A%3APreset), [Audio::TinySoundFont::Builder](https://metacpan.org/pod/Audio%3A%3ATinySoundFont%3A%3ABuilder), [TinySoundFont](https://github.com/schellingb/TinySoundFont)
