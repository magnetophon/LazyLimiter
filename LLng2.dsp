import("stdfaust.lib");
declare author "Bart Brouns";
declare license "GPLv3";

process =
  GR@totalLatency
 ,smoothGR(GR)
// , (attRel~_)
;
attRel(prev) = select2(
                 GR:ba.slidingMin(totalLatency,totalLatency)<prev,decay,attack) with {
  decay =  prev*ba.tau2pole(decaytime)+(GR:ba.slidingMin(totalLatency,totalLatency)*(1-ba.tau2pole(decaytime)));
  attack = prev*ba.tau2pole(attacktime)+(GR:ba.slidingMin(totalLatency,totalLatency)*(1-ba.tau2pole(attacktime)));
  attacktime = hslider("attacktime ", 0.02, 0, 0.1, 0.001);
  decaytime = hslider("decaytime ", 0.1, 0, 0.5, 0.001);
                 };


totalLatency = nrBlocks * blockSize;
// nrBlocks = 1;
// blockSize = 1024;
// nrBlocks = 2;
// blockSize = 512;
// nrBlocks = 8;
// blockSize = 128;
// nrBlocks = 1;
// blockSize = 512;
nrBlocks = 3;
blockSize = 128;
// nrBlocks = 4;
// blockSize = 4;

smoothGR(GR) = FB~(_,_):(_,!,_,_) with {
  FB(prev,oldDownSpeed) =
    // par(i, nrBlocks, crossf(i))
    par(i, nrBlocks, crossf(i)):ro.interleave(2,nrBlocks):(minN(nrBlocks),maxN(nrBlocks))
// ,currentDownSpeed*30
// ,attPhase(prev)
,ramp(size(1),reset(1))*128
// ,speedIsZero
// ,prevH(0)
// ,prevH(1)
// , newDownSpeed(0)*30
// , newDownSpeed(1)*30
,newH(1)
// ,reset(1)
// ,((prev-prev')*90)
// ,(newDownSpeed(0) > currentDownSpeed)
  with {
  new(i) = lowestGRblock(GR,size(i))@(i*blockSize);
  newH(i) = new(i):ba.sAndH(reset(i)| (attPhase(prev)==0) );
  prevH(i) = prev:ba.sAndH(reset(i)| (attPhase(prev)==0) );
  reset(i) =
    (newDownSpeed(i) > currentDownSpeed);
  crossf(i) =
    select2(attPhase(prev)
           ,lowestGRblock(GR,totalLatency)
           , crossfade(prevH(i),newH(i) ,ramp(size(i),reset(i))*hslider("power %i", 1, 0, 2, 0.01)) // TODO crossfade from current direction to new position
    ):min(GR@totalLatency)//TODO: make into brute force fade of 64 samples
// sample and hold oldDownSpeed:
  , (select2((newDownSpeed(i) > currentDownSpeed),currentDownSpeed ,newDownSpeed(i)));
  // with {
  newDownSpeed(i) = (prev -new(i) )/size(i);
  currentDownSpeed = oldDownSpeed*(speedIsZero==0);
  // speedIsZero = (prev==GR@(totalLatency)) ; // TODO: needs more checks, not attack
  // speedIsZero = (prev==prev') ;
  speedIsZero = select2(checkbox("speed"),(prev==GR@(totalLatency)),(prev==prev'));
  size(i) = (nrBlocks-i)*blockSize;
  // }; // ^^ needs i
  }; // ^^ needs prev and oldDownSpeed
  attPhase(prev) = lowestGRblock(GR,totalLatency)<prev;
  lowestGRblock(GR,size) = GR:ba.slidingMin(size,totalLatency);

  // ramp from 1/n to 1 in n samples.  (don't start at 0 cause when the ramp restarts, the crossfade should start right away)
  // when reset == 1, go back to 0.
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


GR = vgroup("GR", no.lfnoise0(totalLatency *t * (no.lfnoise0(totalLatency/2):max(0.1) )):pow(3)*(1-noiseLVL) +(no.lfnoise(rate):pow(3) *noiseLVL):min(0)) ;
t= hslider("time", 0.1, 0, 1, 0.001);
noiseLVL = hslider("noise", 0, 0, 1, 0.01);
rate = hslider("rate", 20, 10, 20000, 10);
