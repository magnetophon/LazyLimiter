declare name    "LazyLimiter ng";
declare author  "Bart Brouns";
declare license "GPLv3";
declare version "0.1";
import("stdfaust.lib");
maxmsp = library("maxmsp.lib");

// process(x) = (gainCalculator(x):ba.db2linear)*(x@LookAheadTime);
// process(x) = minGRspeed(x);
// process = recursiveMax(4);
// process = int2nrOfBits(LookAheadTime);//minN(LookAheadTime);
// process = par(i, 4, minN(pow(i+1,2)));
// process = par(i, 4, int2nrOfBits(i),(log(i)/log(2)));
// process = par(i, 16, nUp(i+1),nDown(i+1));
// process = minN(15);
// process = par(i, 8, minN(i));
process =
  // (minGRdelta(GR))
  // ,
  // GR@LookAheadTime
  GR@pow(2,expo)
// ,lowestGR(GR)
// ,line(lowestGR(GR),LookAheadTime)
// ,(line(GR:ba.slidingMinN(pow(2,4),pow(2,1)) , pow(2,1) ))
 ,(par(i, expo, line(GR:ba.slidingMinN(pow(2,i+1),pow(2,i+1)) , pow(2,i+1) )@(pow(2,expo)-pow(2,i+1))):minN(expo))
// ,(line(GR:ba.slidingMinN(pow(2,expo-1),pow(2,expo-1)) , pow(2,expo-1) )@(pow(2,expo)-pow(2,expo-1)))
// ,minGRdelta(GR)
// ,((((os.lf_trianglepos(4)*LookAheadTime) +1)/LookAheadTime):min(1):attackShaper)
 ,deltaGR(LookAheadTime,lowestGR(GR))
 ,ramp(LookAheadTime,lowestGR(GR))
;

// expo = 4;
expo = 8;
// expo = 13;


// Starts counting up from 0 to n included. While trig is 1 the output is 0.
// The countup starts with the transition of trig from 1 to 0. At the end
// of the countup the output value will remain at n until the next trig.
deltaGR(maxI,GR) = FBdeltaGR(maxI,GR)~_
;
// with {
// };

FBdeltaGR(maxI,GR,FB) = (GR-FB)/((maxI-ramp(maxI,GR))+1);
ramp(maxI,GR) = ba.countup(maxI,(GR-GR')!=0);



minGRdelta2(GR) =
  minGRdeltaFB(GR)~_
with {
  GRdeltaFB(GR,i,FB) = (GR@(i) - FB)/(LookAheadTime-i+1);
  // GRdeltaFB(GR,i,FB) = (GR@(i) - FB)/(((((LookAheadTime-i+1)/LookAheadTime):min(1):attackShaper)*LookAheadTime));
  minGRdeltaFB(GR,FB) = par(i, LookAheadTime+1, GRdeltaFB(GR,i,FB)):minN(LookAheadTime+1)+FB;
};

// LookAheadTime = 127;
// LookAheadTime = 4096;
LookAheadTime = pow(2,expo);
// LookAheadTime = 511;
// LookAheadTime = 15; // for diagram


line (value, time) = state~(_,_):!,_
with {
	state (t, c) = nt, ba.if (nt <= 0, value, c+(value - c) / nt)
	with {
	nt = ba.if( value != value', time, t-1);
	};
};

lowestGR(GR) = GR:ba.slidingMinN(LookAheadTime,LookAheadTime);
newLowestGR(GR) = lowestGR(GR) != lowestGR(GR)';


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
  // GRdeltaFB(GR,i,FB) = (GR@(i) - FB)/(((((LookAheadTime-i+1)/LookAheadTime):min(1):attackShaper)*LookAheadTime));
  minGRdeltaFB(GR,FB) = par(i, LookAheadTime+1, GRdeltaFB(GR,i,FB)):minN(LookAheadTime+1)+FB;
};

// ( par(i,maxAttackTime, currentdown(x)@((i+1-maxAttackTime+maxHoldTime):max(0))*(((i+1)/maxAttackTime):attackShaper)): seq(j,(log(maxAttackTime)/log(2)),par(k,maxAttackTime/(2:pow(j+1)),min)))
// attackShaper

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
attack                  = (hslider("[2]attack shape[tooltip: 0 gives a linear attack (slow), 1 a strongly exponential one (fast)]", 1 , 0, 1 , 0.001));
attackShaper(fraction)= ma.tanh(fraction:pow(attack:attackScale)*(attack*5+.1))/ma.tanh(attack*5+.1);
attackScale(x) = (x+1):pow(7); //from 0-1 to 1-128, just to make the knob fit the aural experience better

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
