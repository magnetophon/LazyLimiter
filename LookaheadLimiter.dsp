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

/*some building blocks where taken from or inspired by compressor-basics.dsp by Sampo Savolainen*/

declare name      "LookAheadLimiter";
declare author    "Bart Brouns";
declare version   "0.2";
declare copyright "(C) 2014 Bart Brouns";

import ("LookaheadLimiter.lib");

//Lookahead and LookaheadPar need a power of 2 as a size
//maxHoldTime = 4; // = 0.1ms, for looking at the block diagram
//maxHoldTime = 32; // =
//maxHoldTime = 128; // = 3ms
//maxHoldTime = 256; // = 6ms
//maxHoldTime = 512; // = 12ms, starts to sound OK, 84% cpu
//maxHoldTime = 1024; // = 23ms, good sound, 185% CPU
//maxHoldTime = 2048; // = 46ms, even less distortion, but can be less loud, 300% CPU
maxHoldTime = maxWinSize*nrWin*2;//4096; // = 92ms
//maxHoldTime = 4096; // = 92ms
//maxHoldTime = 8192; // = 186ms
maxWinSize = 32;
nrWin = 64;
//with maxHoldTime = 1024, having maxAttackTime = 512 uses more cpu then maxAttackTime = 1024
maxAttackTime = 1024:min(maxHoldTime);

//rmsMaxSize = 1024:min(maxHoldTime);
rmsMaxSize = 512:min(maxHoldTime);

main_group(x)  = (hgroup("[1]", x));

knob_group(x)   = main_group(vgroup("[0]", x));
meter_group(x)  = main_group(hgroup("[1]", x));

threshold   = knob_group(hslider("[0]threshold [unit:dB]   [tooltip: maximum output level]", -0.5, -60, 0, 0.1));
attack      = knob_group(hslider("[1]attack shape[tooltip: attack speed]", 1 , 0, 1 , 0.001));
//hardcoding holdTime to maxHoldTime uses more cpu then having a fader!
holdTime    = int(knob_group(hslider("[2]hold time[tooltip: maximum hold time]", maxWinSize, 1, maxWinSize , 1)));
release     = knob_group(hslider("[3]lin release[unit:dB/s][tooltip: maximum release rate]", 10, 6, 500 , 1)/SR);
logRelease  = knob_group(hslider("[4]release time[unit:ms]   [tooltip: Time constant in ms (1/e smoothing time) for the compression gain to approach (exponentially) a new higher target level (the compression 'releasing')]",10, 0.1, 500, 0.1)/1000):time_ratio_release;
time_ratio_target_rel =  knob_group(hslider("[5]release shape", 1, 0.5, 5.0, 0.001));
// hardcoding link to 1 leads to much longer compilation times, yet similar cpu-usage, while one would expect less cpu usage and maybe shorter compilation time
link  = knob_group(hslider("[6]stereo link[tooltip: ]", 1, 0, 1 , 0.001));


meter    = meter_group(_<:(_, ( (vbargraph("[0]GR[unit:dB][tooltip: gain reduction in dB]", -60, 0)))):attach);
avgMeter    = meter_group(_<:(_, ( (vbargraph("[1]avg[unit:dB][tooltip: avg level in dB]", -60, 0)))):attach);
mymeter    = meter_group(_<:(_, ( (vbargraph("[2]SD[tooltip: slow down amount]", 0, 0.5)))):attach);
//process = limiter ,limiter;
//process = naiveStereoLimiter;
//process = ( 0:seq(i,maxHoldTime,(currentdown(x)@(i):max(lastdown)),_: min ));
//process = simpleStereoLimiter;
process = stereoLimiter;
           //process(x)= rdtable(maxAttackTime, (5)  ,int(x*maxAttackTime));
           //process(x)= rdtable(int(maxAttackTime), tanh((6/maxAttackTime):pow(1:attackScale)),int(x*maxAttackTime));
           /*process(x)= rdtable(maxAttackTime, ( tanh((6/maxAttackTime):pow(attack:attackScale)*(attack*5+.1))/tanh(attack*5+.1)),int(x*maxAttackTime))*/
             /*with { attack = 1; };*/
           /*attackScale(x) = (x+1):pow(7);*/
//process = rateLimiter;
//process = SMOOTH(3,4);
/*process(x) =  0:seq(i,maxHoldTime,*/
       /*(((i+1)>(maxHoldTime-holdTime))*(currentdown(x)@(i):max(lastdown))),_: min */
             /*)*/
             /*with { maxHoldTime = 1024; holdTime = 4; lastdown = noise;};*/
