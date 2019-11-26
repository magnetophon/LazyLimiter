declare name    "LazyLimiter ng";
declare author  "Bart Brouns";
declare license "GPLv3";
declare version "0.1";
import("stdfaust.lib");
maxmsp = library("maxmsp.lib");

// process(x) = (gainCalculator(x):ba.db2linear)*(x@LookAheadTime);
process =
GR@(LookAheadTime+length)
// ,GRlong@(LookAheadTime)
,line(lowestGRi(5,GR),pow(2,6))@length // fast fade
,line(lowestGR(GR),LookAheadTime)@length // slow fade
// ,(par(i, expo, line(GR:ba.slidingMinN(pow(2,i+1),pow(2,i+1)) , pow(2,i+1) )@(pow(2,expo)-pow(2,i+1))):minN(expo))
// ,((((os.lf_trianglepos(4)*LookAheadTime) +1)/LookAheadTime):min(1):attackShaper)
 // ,(deltaGR(LookAheadTime,GR)  <: (_-_') : (_*ma.SR/1000)  :ba.slidingMinN(length,length))
 // ,(deltaGR(LookAheadTime,GR) : smoother(length) <: (_-_') : (_*ma.SR/1000)  <: ((_:ba.slidingMinN(length,length))<_@length))
 // ,(deltaGR(LookAheadTime,GR)  <: (del) : (_*ma.SR/1000) : (_@length) )
,deltaGR(LookAheadTime,GR)@length
// ,(deltaGR(LookAheadTime,GR)     : smoother(length))
;

del(x) = x-x';
// del = delFB~_;
// delFB(FB,x) = x-FB;
// expo = 4;
// expo = 8;
expo = 10; // 10 = 1024 samples
// expo = 13; // 13 = 8192 samples, = 0.185759637188 sec = 186ms

// deltaGR(maxI,GR) = FBdeltaGR(maxI,GR)~_
// with {
//   FBdeltaGR(maxI,GR,FB) =
//     par(i, expo,
//         (
//           (lowestGRi(i,GR)-FB)
//             / ((powI(i)-ramp(powI(i),lowestGRi(i,GR)))+1)
//         )
//         : attackRelease(i)
//     )
//     : ((minN(expo) :smoothie ) +FB)
//     // :min(0)
//     :min(GR@LookAheadTime)
//   ;
deltaGR(maxI,GR) = FBdeltaGR(maxI,GR)~_
with {
  FBdeltaGR(maxI,GR,FB) =
    par(i, 16,
        (
          (lowestGRlinI(i,GR)-FB)
            / ((linI(i)-ramp(linI(i),lowestGRlinI(i,GR)))+1)
        )
        : attackRelease(i)
    )
    : ((minN(16) :smoothie ) +FB)
    // :min(0)
    :min(GR@LookAheadTime);
  linI(i) = (i+1)*64;
  lowestGRlinI(i,GR) = GR:ba.slidingMinN(linI(i),linI(i))@delCompLin(i);

  delCompLin(i) = pow(2,expo)-linI(i);

  // smoothie(delta) = select2(delta>=0,delta,smoothieFB(delta)~_);
  // smoothieFB(delta,FB) = min(( (FB*smoo) + (delta*(1-smoo))):max(0) , delta);
  smoothie(delta) = smoothieFB(delta)~_;
  smoothieFB(delta,FB) = select2(delta>=0,delta,min(( (FB*smoo) + (delta*(1-smoo))):max(0) , delta));
  smoo = hslider("smoo", 0, 0,0.999, 0.001):pow(1/128);
  // countup(n,trig) : _
  // * `n`: the maximum count value
  // * `trig`: the trigger signal (1: start at 0; 0: increase until `n`)
  // ramp(maxI,GR) = ((ba.countup(maxI,(GR-GR')!=0)/maxI):attackShaper)*maxI;
  ramp(maxI,GR) =   ba.countup(maxI,(GR-GR')!=0);
  attackRelease(i,delta) =
    select2((delta)<=0,
            releaseFunc,
            // (1/(i+1))+attack : min(1)
            attackFunc(i)
    )*delta;
  releaseFunc =  1+release;
  // releaseFunc(delta) = min((delta*smoo)+( (1+release)  *(1-smoo)));
  //   attackFunc(i) =
  //     (
  //       (
  //         1/
  //           ( pow(( (i-curve):max(1)) , 2.5) ) // linear from i=4
  //           // ) + pow(attack,2) : min(1)
  //           // ) + pow(attack,2) : min(1)+ ((i==3)*1) + ((i==1)*-0.75)
  //       ) + pow(attack,2) : min(1)+ ((i==curve)*1)
  // //+ ((i==(curve-2))*-0.75)
  //     )
  //   ;
  attackFunc(i) =
    (
      (
        1/
          (  (i-curve)*64:max(1)*(attack:pow(4)) )
      ) : min(1)+ ((i==curve)*1)
    )
  ;
  // attackFunc(i) =
  //   (
  //     (
  //       1/
  //         (  (i-curve)*64:max(1)*(attack:pow(4)) )
  //     ) : min(1)+ ((i==curve)*1)
  //   )
  // ;
  curve = hslider("curve", 3, -1, 16, 1);
  // curve = hslider("curve", 3, 2, expo, 1);
  // (1/(i+1))-attack : min(1));
  attack =  hslider("attack",  0, 0, 1, 0.001);
  // OK for expo=10
  // release = (((hslider("release", 0, 0, 1, 0.001):pow(0.2))*-1)+1)*32;
  // OK for 10 and 13
  release = (((hslider("release", 0, 0, 1, 0.001):pow(0.2))*-1)+1)*pow(2,expo/2);
  // release = (((hslider("release", 0, 0, 1, 0.001):pow(0.2))*-1)+1)*pow(2,expo)/32;
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
// TODO: remove this length mess & delay! :)
// length = 2;
// length = pow(2,6); // 64
// length = pow(2,7); // 128
length = pow(2,9); // 128
// smoother(length,x) = smootherFB(x,length)~_;
smoother(length,x) = smootherFB(x,length)~(!,!,_);
smootherFB(x,length,FB) =
  reset,
  ramp
  ,
    // select2(minDelta<(delta@length) ,x@length, deltaXfade)
    deltaXfade
with {
  // delta = x-FB;
  delta = x-x';
  minDelta = (delta):ba.slidingMinN(length,length);
  deltaXfade = xFade(ramp*downSmooth,(x@length)-FB,minDelta)+FB;
  // deltaXfade = xFade(ramp*downSmooth,FB-FB',minDelta)+FB;
  // deltaXfade = (
  // (minDelta-(delta@length))
  // / ((length-ramp(minDelta)+1))
  // )
  // +FB;
  xFade(x,a,b) = a*(1-x)+b*(x);
  downSmooth = hslider("downSmooth", 0, 0, 1, 0.01);
  // ramp =   ba.countup(length,(minDelta<minDelta'))/length;
  ramp =   (ba.countup(length,reset)/length):pow(rampPower);
  rampPower = hslider("rampPower", 1, 1/128, 1, 0.01);
  // ramp =   (ba.countup(length,reset)/length);
  reset = ((delta<delta')*delta>=0)@length;
  // reset = delta<=0;
  // reset = delta<delta';
};

detaGR(GR) = GR-GR';
minDeltaGR(GR) = deltaGR(GR):ba.slidingMinN(length,length);

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
    (op,N) => (opWithNInputs(op,N-1),_) : op;
    // (op,N) => (opWithNInputs(op,nUp(N)),opWithNInputs(op,nDown(N))) : op with {
    // nDown(N) = int(floor( N/2));
    // nUp(N)   = int(floor((N/2)+0.5));
    // };
  };

gainCalculator(x) = x;
attack                  = (hslider("[2]attack shape[tooltip: 0 gives a linear attack (slow), 1 a strongly exponential one (fast)]", 1 , 0, 1 , 0.001));
attackShaper(fraction)= ma.tanh(fraction:pow(attack:attackScale)*(attack*5+.1))/ma.tanh(attack*5+.1);
attackScale(x) = (x+1):pow(7); //from 0-1 to 1-128, just to make the knob fit the aural experience better


VocoderLinArrayParametricMid(bottom,mid,band,top) =
  par(i, nrBands, select2(band<=i+1,midToBottomVal(i),midToTopVal(i)))
  with {
    midToBottomVal(i) = (midToBottom(i)*bottom) + (((midToBottom(i)*-1)+1)*mid);
    midToBottom(i) = (band-(i+1))/(band-1);

    midToTopVal(i) = (midToTop(i)*top) + (((midToTop(i)*-1)+1)*mid);
    midToTop(i) = (i+1-band)/(nrBands-band);
  };
