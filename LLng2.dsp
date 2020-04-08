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
       ,attPhase(prev)
      with {
          crossf(i) =
            select2(attPhase(prev)
              ,lowestGRblock(GR,totalLatency)
              , crossfade(prevH,newH ,ramp(size,reset))*hslider("power %i", 1, 0, 2, 0.01) // TODO crossfade from current directin to new position
            ):min(GR@totalLatency)//TODO: make into brute force fade of 64 samples
          // sample and hold oldDownSpeed:
          , (select2((newDownSpeed > (oldDownSpeed*oldIsValid)),oldDownSpeed*oldIsValid,newDownSpeed))
              with {
              new = lowestGRblock(GR,size)@(i*blockSize);
              newH = new:ba.sAndH(reset);
              prevH = prev:ba.sAndH(reset);
              reset =
                (newDownSpeed > (oldDownSpeed*oldIsValid)) | (attPhase(prev)==0)
              with {
                oldDownSpeed2 = select2(checkbox("relOld"),oldDownSpeed, (prev'-prev));
              };
              oldIsValid = (prev!=GR@(totalLatency)) ; // TODO: needs more checks, not just attack
              newDownSpeed = (prev -new )/size;
              size = (nrBlocks-i)*blockSize;
              }; // ^^ needs i
      }; // ^^ needs prev and oldDownSpeed
      attPhase(prev) = lowestGRblock(GR,totalLatency)<prev;
      lowestGRblock(GR,size) = GR:ba.slidingMin(size,totalLatency);

      // ramp from 1/n to 1 in n samples.
      // when reset == 1, go back to 0.
      ramp(n,reset) = select2(reset,_+(1/n):min(1),1/n)~_;

      crossfade(a,b,x) = a*(1-x) + b*x;

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


    GR = vgroup("GR", no.lfnoise0(totalLatency *t * (no.lfnoise0(totalLatency/2):max(0.1) )):pow(3)*(1-noiseLVL) +(no.lfnoise(rate):pow(3) *noiseLVL):min(0)) ;//(no.noise:min(0)):ba.sAndH(t)
t= hslider("time", 0.1, 0, 1, 0.001);
noiseLVL = hslider("noise", 0, 0, 1, 0.01);
rate = hslider("rate", 20, 10, 20000, 10);
