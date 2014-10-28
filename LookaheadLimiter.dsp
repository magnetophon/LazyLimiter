declare name      "LookAheadLimiter";
declare author    "Bart Brouns";
declare version   "0.1";
declare copyright "(C) 2014 Bart Brouns";

import ("LookaheadLimiter.lib");

pd = maxPredelay;

MAX_flt = fconstant(int FLT_MAX, <float.h>);
//FLT_MAX normal
//DBL_MAX -double
//LDBL_MAX -quad
predelay = hslider("[0]predelay[tooltip: ]", maxPredelay , 1, maxPredelay , 1);
//predelay = hslider("[0]predelay[tooltip: ]", 1, 0.0, 24, 0.001)*SR*0.001:int:max(1);
//predelay = 0.5*SR;
//maximumdown needs a power of 2 as a size
//maxPredelay = 4; // = 0.1ms
//maxPredelay = 128; // = 3ms
//maxPredelay = 256; // = 6ms   //no overs till here, independent of -vec compile option
//maxPredelay = 512; // = 12ms //no overs till here, but only without -vec or with both  -vec and -lv 1
maxPredelay = 1024; // = 23ms //always gives overs with par lookahead, never gives overs with seq lookahead. Unfortunately, seq @ 1024 doesn't like ratelimiter: as soon as it is faded in, we get silence.
// seq @ < 1024 works fine...
//maxPredelay = 2048; // = 46ms
//maxPredelay = 8192; // = 186ms

main_group(x)  = (hgroup("[1]", x));

meter_group(x)  = main_group(hgroup("[1]", x));
knob_group(x)   = main_group(hgroup("[2]", x));

detector_group(x)  = knob_group(vgroup("[0]detector", x));
post_group(x)      = knob_group(vgroup("[1]", x));
ratelimit_group(x) = knob_group(vgroup("[2]ratelimit", x));

shape_group(x)      = post_group(vgroup("[0]shape", x));
out_group(x)        = post_group(vgroup("[2]", x));

envelop = abs : max ~ -(100.0/SR) ;


meter = meter_group(_<:(_, (linear2db :(vbargraph("[1][unit:dB][tooltip: input level in dB]", -60, 0)))):attach);
mtr = meter_group(_<:(_, ( (vbargraph("punch", 0, 128)))):attach);

threshold     = detector_group(hslider("[4] Threshold [unit:dB]   [tooltip: When the signal level exceeds the Threshold (in dB), its level is compressed according to the Ratio]", -12, -60, 0, 0.1));

limPunch      = shape_group(hslider("[1]punch[tooltip: ]", 0 , 0, 1 , 0.001)):punchScale:mtr;
ratelimit      = ratelimit_group(hslider("[0]ratelimit amount[tooltip: ]", 0, 0, 1 , 0.001));
maxRateDecay   = ratelimit_group(hslider("[2]max decay[unit:dB/s][tooltip: ]", 64, 6, 500 , 1)/SR);
stayDown       = shape_group(hslider("[2]stayDown[tooltip: ]", 0.811, 0, 1 , 0.001));

process = limiter ,limiter;
