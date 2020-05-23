import("stdfaust.lib");
import("slidingReduce.lib");

process = GR@totalLatency,smoothGRl(GR);

// maxAttack = 128;

// TODO:
// get to GR earlier, then for the last bit, xfade from dir to pos.
// - ramp of 64 samples towards GR:slidingMin(32)
//
//better separate out the attack and release
// release: xfade from dir
// trigger of each ramp compares itself to the un-shaped version and to the shaped versions of the others

// make separate transient stage and slow release, loke pro-L:
// Apart from the fast 'transient' stage, the limiter has a slower 'release' stage that responds to the overall dynamics of the incoming audio.
// The Attack and Release knobs control how quickly and heavily the release stage sets in. Shorter attack times will allow the release stage
// to set in sooner; longer release times will cause it to have more effect.
// In general, short attack times and long release times are safer and cleaner, but they can also cause pumping and reduce clarity. On the


t= hslider("time", 0.1, 0, 1, 0.001);
noiseLVL = hslider("noise", 0, 0, 1, 0.01);
rate = hslider("rate", 20, 10, 20000, 10);

// expo = 3; // for block diagram
// expo = 6; // 64 samples, 1.3 ms at 48k
expo = 7; // 128 samples, 2.6 ms at 48k
// expo = 8; // 256 samples, 5.3 ms at 48k, the max lookahead of fabfilter pro-L is 5ms
// TODO sAndH(reset) parameters
smoothGRl(GR) = FB~(_,_) :(_,!)
with {
  FB(prev,oldDownSpeed) =
    par(i, expo, fade(i)):ro.interleave(2,expo)
    :((minN(expo):attOrRelease(GR)),maxN(expo))
// ,( rampOne(0) * speed(0))
  with {
  new(i) = lowestGRblock(GR,size(i))@(totalLatency-size(i));
  newH(i) = new(i):ba.sAndH( reset(i)| (attPhase(prev)==0) );
  prevH(i) = prev:ba.sAndH( reset(i)| (attPhase(prev)==0) );
  reset(i) =
    (newDownSpeed(i) > currentDownSpeed) | (prev<=(lowestGRblock(GR,size(0))'));
  fade(i) =
    crossfade(currentPosAndDir(i),newH(i) ,ramp(size(i),reset(i)):rampShaper(i)) // crossfade from current direction to new position
// crossfade(prevH(i),newH(i) ,ramp(size(i),reset(i)):rampShaper(i)) // TODO crossfade from current direction to new position
// crossfade(prevH(i),newH(i) ,ramp(size(i),reset(i))) // TODO crossfade from current direction to new position
    :min(GR@totalLatency)//brute force fade of 64 samples not needed for binary tree attack ?
// sample and hold oldDownSpeed:
  , (select2((newDownSpeed(i) > currentDownSpeed),currentDownSpeed ,newDownSpeed(i)));
  rampShaper(i) = _:pow(power(i))*mult(i):max(smallestRamp(reset(i)));
  power(i) = LinArrayParametricMid(hslider("power bottom", 1, 0.01, 10, 0.01),hslider("power mid", 1, 0.01, 10, 0.01),hslider("power band", (expo/2)-1, 0, expo, 1),hslider("power top", 0.5, 0.01, 10, 0.01),i,expo);
  mult(i) = 1;// LinArrayParametricMid(hslider("mult bottom", 1, 0.001, 1 ,0.001),hslider("mult mid", 1, 0.001, 1 ,0.001),hslider("mult band", (expo/2)-1, 0, expo, 1),hslider("mult top", 1, 0.001, 1 ,0.001),i,expo);
// currentPosAndDir(i) = prevH(i)-( ramp(size(i),reset(i)) * hslider("ramp", 0, 0, 1, 0.01) * (prevH(i)'-prevH(i)));
currentPosAndDir(i) = prevH(i)-( rampOne(i) * speed(i));
rampOne(i) = (select2(reset(i),_+1,1):min(size(i)))~_;
speed(i) = (prev-prev'):ba.sAndH( reset(i)| (attPhase(prev)==0) );
// speed(i) = (prev-prev'):ba.sAndH( reset(i) );
// newDownSpeed(i) = (select2(checkbox("newdown"),prev,(prev'-currentDownSpeed)) -new(i) )/size(i);
newDownSpeed(i) = (prev -new(i) )/size(i);
currentDownSpeed = oldDownSpeed*(speedIsZero==0);
// speedIsZero = (prev==GR@(totalLatency)) ; // TODO: needs more checks, not attack
// speedIsZero = (prev==prev') ;
speedIsZero = select2(checkbox("speed"),(prev==GR@(totalLatency)),(prev==prev'));
// speedIsZero = select2(checkbox("speed"),(prev==GR@(totalLatency+1)),(prev==prev'));
size(i) = pow(2,(expo-i));
// attOrRelease(GR,newGR) = select2(attPhase(prev) ,lowestGRblock(GR,size(0)),newGR);
attOrRelease(GR,newGR) = select2(newGR<=lowestGRblock(GR,size(0)),newGR,lowestGRblock(GR,size(0)));
  }; // ^^ needs prev and oldDownSpeed
  attPhase(prev) = lowestGRblock(GR,totalLatency)<prev;
  lowestGRblock(GR,size) = GR:slidingMinN(size,totalLatency);


  // ramp from 1/n to 1 in n samples.  (don't start at 0 cause when the ramp restarts, the crossfade should start right away)
  // when reset == 1, go back to 0.
  // ramp(n,reset) = select2(reset,_+(1/n):min(1),0)~_;
  ramp(n,reset) = select2(reset,_+(1/n):min(1),1/n)~_;
  smallestRamp(reset)  = select2(reset,_+(small):min(1),small)~_ with {
    small = pow(2,-23);
};


  crossfade(a,b,x) = it.interpolate_linear(x,a,b);  // faster then: a*(1-x) + b*x;

  minN(n) = opWithNInputs(min,n);
  maxN(n) = opWithNInputs(max,n);
  // opWithNInputs()
  opWithNInputs =
    case {
      (op,0) => 0:!;
        (op,1) => _;
      (op,2) => op;
      (op,N) => (opWithNInputs(op,N-1),_) : op;
    };
};



LinArrayParametricMid(bottom,mid,band,top,element,nrElements) =
  select2(band<=element +1,midToBottomVal(element), midToTopVal(element))
with {
  midToBottomVal(element) = (midToBottom(element)*bottom) + (((midToBottom(element)*-1)+1)*mid);
  midToBottom(element) = (band-(element +1))/(band-1);

  midToTopVal(element) = (midToTop(element)*top) + (((midToTop(element)*-1)+1)*mid);
  midToTop(element) = (element +1-band)/(nrElements-band);
};

attackBruteForce =
  case {
    (GR,0) => GR/(maxAttack+1);
    (GR,n) => min(attack(GR,n-1), GR@n/(maxAttack-n+1));
  };

// totalLatency = maxAttack;
totalLatency = pow(2,expo);
GR = vgroup("GR", no.lfnoise0(totalLatency * 8 *t * (no.lfnoise0(totalLatency/2):max(0.1) )):pow(3)*(1-noiseLVL) +(no.lfnoise(rate):pow(3) *noiseLVL):min(0)) ;
