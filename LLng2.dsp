import("stdfaust.lib");
declare author "Bart Brouns";
declare license "GPLv3";

process =
  GR@(totalLatency*1)
 ,smoothGR(GR)
;

totalLatency = nrBlocks * blockSize;
// nrBlocks = 64;
// blockSize = 16;
nrBlocks = 8;
blockSize = 128;
// nrBlocks = 1;
// blockSize = 1024;
// blockSize = 4;


GR = vgroup("GR", no.lfnoise0(totalLatency *t * (no.lfnoise0(totalLatency/2):max(0.1) )):pow(3)*(1-noiseLVL) +(no.lfnoise(rate):pow(3) *noiseLVL):min(0)) ;//(no.noise:min(0)):ba.sAndH(t)
t= hslider("time", 0.1, 0, 1, 0.001);
noiseLVL = hslider("noise", 0, 0, 1, 0.01);
rate = hslider("rate", 20, 10, 20000, 10);

smoothGR(GR) = FB~_ with {
  FB(prev) =
    // par(i, nrBlocks, crossf(i))
    select2(lowestGRblock(GR,totalLatency)>=prev 
           ,par(i, nrBlocks, crossf(i)):minN(nrBlocks)
           ,lowestGRblock(GR,totalLatency)
    )//:min(GR@totalLatency)//bootstrap measure, TODO take out
  with {
  // crossf(i) = reset
  crossf(i) =
           crossfade(prevH,newH ,ramp(size,reset))
// ,GR@totalLatency
// ,GR@totalLatency)
// ,ramp(size,reset)
// ,prev
// ,new
  with {
  new = lowestGRblock(GR,size)@(i*blockSize);
  newH = new:ba.sAndH(reset);
  size = (nrBlocks-i)*blockSize;
  prevH = prev:ba.sAndH(reset);
  // reset = new<new';
  // reset = resetFB~_ with {
  // resetFB(fb) =(newDownSpeed > oldDownSpeed(fb));
  // reset =(newDownSpeed > oldDownSpeed):select2(checkbox("imp"),_,ba.impulsify);
  // reset =(newDownSpeed > oldDownSpeed):ba.impulsify;
  reset =(newDownSpeed > oldDownSpeed);

  newDownSpeed = (prev -new )/size;
  // oldDownSpeed = (prev'-prev);
  oldDownSpeed = (prev'-prev);
  // oldDownSpeed(reset) = (prev'-prev):ba.sAndH(reset);
  crossfade(a,b,x) = a*(1-x) + b*x;
  };
  lowestGRblock(GR,size) = GR:ba.slidingMin(size,totalLatency);
  // ramp from 1/n to 1 in n samples.
  // when reset == 1, go back to 0.
  ramp(n,reset) = select2(reset,_+(1/n):min(1),1/n)~_;

  minN(n) = opWithNInputs(min,n);

  // opWithNInputs(op,n) = seq(j,(log(n)/log(2)),par(k,n/(2:pow(j+1)),op));
  opWithNInputs =
    case {
      (op,0) => 0:!;
        (op,1) => _;
      (op,2) => op;
      // (op,N) => (opWithNInputs(op,N/2),opWithNInputs(op,N/2)) : op;
      (op,N) => (opWithNInputs(op,N-1),_) : op;
      // (op,N) => (opWithNInputs(op,nUp(N)),opWithNInputs(op,nDown(N))) : op with {
      // nDown(N) = int(floor( N/2));
      // nUp(N)   = int(floor((N/2)+0.5));
      // };
    };
    };
};
