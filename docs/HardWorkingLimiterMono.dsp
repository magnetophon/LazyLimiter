/*
 *  Copyright (C) 2014 Bart Brouns
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; version 2 of the License.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 */

/*some building blocks where taken from or inspired on compressor-basics.dsp by Sampo Savolainen*/

declare name      "LookAheadLimiterMono";
declare author    "Bart Brouns";
declare version   "0.1";
declare copyright "(C) 2014 Bart Brouns";

import ("LookaheadLimiter.lib");

//LookaheadPar needs a power of 2 as a size
//the following maxHoldTime related bug-comments only manifest with another implementation of "currentdown"
//maxHoldTime = 4; // = 0.1ms
//maxHoldTime = 128; // = 3ms
//maxHoldTime = 256; // = 6ms   //no overs till here, independent of -vec compile option
//maxHoldTime = 512; // = 12ms //no overs till here, but only without -vec or with both  -vec and -lv 1
maxHoldTime = 1024; // = 23ms //always gives overs with par lookahead, never gives overs with seq lookahead. Unfortunately, seq @ 1024 doesn't like ratelimiter: as soon as it is faded in, we get silence.
// seq @ < 1024 works fine...
//maxHoldTime = 2048; // = 46ms
//maxHoldTime = 8192; // = 186ms

//with maxHoldTime = 1024, having maxAttackTime = 512 uses more cpu then maxAttackTime = 1024
maxAttackTime = 1024:min(maxHoldTime);

rmsMaxSize = 4096;

time_ratio_target = 1.5; 

//time_ratio_target_atk = hslider("attack time ratio", 1.5, 0.2, 10.0, 0.1); 
time_ratio_target_atk = 8.0;
//time_ratio_target_rel = 4.0; // this could be too slow
//time_ratio_target_rel = 1.5;

main_group(x)  = (hgroup("[1]", x));

meter_group(x)  = main_group(hgroup("[1]", x));
knob_group(x)   = main_group(vgroup("[2]", x));

detector_group(x)  = knob_group(vgroup("[0]detector", x));
post_group(x)      = knob_group(vgroup("[1]", x));
ratelimit_group(x) = knob_group(vgroup("[2]ratelimit", x));

shape_group(x)      = post_group(vgroup("[0]shape", x));
out_group(x)        = post_group(vgroup("[2]", x));

envelop = abs : max ~ -(100.0/ma.SR) ;

meter    = meter_group(_<:(_, ( (vbargraph("[1]GR[unit:dB][tooltip: gain reduction in dB]", -60, 0)))):attach);
mtr      = meter_group(_<:(_, ( (vbargraph("punch", 0, 128)))):attach);
mymeter  = meter_group(_<:(_, ( (vbargraph("[1][unit:dB][tooltip: input level in dB]", 0, 144)))):attach);

threshold   = knob_group(hslider("[0]threshold [unit:dB]   [tooltip: maximum output level]", -12, -60, 0, 0.1));
attack      = knob_group(hslider("[1]attack shape[tooltip: attack speed]", 0.841 , 0, 1 , 0.001));
//hardcoding holdTime to maxHoldTime uses more cpu then having a fader!
holdTime    = knob_group(hslider("[2]hold time[tooltip: maximum hold time]", maxHoldTime, 0, maxHoldTime , 1));
release     = knob_group(hslider("[3]lin release[unit:dB/s][tooltip: maximum release rate]", 113, 6, 500 , 1)/ma.SR);
logRelease  = knob_group(hslider("[4]release time[unit:ms]   [tooltip: Time constant in ms (1/e smoothing time) for the compression gain to approach (exponentially) a new higher target level (the compression 'releasing')]",150, 0.1, 500, 0.1)/1000):time_ratio_release;
time_ratio_target_rel =  knob_group(hslider("[5]release shape", 0.5, 0.2, 5.0, 0.1));
// hardcoding link to 1 leads to much longer compilation times, yet similar cpu-usage, while one would expect less cpu usage and maybe shorter compilation time
link  = knob_group(hslider("[6]stereo link[tooltip: ]", 1, 0, 1 , 0.001));

ratelimit  = knob_group(hslider("[0]ratelimit amount[tooltip: ]", 1, 0, 1 , 0.001));

mult           = ratelimit_group(hslider("[3]mult[tooltip: ]", 1 , 0.1,20, 0.1));

IMattack        = ratelimit_group(time_ratio_attack(hslider("[6] Attack [unit:ms]   [tooltip: Time constant in ms (1/e smoothing time) for the compression gain to approach (exponentially) a new lower target level (the compression `kicking in')]", 23.7, 0.1, 500, 0.1)/1000)) ;
IMrelease       = ratelimit_group(time_ratio_release(hslider("[7] Release [unit:ms]   [tooltip: Time constant in ms (1/e smoothing time) for the compression gain to approach (exponentially) a new higher target level (the compression 'releasing')]",0.1, 0.1, 2000, 0.1)/1000));

maxChange = hslider("[0]maxChange[tooltip: ]", 84 , 1, 144 , 1);
decayPower     = ratelimit_group(hslider("[4]decayPower[tooltip: ]", 10, 0, 10 , 0.001));
decayMult      = ratelimit_group(hslider("[3]decayMult[tooltip: ]", 200 , 0,500, 1))*10;

IMpower        = ratelimit_group(hslider("[1]IMpower[tooltip: ]", -64 , -128, 0 , 0.001)):limPowerScale;
IM_size        = ratelimit_group(hslider("[5]IM_size[tooltip: ]",108, 1,   rmsMaxSize,   1)*44100/ma.SR); //0.0005 * min(192000.0, max(22050.0, ma.SR));

process = limiter;
//process = naiveStereoLimiter;
//process = simpleStereoLimiter;
//process = stereoLimiter;
