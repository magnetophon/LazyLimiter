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

declare name      "LazyLimiter";
declare author    "Bart Brouns";
declare version   "0.3.2";


declare copyright "(C) 2014 Bart Brouns";

import ("GUI.lib");
import ("LazyLimiter.lib");

//process = stereoGainComputer;
//process = naiveStereoLimiter;
//process = ( 0:seq(i,maxHoldTime,(currentdown(x)@(i):max(lastdown)),_: min ));
//process(x,y) = (((Lookahead(x):releaseEnv(minRelease)),(Lookahead(y):releaseEnv(minRelease))):min)~(+(inGain@maxHoldTime)):meter:ba.db2linear<:(_*x@maxHoldTime,_*y@maxHoldTime);

//(((Lookahead(x):releaseEnv(minRelease)),(Lookahead(y):releaseEnv(minRelease))):min)~(_<:(_,_))+(inGain@maxHoldTime):meter:ba.db2linear<:(_*x@maxHoldTime,_*y@maxHoldTime);
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
//process(x,y) = (stereoGainComputerHalf(x,y),stereoGainComputerHalf(y,x))~(ro.cross(2));
//(stereoGainComputerHalf(x,y),stereoGainComputerHalf(y,x))~((_,_ <: !,_,_,!),_)
process = stereoLimiter;
// process = naiveStereoLimiter;
// process = minimalStereoLimiter;
// process(x) = block_hold(x);
// process(x) = Yann_hold(x);
// process = ((fixed_hold(maxWinSize)@(5):max(lastdown)),_): min ;
// Lookahead(x,lastdown,avgLevel) =

//(((_,(_,((_,_):Lookahead(y)):min)):linearXfade(link)):releaseEnv(minRelease):rateLimit);

//(((_,(_<:_,_)):(Lookahead(x)<:_,_),(_<:_,_)):ro.interleave(2,2));

//(((_,(_,Lookahead(y,prevy,avgLevely):min)):linearXfade(link)):releaseEnv(minRelease):rateLimit);

//GOOD:
//process(x,y,prevy) =
  /*(*/
    /*(((_,(_,((prevy,_):Lookahead(y)):min)):linearXfade(link)):releaseEnv(minRelease):(rateLimit))*/
    /*~(((_<:(_,_)),_):((ro.cross(2):Lookahead(x)<:_,_),_))*/
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
 //process(x)= rdtable(int(maxAttackTime), ma.tanh((6/maxAttackTime):pow(1:attackScale)),int(x*maxAttackTime));
 /*process(x)= rdtable(maxAttackTime, ( ma.tanh((6/maxAttackTime):pow(attack:attackScale)*(attack*5+.1))/ma.tanh(attack*5+.1)),int(x*maxAttackTime))*/
 /*with { attack = 1; };*/
 /*attackScale(x) = (x+1):pow(7);*/
//process = rateLimiter;
//process = SMOOTH(3,4);
/*process(x) =  0:seq(i,maxHoldTime,*/
       /*(((i+1)>(maxHoldTime-holdTime))*(currentdown(x)@(i):max(lastdown))),_: min */
             /*)*/
             /*with { maxHoldTime = 1024; holdTime = 4; lastdown = no.noise;};*/
