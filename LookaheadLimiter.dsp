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


SampleRate = 44100;
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
maxWinSize = int(32*SampleRate/44100);
nrWin = 128;
//with maxHoldTime = 1024, having maxAttackTime = 512 uses more cpu then maxAttackTime = 1024
maxAttackTime = int(24*SampleRate/44100):min(maxHoldTime);

//rmsMaxSize = 1024:min(maxHoldTime);
rmsMaxSize = int(512*SampleRate/44100):min(maxHoldTime);

main_group(x)  = (hgroup("[1]", x));

knob_group1(x)   = main_group(vgroup("[0] distortion control [tooltip: this section controls the amount of distortion, versus the amount of GR]", x));
  threshold   = knob_group1(hslider("[0]threshold [unit:dB]   [tooltip: maximum output level in dB]", -0.5, -60, 0, 0.1));
  attack      = knob_group1(hslider("[1]attack shape[tooltip: 0 gives a linear attack (slow), 1 a strongly exponential one (fast)]", 1 , 0, 1 , 0.001));
  //hardcoding holdTime to maxHoldTime uses more cpu then having a fader!
  maxHoldMs = maxHoldTime*1000/SampleRate;
  holdTime    = int(knob_group1(hslider("[2]maximum hold time[unit:ms] [tooltip: maximum hold time in ms]", maxHoldMs, 0.1, maxHoldMs ,0.1))/1000*SampleRate/nrWin/2);
  release     = knob_group1(hslider("[3]lin release[unit:dB/s][tooltip: maximum release rate]", 10, 6, 500 , 1)/SampleRate);
  minRelease  = knob_group1(hslider("[4]minimum release time[unit:ms]   [tooltip: minimum time in ms for the GR to go up]",10, 0.1, 500, 0.1)/1000):time_ratio_release;
  time_ratio_target_rel =  knob_group1(hslider("[5]release shape", 1, 0.5, 5.0, 0.001));
  // hardcoding link to 1 leads to much longer compilation times, yet similar cpu-usage, while one would expect less cpu usage and maybe shorter compilation time
  link  = knob_group1(hslider("[6]stereo link[tooltip: 0 means independent, 1 fully linked]", 1, 0, 1 , 0.001));
  dynHold =  knob_group1(hslider("[7]dynHold[tooltip:]", 0, 0, 100 , 0.1))*100;
  dynHoldPow =  knob_group1(hslider("[8]dynHoldPow[tooltip:]", 0, 0, 100 , 0.1));
  dynHoldDiv =  knob_group1(hslider("[9]dynHoldDiv[tooltip:]", 0, 0, 100 , 0.1));

knob_group2(x)   = main_group(vgroup("[1] musical release [tooltip: this section fine tunes the release to sound musical]", x));
  baserelease   = knob_group2(hslider("[0]base release rate[unit:dB/s][tooltip: release rate when the GR is at AVG, in dB/s]", 15, 0.1, 60 , 0.1)/SampleRate);
  transientSpeed     = knob_group2(hslider("[1]transient speed[tooltip:  speed up the release when the GR is below AVG ]", 0.25, 0, 1,   0.001));
  antiPump     = knob_group2(hslider("[2]anti pump[tooltip: slow down the release when the GR is above AVG ]", 0.5, 0, 1,   0.001));
  attackAVG      = knob_group2(time_ratio_attack(hslider("[3] AVG attack [unit:ms]   [tooltip: time in ms for the AVG to go down ]", 1400, 50, 5000, 1)/1000)) ;
  releaseAVG       = knob_group2(time_ratio_attack(hslider("[4] AVG release [unit:ms]   [tooltip:  time in ms for the AVG to go up]", 300, 50, 5000, 1)/1000)) ;
  offset       = knob_group2((hslider("[5] offset [unit:dB]   [tooltip:  ", 0, 0, 30, 0.1))) ;

  GRmeter_group(x)  =main_group(hgroup("[2] GR [tooltip: gain reduction in dB]", x));
    meter    =  GRmeter_group(_<:(_,(_:min(0):max(-20):( (vbargraph("[0][unit:dB]", -20, 0))))):attach);
  AVGmeter_group(x)  = (main_group(hgroup("[3] AVG [tooltip: average gain reduction in dB]", x)));
    avgMeter    = AVGmeter_group((_<:(_,(_:min(0):max(-20):( (vbargraph("[1][unit:dB]", -20, 0))))):attach));


mymeter    = meter_group(_<:(_, ( (vbargraph("[2]SD[tooltip: slow down amount]", 0, 0.5)))):attach);
//process = limiter ,limiter;
//process = naiveStereoLimiter;
//process = ( 0:seq(i,maxHoldTime,(currentdown(x)@(i):max(lastdown)),_: min ));
//process = simpleStereoLimiter;
process = minimalStereoLimiter;
//process =avgMeter(offset);
//process = stereoLimiter;
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
