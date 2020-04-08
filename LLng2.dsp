import("stdfaust.lib");
declare author "Bart Brouns";
declare license "GPLv3";

process =
GR@totalLatency
,smoothGR(GR)
    ;

    totalLatency = nrBlocks * blockSize;
    // nrBlocks = 1;
    // blockSize = 1024;
    // nrBlocks = 2;
    // blockSize = 512;
    // nrBlocks = 8;
    // blockSize = 128;
    // nrBlocks = 1;
    // blockSize = 256;
    nrBlocks = 3;
    blockSize = 128;
    // nrBlocks = 4;
    // blockSize = 4;

    smoothGR(GR) = FB~(_,_) with {
      FB(prev,oldDownSpeed) =
        // par(i, nrBlocks, crossf(i))
        par(i, nrBlocks, crossf(i)):ro.interleave(2,nrBlocks):(minN(nrBlocks),maxN(nrBlocks))
      with {
      crossf(i) =
        select2(attPhase
               ,lowestGRblock(GR,totalLatency)
               , crossfade(prevH,newH ,ramp(size,reset(attPhase)))*hslider("power %i", 1, 0, 2, 0.01) // TODO crossfade from current directin to new position
        ):min(GR@totalLatency)//TODO: make
      , (select2((newDownSpeed > (oldDownSpeed*oldIsValid)),oldDownSpeed*oldIsValid,newDownSpeed))
      with {
      new = lowestGRblock(GR,size)@(i*blockSize);
      newH = new:ba.sAndH(reset(attPhase));
      size = (nrBlocks-i)*blockSize;
      prevH = prev:ba.sAndH(reset(attPhase));
      reset(attPhase) =
        (newDownSpeed > (oldDownSpeed*oldIsValid)) | (attPhase==0)
      with {
        oldDownSpeed2 = select2(checkbox("relOld"),oldDownSpeed, (prev'-prev));
      };
      oldIsValid =
        // lowestGRblock(GR,totalLatency)<prev
        // &
        // (prev!=GR@(totalLatency))
        (prev!=GR@(totalLatency))
//&(prev!=new)
// & (prev!=prev')
      ;

      attPhase = lowestGRblock(GR,totalLatency)<prev;//(prev-oldDownSpeed);
newDownSpeed = (prev -new )/size;
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
