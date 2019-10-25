declare name    "LazyLimiter ng";
declare author  "Bart Brouns";
declare license "GPLv3";
declare version "0.1";
import("stdfaust.lib");

// process(x) = (gainCalculator(x):ba.db2linear)*(x@LookAheadTime);
// process(x) = minGRspeed(x);
// process = recursiveMax(4);
// process = int2nrOfBits(LookAheadTime);//minN(LookAheadTime);
// process = par(i, 4, minN(pow(i+1,2)));
// process = par(i, 4, int2nrOfBits(i),(log(i)/log(2)));
// process = par(i, 16, nUp(i+1),nDown(i+1));
// process = minN(15);
// process = par(i, 8, minN(i));
process = (minGRdelta(GR)),GR@LookAheadTime;

GR = no.lfnoise0(LookAheadTime *t * (no.lfnoise0(LookAheadTime/2):max(0.1) ) ):pow(3):min(0);//(no.noise:min(0)):ba.sAndH(t)
// GR = no.lfnoise0(LookAheadTime *t ):pow(3):min(0);//(no.noise:min(0)):ba.sAndH(t)

// GR = no.lfnoise0(LookAheadTime *t * (no.lfnoise0(LookAheadTime/8)) ):pow(3):min(0);//(no.noise:min(0)):ba.sAndH(t)
t= vslider("time", 0, 0, 1, 0.001);

// reset at rampTime == LookAheadTime
// save at minGR < target
// from save do line of LookAheadTime long
// currentLine(GR)

minGRdelta(GR) =
  minGRdeltaFB(GR)~_
with {
  GRdeltaFB(GR,i,FB) = (GR@(i) - FB)/(LookAheadTime-i+1);
  minGRdeltaFB(GR,FB) = par(i, LookAheadTime+1, GRdeltaFB(GR,i,FB)):minN(LookAheadTime+1)+FB;
};



minN(n) = opWithNInputs(min,n);

// opWithNInputs(op,n) = seq(j,(log(n)/log(2)),par(k,n/(2:pow(j+1)),op));



opWithNInputs =
  case {
    (op,0) => 0:!;
    (op,1) => _;
    (op,2) => op;
    // (op,N) => (opWithNInputs(op,N/2),opWithNInputs(op,N/2)) : op;
    (op,N) => (opWithNInputs(op,nUp(N)),opWithNInputs(op,nDown(N))) : op with {
      nDown(N) = int(floor( N/2));
      nUp(N)   = int(floor((N/2)+0.5));
    };
  };

// minN(n) = seq(j,3,par(k,LookAheadTime/(2:pow(j+1)),min));
// minN(n) = seq(j,int2nrOfBits(n),par(k,n/(2:pow(j+1)),min));
// minN(n) = seq(j,2,par(k,LookAheadTime/(2:pow(j+1)),min));
// minN(n) = seq(j,(log(LookAheadTime)/log(2)),par(k,LookAheadTime/(2:pow(j+1)),min));


gainCalculator(x) = x;
// LookAheadTime = 511;
LookAheadTime = 511;

// GRnSMP(i) =
// GR(i),SMP(i);
// GR(i,x) = (GR(x)@i);

minGRspeed(x) = par(i, LookAheadTime, GRspeed(x)) : seqMin;

GRspeed(x) = x; // TODO

seqMin = seq(i, LookAheadTime, min,_);


recursiveMax =
  case {
    (1,x) => x;
    (N,x) =>  max(recursiveMax(N/2,x) , recursiveMax(N/2,x)@(N/2));
  };

// calculate how many ones and zeros are needed to represent maxN
int2nrOfBits(0) = 0;
int2nrOfBits(maxN) = int(floor(log(maxN)/log(2)));
