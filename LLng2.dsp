import("stdfaust.lib");
declare author "Bart Brouns";
declare license "GPLv3";

process =
GR@totalLatency
,smoothGR(GR)
// newVal,oldVal with {
// newVal = hslider("val", 0, 0, 1, 0.1):ba.sAndH(reset);
// oldVal = newVal':ba.sAndH(reset);
// reset = button("reset"):ba.impulsify;
// }
// reset(attPhase)
    ;

    reset(attPhase) = resetFB(attPhase)~_:(!,_) ;
    resetFB(attPhase,oldDownSpeed) =(newDownSpeed > (oldDownSpeed))<:
                                    (
                                      ((cross2:select2(_,_,newDownSpeed)*attPhase)~_)
                                     ,_);
    cross2(a,b) = b,a;
    newDownSpeed = hslider("DS", 0, 0, 1, 0.1):ba.sAndH(button("samp"):ba.impulsify);
    attPhase = button("rel")*-1+1;

    xVal_target(reset)  = rwtable(3, 0.0,nextValIndex(reset),xVal,currentValIndex(reset));
    currentValIndex(reset) = reset :ba.toggle: xor(startPulse'');
    nextValIndex(reset) = currentValIndex(reset)*-1+1;
    startPulse = 1-1';


    totalLatency = nrBlocks * blockSize;
    nrBlocks = 1;
    blockSize = 1024;
    // nrBlocks = 2;
    // blockSize = 512;
    // nrBlocks = 4;
    // blockSize = 256;
    // nrBlocks = 8;
    // blockSize = 128;
    // nrBlocks = 64;
    // blockSize = 16;
    // nrBlocks = 4;
    // blockSize = 4;

    smoothGR(GR) = FB~(_,_) with {
      FB(prev,oldDownSpeed) =
        // par(i, nrBlocks, crossf(i))
        // par(i, nrBlocks, crossf(i))
        // par(i, nrBlocks, crossf(i)):(minN(nrBlocks),maxN(nrBlocks))
        par(i, nrBlocks, crossf(i)):ro.interleave(2,nrBlocks):(minN(nrBlocks),maxN(nrBlocks))
      with {
      // crossf(i) = reset
      crossf(i) =
        select2(attPhase
               ,lowestGRblock(GR,totalLatency)
               , crossfade(prevH,newH ,ramp(size,reset(attPhase))) // TODO crossfade from current directin to new position
        ):min(GR@totalLatency)//bootstrap measure, TODO take out
      , ((select2((newDownSpeed > (oldDownSpeed)),oldDownSpeed,newDownSpeed)*(prev!=GR@totalLatency)*(prev!=lowestGRblock(GR,totalLatency))*attPhase))
// ,reset(attPhase)
// ,(prev!=GR@(totalLatency+1))
// ,(prev!=new)
// ,GR@totalLatency
// ,ramp(size,reset)
// ,prev
// ,new
      with {
      new = lowestGRblock(GR,size)@(i*blockSize);
      newH = new:ba.sAndH(reset(attPhase));
      size = (nrBlocks-i)*blockSize;
      prevH = prev:ba.sAndH(reset(attPhase));
      // reset(attPhase) = resetFB(attPhase)~_:(!,_) ;
      reset(attPhase) =
        (newDownSpeed > (oldDownSpeed))
// <:
// (
// ((cross2:select2(_,_,newDownSpeed)*(prev!=GR@totalLatency)*(prev!=lowestGRblock(GR,totalLatency))*attPhase)~_)
// ,_)
      ;
      // reset = resetFB~_:(!,_) ;
      // resetFB(oldDownSpeed) =(newDownSpeed > (oldDownSpeed))<:
      // (
      // ((cross2:select2(_,oldDownSpeed,_))~_)
      // ,_);
      cross2(a,b) = b,a;
      attPhase = lowestGRblock(GR,totalLatency)<prev;
      // reset = resetFB~_:(!,_) with {
      // resetFB(fb) =(newDownSpeed > (fb))<:((newDownSpeed:ba.sAndH(_)),_);};
      // reset =(newDownSpeed > oldDownSpeed);

      newDownSpeed = (prev -new )/size;
      // oldDownSpeed = (prev'-prev);
      // oldDownSpeed(FBreset) = (prev'-prev),(FBreset:!);
      // oldDownSpeed(FBreset) = newDownSpeed':ba.sAndH(FBreset)':ba.sAndH(FBreset);
      // oldDownSpeed(FBreset) = newDownSpeed:ba.sAndH(FBreset:ba.impulsify);
      crossfade(a,b,x) = a*(1-x) + b*x;
      };
      lowestGRblock(GR,size) = GR:ba.slidingMin(size,totalLatency);
      // ramp from 1/n to 1 in n samples.
      // when reset == 1, go back to 0.
      ramp(n,reset) = select2(reset,_+(1/n):min(1),1/n)~_;

      minN(n) = opWithNInputs(min,n);
      maxN(n) = opWithNInputs(max,n);

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


    GR = vgroup("GR", no.lfnoise0(totalLatency *t * (no.lfnoise0(totalLatency/2):max(0.1) )):pow(3)*(1-noiseLVL) +(no.lfnoise(rate):pow(3) *noiseLVL):min(0)) ;//(no.noise:min(0)):ba.sAndH(t)
t= hslider("time", 0.1, 0, 1, 0.001);
noiseLVL = hslider("noise", 0, 0, 1, 0.01);
rate = hslider("rate", 20, 10, 20000, 10);
