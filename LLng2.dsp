import("stdfaust.lib");
declare author "Bart Brouns";
declare license "GPLv3";

process =
GR@totalLatency
,smoothGR(GR)
// , (attRel~_)
;

totalLatency = pow(2,expo);
// totalLatency = nrBlocks * blockSize;
// nrBlocks = 1;
// blockSize = 1024;
// nrBlocks = 2;
// blockSize = 512;
// nrBlocks = 8;
// blockSize = 128;
// nrBlocks = 16;
// blockSize = 64;
// nrBlocks = 1;
// blockSize = 512;
// nrBlocks = 2;
// blockSize = 128;
// nrBlocks = 1;
// blockSize = 4;
// expo = 4;
// expo = 10;
expo = 8;
// TODO sAndH(reset) parameters
smoothGR(GR) = FB~(_,_) :(_,!)
with {
  FB(prev,oldDownSpeed) =
    par(i, expo, fade(i)):ro.interleave(2,expo):(minN(expo),maxN(expo))
  with {
  new(i) = lowestGRblock(GR,size(i))@(totalLatency-size(i));
  newH(i) = new(i):ba.sAndH( reset(i)| (attPhase(prev)==0) );
  prevH(i) = prev:ba.sAndH( reset(i)| (attPhase(prev)==0) );
  reset(i) =
    (newDownSpeed(i) > currentDownSpeed);
  fade(i) =
    // crossfade(currentPosAndDir(i),newH(i) ,ramp(size(i),reset(i)):rampShaper(i)) // TODO crossfade from current direction to new position
    crossfade(prevH(i),newH(i) ,ramp(size(i),reset(i)):rampShaper(i)) // TODO crossfade from current direction to new position
    :min(GR@totalLatency)//brute force fade of 64 samples not needed for binary tree attack ?
// sample and hold oldDownSpeed:
  , (select2((newDownSpeed(i) > currentDownSpeed),currentDownSpeed ,newDownSpeed(i)));
  rampShaper(i) = _:pow(power(i))*mult(i):max(smallestRamp(reset(i)));
  power(i) = LinArrayParametricMid(hslider("power bottom", 1, 0.01, 10, 0.01),hslider("power mid", 1, 0.01, 10, 0.01),hslider("power band", (expo/2)-1, 0, expo, 1),hslider("power top", 0.5, 0.01, 10, 0.01),i,expo);
  mult(i) = LinArrayParametricMid(hslider("mult bottom", 1, 0.001, 1 ,0.001),hslider("mult mid", 1, 0.001, 1 ,0.001),hslider("mult band", (expo/2)-1, 0, expo, 1),hslider("mult top", 1, 0.001, 1 ,0.001),i,expo);
  currentPosAndDir(i) = prevH(i)-( ramp(size(i),reset(i)) * hslider("ramp", 0, 0, 1, 0.01) * (prevH(i)'-prevH(i)));
  // newDownSpeed(i) = (select2(checkbox("newdown"),prev,(prev'-currentDownSpeed)) -new(i) )/size(i);
  newDownSpeed(i) = (prev -new(i) )/size(i);
  currentDownSpeed = oldDownSpeed*(speedIsZero==0);
  // speedIsZero = (prev==GR@(totalLatency)) ; // TODO: needs more checks, not attack
  // speedIsZero = (prev==prev') ;
  speedIsZero = select2(checkbox("speed"),(prev==GR@(totalLatency)),(prev==prev'));
  size(i) = pow(2,(expo-i));
  }; // ^^ needs prev and oldDownSpeed
  attPhase(prev) = lowestGRblock(GR,totalLatency)<prev;
  lowestGRblock(GR,size) = GR:ba.slidingMin(size,totalLatency);


  // ramp from 1/n to 1 in n samples.  (don't start at 0 cause when the ramp restarts, the crossfade should start right away)
  // when reset == 1, go back to 0.
  // ramp(n,reset) = select2(reset,_+(1/n):min(1),0)~_;
  ramp(n,reset) = select2(reset,_+(1/n):min(1),1/n)~_;
  smallestRamp(reset)  = select2(reset,_+(small):min(1),small)~_ with {
    small = pow(2,-23);
};


  crossfade(a,b,x) = it.interpolate_linear(x,a,b);  // faster then: a*(1-x) + b*x;

  minN(n) = opWithNInputs(min,n);
  maxN(n) = opWithNInputs(max,n);

  opWithNInputs =
    case {
      (op,0) => 0:!;
        (op,1) => _;
      (op,2) => op;
      (op,N) => (opWithNInputs(op,N-1),_) : op;
    };
};

smoothGRlinear(GR) = FB~(_,_)
                        :(_,!)
with {
  FB(prev,oldDownSpeed) =
    par(i, nrBlocks, fade(i)):ro.interleave(2,nrBlocks):(minN(nrBlocks),maxN(nrBlocks))
  with {
  new(i) = lowestGRblock(GR,size(i))@(i*blockSize);
  newH(i) = new(i):ba.sAndH( reset(i)| (attPhase(prev)==0) );
  prevH(i) = prev:ba.sAndH( reset(i)| (attPhase(prev)==0) );
  reset(i) =
    (newDownSpeed(i) > currentDownSpeed);
  fade(i) =
    // crossfade(currentPosAndDir(i),newH(i) ,ramp(size(i),reset(i)):rampShaper(i)) // TODO crossfade from current direction to new position
    crossfade(prevH(i),newH(i) ,ramp(size(i),reset(i)):rampShaper(i)) // TODO crossfade from current direction to new position
    :min(GR@totalLatency)//TODO: make into brute force fade of 64 samples
// sample and hold oldDownSpeed:
  , (select2((newDownSpeed(i) > currentDownSpeed),currentDownSpeed ,newDownSpeed(i)));
  rampShaper(i) = _:pow(power(i))*mult(i);
  power(i) = LinArrayParametricMid(hslider("power bottom", 1, 0.001, 100, 0.001),hslider("power mid", 1, 0.001, 100, 0.001),hslider("band", (nrBlocks/2)-1, 0, nrBlocks, 1),hslider("power top", 1, 0.001, 100, 0.001),i,nrBlocks);
  mult(i) = LinArrayParametricMid(hslider("mult bottom", 1, 0.001, 1 ,0.001),hslider("mult mid", 1, 0.001, 1 ,0.001),hslider("band", (nrBlocks/2)-1, 0, nrBlocks, 1),hslider("mult top", 1, 0.001, 1 ,0.001),i,nrBlocks);
  currentPosAndDir(i) = prevH(i)-( ramp(size(i),reset(i)) * hslider("ramp", 0, 0, 1, 0.01) * (prevH(i)'-prevH(i)));
  // newDownSpeed(i) = (select2(checkbox("newdown"),prev,(prev'-currentDownSpeed)) -new(i) )/size(i);
  newDownSpeed(i) = (prev -new(i) )/size(i);
  currentDownSpeed = oldDownSpeed*(speedIsZero==0);
  // speedIsZero = (prev==GR@(totalLatency)) ; // TODO: needs more checks, not attack
  // speedIsZero = (prev==prev') ;
  speedIsZero = select2(checkbox("speed"),(prev==GR@(totalLatency)),(prev==prev'));
  size(i) = (nrBlocks-i)*blockSize;
  }; // ^^ needs prev and oldDownSpeed
  attPhase(prev) = lowestGRblock(GR,totalLatency)<prev;
  lowestGRblock(GR,size) = GR:ba.slidingMin(size,totalLatency);


  // ramp from 1/n to 1 in n samples.  (don't start at 0 cause when the ramp restarts, the crossfade should start right away)
  // when reset == 1, go back to 0.
  // ramp(n,reset) = select2(reset,_+(1/n):min(1),0)~_;
  ramp(n,reset) = select2(reset,_+(1/n):min(1),1/n)~_;

  crossfade(a,b,x) = it.interpolate_linear(x,a,b);  // faster then: a*(1-x) + b*x;

  minN(n) = opWithNInputs(min,n);
  maxN(n) = opWithNInputs(max,n);

  opWithNInputs =
    case {
      (op,0) => 0:!;
        (op,1) => _;
      (op,2) => op;
      (op,N) => (opWithNInputs(op,N-1),_) : op;
    };
};

// make a log array of values, from bottom to top
LogArray(bottom,top,nrElements) =     par(i,nrElements,   pow((pow((top/bottom),1/(nrElements-1))),i)*bottom);

LinArrayParametricMid(bottom,mid,band,top,element,nrElements) =
  select2(band<=element +1,midToBottomVal(element), midToTopVal(element))
with {
  midToBottomVal(element) = (midToBottom(element)*bottom) + (((midToBottom(element)*-1)+1)*mid);
  midToBottom(element) = (band-(element +1))/(band-1);

  midToTopVal(element) = (midToTop(element)*top) + (((midToTop(element)*-1)+1)*mid);
  midToTop(element) = (element +1-band)/(nrElements-band);
};

GR = vgroup("GR", no.lfnoise0(totalLatency *t * (no.lfnoise0(totalLatency/2):max(0.1) )):pow(3)*(1-noiseLVL) +(no.lfnoise(rate):pow(3) *noiseLVL):min(0)) ;
t= hslider("time", 0.1, 0, 1, 0.001);
noiseLVL = hslider("noise", 0, 0, 1, 0.01);
rate = hslider("rate", 20, 10, 20000, 10);

attRel(prev) = select2(
                 GR:ba.slidingMin(totalLatency,totalLatency)<prev,decay,attack) with {
  decay =  prev*ba.tau2pole(decaytime)+(GR:ba.slidingMin(totalLatency,totalLatency)*(1-ba.tau2pole(decaytime)));
  attack = prev*ba.tau2pole(attacktime)+(GR:ba.slidingMin(totalLatency,totalLatency)*(1-ba.tau2pole(attacktime)));
  attacktime = hslider("attacktime ", 0.02, 0, 0.1, 0.001);
  decaytime = hslider("decaytime ", 0.1, 0, 0.5, 0.001);
                 };
