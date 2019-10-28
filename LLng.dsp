declare name    "LazyLimiter ng";
declare author  "Bart Brouns";
declare license "GPLv3";
declare version "0.1";
import("stdfaust.lib");
maxmsp = library("maxmsp.lib");

// process(x) = (gainCalculator(x):ba.db2linear)*(x@LookAheadTime);
process =
GR@LookAheadTime
,line(lowestGR(GR),LookAheadTime)
// ,(par(i, expo, line(GR:ba.slidingMinN(pow(2,i+1),pow(2,i+1)) , pow(2,i+1) )@(pow(2,expo)-pow(2,i+1))):minN(expo))
// ,((((os.lf_trianglepos(4)*LookAheadTime) +1)/LookAheadTime):min(1):attackShaper)
,deltaGR(LookAheadTime,GR)
;

// expo = 4;
// expo = 8;
expo = 13;

deltaGR(maxI,GR) = FBdeltaGR(maxI,GR)~_
with {
  FBdeltaGR(maxI,GR,FB) =
    par(i, expo,
        ((lowestGR(i)-FB)
          /((powI(i)-ramp(powI(i),lowestGR(i)))+1))
        : attackRelease(i,FB)
    )
    :minN(expo) +FB;
  ramp(maxI,GR) = ba.countup(maxI,(GR-GR')!=0);
  powI(i) = pow(2,i+1);
  delComp(i) = pow(2,expo)-powI(i);
  lowestGR(i) = GR:ba.slidingMinN(powI(i),powI(i))@delComp(i);
  // attackRelease(i,FB) =
  //   select2(FB>FB',
  //           (1/(i+1))*speed : min(1),
  //           (  (i+1))*speed : min(1));
  // speed = (((hslider("speed", 0, 0, 1, 0.001)*-1)+1)*pow(2,expo))+1;
  attackRelease(i,FB,delta) =
    select2((delta+FB)<=FB,
            1+release,
            (1/(i+1))+attack : min(1))*delta;
  // (1/(i+1))-attack : min(1));
  attack =  hslider("attack",  0, 0, 1, 0.001)*32;
  release = ((hslider("release", 0, 0, 1, 0.001)*-1)+1)*32;
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


GR = no.lfnoise0(LookAheadTime *t * (no.lfnoise0(LookAheadTime/2):max(0.1) ) ):pow(3):min(0);//(no.noise:min(0)):ba.sAndH(t)
t= hslider("time", 0, 0, 1, 0.001);



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
