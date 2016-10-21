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

declare name      "LazyLimiterBlockDiagram";
declare author    "Bart Brouns";
declare version   "0.3";
declare copyright "(C) 2014 Bart Brouns";

import("stdfaust.lib");  //for ba.linear2db
import("stdfaust.lib");  //for an.amp_follower
import ("../GUI.lib");
import ("../LazyLimiter.lib");

process(audio) = GainCalculator(audio) : ba.db2linear * audio@LookAheadTime;

// just for visual indication in the blockdiagram. you can't actually change it and expect the code to work.
LookAheadTime = 4;

GainCalculator(audio) = (minimumGainReduction(audio) : releaseEnvelope)~_;

// this extra abstraction layer is needed to make the feedback loop work.
// not so great for educational purposes.
minimumGainReduction(audio,lastdown) = ((attackGainReduction(audio) , hold(audio,lastdown)): min);

attackGainReduction(audio) = 
(
  currentdown(audio)@1*(1/4),
  currentdown(audio)@2*(2/4),
  currentdown(audio)@3*(3/4),
  currentdown(audio)@4*(4/4)
): (min,min):min;

hold(audio,lastdown) = 
(
  (currentdown(audio)@(0):max(lastdown)),
  (currentdown(audio)@(1):max(lastdown)),
  (currentdown(audio)@(2):max(lastdown)),
  (currentdown(audio)@(3):max(lastdown))
): (min,min):min;

release = 0.1;
releaseEnvelope = an.amp_follower(release);
