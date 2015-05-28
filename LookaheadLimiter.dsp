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
declare version   "0.3";
declare copyright "(C) 2014 Bart Brouns";

import ("LookaheadLimiter.lib");


SampleRate = 44100;
//Lookahead and LookaheadPar need a power of 2 as a size
//maxHoldTime      = 4; //                                        = 0.1ms, for looking at the block diagram
//maxHoldTime      = 32; //                                       =
//maxHoldTime      = 128; //                                      = 3ms
//maxHoldTime      = 256; //                                      = 6ms
//maxHoldTime      = 512; //                                      = 12ms, starts to sound OK, 84% cpu
//maxHoldTime      = 1024; //                                     = 23ms, good sound, 185% CPU
//maxHoldTime      = 2048; //                                     = 46ms, even less distortion, but can be less loud, 300% CPU
maxHoldTime        = maxWinSize*nrWin*2;//4096; //                = 92ms
//maxHoldTime      = 4096; //                                     = 92ms
//maxHoldTime      = 8192; //                                     = 186ms
maxWinSize         = int(32*SampleRate/44100);
//maxWinSize       = int(32*SampleRate/44100);
nrWin              = 128;
//nrWin            = 128;
//with maxHoldTime = 1024, having maxAttackTime                   = 512 uses more cpu then maxAttackTime                       = 1024
maxAttackTime      = int(1024*SampleRate/44100):min(maxHoldTime);

//rmsMaxSize = 1024:min(maxHoldTime);
rmsMaxSize = int(512*SampleRate/44100):min(maxHoldTime);

main_group(x) = (hgroup("[1]", x));

distKnobGroup(x)          = main_group(vgroup("[0]distortion control [tooltip: this section controls the amount of distortion, versus the amount of GR]", x));
  inGain                  = distKnobGroup(hslider("[0]input gain [unit:dB]   [tooltip: input gain in dB ", 0, 0, 30, 0.1)) ;
  threshold               = distKnobGroup(hslider("[1]threshold [unit:dB]   [tooltip: maximum output level in dB]", -0.5, -60, 0, 0.1));
  attack                  = distKnobGroup(hslider("[2]attack shape[tooltip: 0 gives a linear attack (slow), 1 a strongly exponential one (fast)]", 1 , 0, 1 , 0.001));
//  release               = distKnobGroup(hslider("[3]lin release[unit:dB/s][tooltip: maximum release rate]", 10, 6, 500 , 1)/SampleRate);
  minRelease              = distKnobGroup(hslider("[3]minimum release time[unit:ms]   [tooltip: minimum time in ms for the GR to go up]",30, 0.1, 500, 0.1)/1000):time_ratio_release;
//  time_ratio_target_rel = distKnobGroup(hslider("[4]release shape", 1, 0.5, 5.0, 0.001));
  // hardcoding link to 1 leads to much longer compilation times, yet similar cpu-usage, while one would expect less cpu usage and maybe shorter compilation time
  link              = distKnobGroup(hslider("[5]stereo link[tooltip: 0 means independent, 1 fully linked]", 1, 0, 1 , 0.001));

dynHoldKnobGroup(x) = main_group(vgroup("[1]dynamic hold [tooltip: the GR will not go up if it has to be back here within the hold time]", x));
  //hardcoding holdTime to maxHoldTime uses more cpu then having a fader!
  maxHoldMs   = maxHoldTime*1000/SampleRate;
  holdTime    = int(dynHoldKnobGroup(hslider("[0]maximum hold time[unit:ms] [tooltip: maximum hold time in ms]", maxHoldMs, 0.1, maxHoldMs ,0.1))/1000*SampleRate/nrWin/2);
  minHoldTime = int(dynHoldKnobGroup(hslider("[1]minimum hold time[unit:ms] [tooltip: minimum hold time in ms]", 30,        0.1, maxHoldMs ,0.1))/1000*SampleRate/nrWin/2);
  dynHold     = dynHoldKnobGroup(hslider("[2]dynHold[tooltip: shorten the hold time when the GR is below AVG]", 0.5, 0, 1 , 0.001))*20;
  dynHoldPow  = dynHoldKnobGroup(hslider("[3]dynHoldPow[tooltip: shape the curve of the hold time]", 2, 0.1, 10 , 0.1));
  dynHoldDiv  = dynHoldKnobGroup(hslider("[4]dynHoldDiv[tooltip: scale the curve of the hold time]", 6, 0.1, 24 , 0.1));


musicRelKnobGroup(x) = main_group(vgroup("[2] musical release [tooltip: this section fine tunes the release to sound musical]", x));
  baserelease        = musicRelKnobGroup(hslider("[0]base release rate[unit:dB/s][tooltip: release rate when the GR is at AVG, in dB/s]", 30, 0.1, 60 , 0.1)/SampleRate);
  transientSpeed     = musicRelKnobGroup(hslider("[1]transient speed[tooltip:  speed up the release when the GR is below AVG ]", 0.5, 0, 1,   0.001));
  antiPump           = musicRelKnobGroup(hslider("[2]anti pump[tooltip: slow down the release when the GR is above AVG ]", 0.5, 0, 1,   0.001));
  attackAVG          = musicRelKnobGroup(time_ratio_attack(hslider("[3] AVG attack [unit:ms]   [tooltip: time in ms for the AVG to go down ]", 1400, 50, 5000, 1)/1000)) ;
  releaseAVG         = musicRelKnobGroup(time_ratio_attack(hslider("[4] AVG release [unit:ms]   [tooltip:  time in ms for the AVG to go up]", 300, 50, 5000, 1)/1000)) ;

  GRmeter_group(x)  = main_group(hgroup("[3] GR [tooltip: gain reduction in dB]", x));
    meter           = GRmeter_group(  _<:(_,(_:min(0):max(-20):( (vbargraph("[unit:dB]", -20, 0))))):attach);
  AVGmeter_group(x) = (main_group(hgroup("[4] AVG [tooltip: average gain reduction in dB]", x)));
    avgMeter        = AVGmeter_group((_<:(_,(_:min(0):max(-20):( (vbargraph("[unit:dB]", -20, 0))))):attach));
  DHmeter_group(x)       = (main_group(hgroup("[5] HoldTime [tooltip: hold time in ms]", x)));
    dhMeter         = DHmeter_group((_<:(_,((_*1000/SampleRate*nrWin*2):min(maxHoldMs):max(0):( (vbargraph("[unit: ms]", 0, maxHoldMs))))):attach));


mymeter    = meter_group(_<:(_, ( (vbargraph("[2]SD[tooltip: slow down amount]", 0, 0.5)))):attach);
//process = stereoGainComputer;
//process = naiveStereoLimiter;
//process = ( 0:seq(i,maxHoldTime,(currentdown(x)@(i):max(lastdown)),_: min ));
//process(x,y) = (((Lookahead(x):releaseEnv(minRelease)),(Lookahead(y):releaseEnv(minRelease))):min)~(+(inGain@maxHoldTime)):meter:db2linear<:(_*x@maxHoldTime,_*y@maxHoldTime);

//(((Lookahead(x):releaseEnv(minRelease)),(Lookahead(y):releaseEnv(minRelease))):min)~(_<:(_,_))+(inGain@maxHoldTime):meter:db2linear<:(_*x@maxHoldTime,_*y@maxHoldTime);
//simpleStereoLimiter;
//process = slidemax(5,8);
//process = minimalStereoLimiter;

/*process(x) =*/
       /*0: seq(i,maxAttackTime,*/
         /*(currentdown(x)@(i+1-maxAttackTime+maxHoldTime))*/
         /**(((i+1)/maxAttackTime))*/
           /*,_: min*/
       /*);*/
/*process =*/
/*(0,_):seq(i,maxAttackTime,*/
  /*(*/
    /*(_,*/
      /*(*/
         /*((_')<:(_,_)):*/
         /*(*/
          /*(_ *(((i+1)/maxAttackTime)))*/
          /*,_*/
         /*)*/
      /*)*/
    /*)*/
    /*:min,_*/
  /*)*/
/*) ;*/

/*process(x) =   pmin(currentdown(x),0,4)*/
    /*with {*/
      /*pmin(del,mini,1) =del', ((del *((maxAttackTime/maxAttackTime))) ,mini : min);*/
      /*pmin(del,mini,k) = del,(((pmin(del@(1),mini,(k-1))):(_*(((maxAttackTime-k+1)/maxAttackTime))),_) : (min));*/
    /*};*/

//process =avgMeter(inGain);
//process(x,y) = (stereoGainComputerHalf(x,y),stereoGainComputerHalf(y,x))~(cross(2));
//(stereoGainComputerHalf(x,y),stereoGainComputerHalf(y,x))~((_,_ <: !,_,_,!),_)
process = stereoLimiter;
//Lookahead(x,lastdown,avgLevel) =


//(((_,(_,((_,_):Lookahead(y)):min)):linearXfade(link)):releaseEnv(minRelease):rateLimit);

//(((_,(_<:_,_)):(Lookahead(x)<:_,_),(_<:_,_)):interleave(2,2));

//(((_,(_,Lookahead(y,prevy,avgLevely):min)):linearXfade(link)):releaseEnv(minRelease):rateLimit);

//GOOD:
//process(x,y,prevy) =
  /*(*/
    /*(((_,(_,((prevy,_):Lookahead(y)):min)):linearXfade(link)):releaseEnv(minRelease):(rateLimit))*/
    /*~(((_<:(_,_)),_):((cross(2):Lookahead(x)<:_,_),_))*/
  /*):(_,!);*/


/*(*/
    /*(((_,(_,(prevy:Lookahead(y,_)):min)):linearXfade(link)):releaseEnv(minRelease):rateLimit)*/
    /*~((Lookahead(x)<:_,_),_)*/
  /*);*/


  /*(*/
    /*(((_,(_,((prevy:Lookahead(y),_):(_,!)):min)):linearXfade(link)):releaseEnv(minRelease):rateLimit)*/
    /*~((Lookahead(x)<:_,_),_):(_,!)*/
  /*);*/

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
