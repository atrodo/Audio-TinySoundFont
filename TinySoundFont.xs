#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define TSF_IMPLEMENTATION
#define TSF_STATIC
#include "TinySoundFont/tsf.h"

typedef tsf* Audio__TinySoundFont__XS;

#define SAMPLE_RATE 44100

MODULE = Audio::TinySoundFont  PACKAGE = Audio::TinySoundFont::XS

BOOT:
{
    HV *stash = gv_stashpv("Audio::TinySoundFont::XS", 0);

    newCONSTSUB(stash, "SAMPLE_RATE",        newSViv(SAMPLE_RATE));
    newCONSTSUB(stash, "MONO",               newSViv(TSF_MONO));
    newCONSTSUB(stash, "STEREO_INTERLEAVED", newSViv(TSF_STEREO_INTERLEAVED));
    newCONSTSUB(stash, "STEREO_UNWEAVED",    newSViv(TSF_STEREO_UNWEAVED));
}

Audio::TinySoundFont::XS
load_file(CLASS, filename)
    SV *CLASS = NO_INIT
    const char* filename
  CODE:
    RETVAL = tsf_load_filename(filename);
    if ( RETVAL == NULL )
    {
      croak("Unable to loadfile: %s\n", filename);
    }
    tsf_set_output(RETVAL, TSF_MONO, SAMPLE_RATE, -10);
  OUTPUT:
    RETVAL

int
presetcount(self)
    Audio::TinySoundFont::XS self
  CODE:
    RETVAL = tsf_get_presetcount(self);
  OUTPUT:
    RETVAL

const char*
get_presetname(self, preset_idx)
    Audio::TinySoundFont::XS self
    int preset_idx
  CODE:
    RETVAL = tsf_get_presetname(self, preset_idx);
  OUTPUT:
    RETVAL

int
is_active(self)
    Audio::TinySoundFont::XS self
  CODE:
    RETVAL = tsf_active_voice_count(self);
  OUTPUT:
    RETVAL

void
set_volume(self, global_gain);
    Audio::TinySoundFont::XS self
    float global_gain
  CODE:
    tsf_set_volume(self, global_gain);

void
note_on(self, preset_idx, note, velocity)
    Audio::TinySoundFont::XS self
    int preset_idx
    int note
    float velocity
  CODE:
    tsf_note_on(self, preset_idx, note, velocity);

void
note_off(self, preset_idx, note)
    Audio::TinySoundFont::XS self
    int preset_idx
    int note
  CODE:
    tsf_note_off(self, preset_idx, note);

SV *
render(self, samples)
    Audio::TinySoundFont::XS self
    int samples
  CODE:
    int slen = samples * sizeof(short);
    RETVAL = newSV(slen);
    SvCUR_set(RETVAL,  slen);
    SvPOK_only(RETVAL);
    STRLEN len;
    short* buffer;
    buffer = (short *)SvPVX(RETVAL);
    tsf_render_short(self, buffer, samples, 0);
    *(SvEND(RETVAL)) = '\0';
  OUTPUT:
    RETVAL
