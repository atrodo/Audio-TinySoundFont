#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define TSF_IMPLEMENTATION
#include "tsf.h"

MODULE = Audio::TinySoundFont  PACKAGE = Audio::TinySoundFont::XS

