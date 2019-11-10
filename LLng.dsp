declare name    "LazyLimiter ng";
declare author  "Bart Brouns";
declare license "GPLv3";
declare version "0.1";
import("stdfaust.lib");
maxmsp = library("maxmsp.lib");

// process(x) = (gainCalculator(x):ba.db2linear)*(x@LookAheadTime);
process =
  GR@(LookAheadTime+length)
 ,GRlong@(LookAheadTime)
// ,line(lowestGRi(5,GR),pow(2,6)) // fast fade
 ,line(lowestGR(GR),LookAheadTime)@length
// ,(par(i, expo, line(GR:ba.slidingMinN(pow(2,i+1),pow(2,i+1)) , pow(2,i+1) )@(pow(2,expo)-pow(2,i+1))):minN(expo))
// ,((((os.lf_trianglepos(4)*LookAheadTime) +1)/LookAheadTime):min(1):attackShaper)
 ,deltaGR(LookAheadTime,GRlong)
;

// expo = 4;
// expo = 8;
expo = 10;
// expo = 13; // 13 = 8192 samples, = 0.185759637188 sec = 186ms

deltaGR(maxI,GR) = FBdeltaGR(maxI,GR)~_
with {
  FBdeltaGR(maxI,GR,FB) =
    par(i, expo,
        (
          (lowestGRi(i,GR)-FB)
            / ((powI(i)-ramp(powI(i),lowestGRi(i,GR)))+1)
        )
        : attackRelease(i,FB)
    )
    : minN(expo) +FB
    : smoother(length)
  ;
  // countup(n,trig) : _
  // * `n`: the maximum count value
  // * `trig`: the trigger signal (1: start at 0; 0: increase until `n`)
  // ramp(maxI,GR) = ((ba.countup(maxI,(GR-GR')!=0)/maxI):attackShaper)*maxI;
  ramp(maxI,GR) =   ba.countup(maxI,(GR-GR')!=0);
  //
  // attackRelease(i,FB) =
  //   select2(FB>FB',
  //           (1/(i+1))*speed : min(1),
  //           (  (i+1))*speed : min(1));
  // speed = (((hslider("speed", 0, 0, 1, 0.001)*-1)+1)*pow(2,expo))+1;
  attackRelease(i,FB,delta) =
    select2((delta+FB)<=FB, // TODO we don't need FB!
            releaseFunc,
            // (1/(i+1))+attack : min(1)
            attackFunc(i)
    )*delta;
  releaseFunc = 1+release;
  attackFunc(i) =
    (
      (
        1/
          ( pow(( (i-curve):max(1)) , 2.5) ) // linear from i=4
          // ) + pow(attack,2) : min(1)
          // ) + pow(attack,2) : min(1)+ ((i==3)*1) + ((i==1)*-0.75)
      ) + pow(attack,2) : min(1)+ ((i==curve)*1) + ((i==(curve-2))*-0.75)
    )
;
curve = hslider("curve", 3, 2, expo, 1);
// (1/(i+1))-attack : min(1));
attack =  hslider("attack",  0, 0, 1, 0.001);
// OK for expo=10
// release = (((hslider("release", 0, 0, 1, 0.001):pow(0.2))*-1)+1)*32;
// OK for 10 and 13
// release = (((hslider("release", 0, 0, 1, 0.001):pow(0.2))*-1)+1)*pow(2,expo/2);
release = (((hslider("release", 0, 0, 1, 0.001):pow(0.2))*-1)+1)*pow(2,expo)/32;
};

// lin from 32 (i=4)
// *2 from 16-8
// *1 from 8-4
// *0.25 from 4-0

// auto-attack-release:
// vocoder, each band represents a fixed A&R, (lower is longer of course)
// and each influences the end result
// use VOF code to normalise and focus

// if (somewhere in the next "length" samples, we are going down quicker then we are now):
// then (fade down to that speed)
// second implementation option:
// if knikpunt
// then (fade down to 0 speed at knikpunt, then "normal release")
// length = pow(2,6); // 64
// TODO: remove this length mess & delay! :)
length = 2;
smoother(length,x) = smootherFB(x)~_ ;
smootherFB(x,FB) = (x); // attackBottom(x);
detaGR(GR) = GR-GR';
minDeltaGR(GR) = deltaGR(GR):slidingMinN(length,length);

// similar thing for the attack-corner:
GRlong = GR:ba.slidingMinN(length,length); // to almost reach the trought earlier
// if (somewhere in the next "length" samples, we are going up quicker then we are now):
// then (fade up to that speed)

linPart = hslider("linPart", 5, 1, 8, 1);

powI(i) = pow(2,i+1);
delComp(i) = pow(2,expo)-powI(i);
lowestGRi(i,GR) = GR:ba.slidingMinN(powI(i),powI(i))@delComp(i);

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


GR = no.lfnoise0(LookAheadTime *t * (no.lfnoise0(LookAheadTime/2):max(0.1) )):pow(3)*(1-noiseLVL) +(no.lfnoise(rate):pow(3) *noiseLVL):min(0);//(no.noise:min(0)):ba.sAndH(t)
t= hslider("time", 0, 0, 1, 0.001);
noiseLVL = hslider("noise", 0, 0, 1, 0.01);
rate = hslider("rate", 20, 10, 20000, 10);



minGRdelta(GR) =
  minGRdeltaFB(GR)~_
with {
  GRdeltaFB(GR,i,FB) = (GR@(i) - FB)/(LookAheadTime-i+1);
  // GRdeltaFB(GR,i,FB) = (GR@(i) - FB)/(((((LookAheadTime-i+1)/LookAheadTime):min(1):attackShaper)*LookAheadTime));
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

gainCalculator(x) = x;
attack                  = (hslider("[2]attack shape[tooltip: 0 gives a linear attack (slow), 1 a strongly exponential one (fast)]", 1 , 0, 1 , 0.001));
attackShaper(fraction)= ma.tanh(fraction:pow(attack:attackScale)*(attack*5+.1))/ma.tanh(attack*5+.1);
attackScale(x) = (x+1):pow(7); //from 0-1 to 1-128, just to make the knob fit the aural experience better
