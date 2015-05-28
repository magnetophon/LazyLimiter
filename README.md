LookaheadLimiter
================

A clean yet fast lookahead limiter written in Faust.

It uses somewhat of a 'brute force' algorithm , so it's quite CPU-hungry.

###features

* brick-wall limiter
* starts fading down before each peak
* fade down can be anything between linear, and strongly exponential
  linear sounds cleaner, exponential punchier/louder
* will not start fading up if we need to be down at least the same amount soon
* the release allows for the usual trade-off between clean and loud


In combination, these features provide the holy grail of limiters: fast reaction on peaks, yet hardly any distortion on sustained material.
Sine waves even have zero distortion down to the very low bass, at any level.

The cost is heavy CPU usage, and a lot of latency (23 ms by default)

Usage:
------

## distortion control
this section controls the amount of distortion, versus the amount of GR
### input gain
input gain in dB 
### threshold
maximum output level in dB
### attack shape
0 gives a linear attack (slow), 1 a strongly exponential one (fast)
this is how the curve of the attack varies it's shape:
![](https://github.com/magnetophon/LookaheadLimiter/blob/master/attack.gif)
### minimum release time
minimum time in ms for the GR to go up
### stereo link
0 means independent, 1 fully linked

## dynamic hold
the GR will not go up if it has to be back here within the hold time
### maximum hold time
maximum hold time in ms
### minimum hold time
minimum hold time in ms
### dynHold
shorten the hold time when the GR is below AVG
### dynHoldPow
shape the curve of the hold time
### dynHoldDiv
scale the curve of the hold time

##  musical release
this section fine tunes the release to sound musical
### base release rate
release rate when the GR is at AVG, in dB/s
### transient speed
speed up the release when the GR is below AVG 
### anti pump
slow down the release when the GR is above AVG 
###  AVG attack 
time in ms for the AVG to go down 
###  AVG release 
time in ms for the AVG to go up

## metering section:
### gain reduction in dB
### average gain reduction in dB
### hold time in ms

Inner workings:
---------------
As with any lookahead limiter, there is a block calculating the gain reduction (GR), and that value is multiplied with the delayed signal.

In this block-diagram, the lookahead time has been set to 4 samples, and it's a simplified implementation.
The actual limiter uses 8192 at a samplerate of 44100, and even more at higher samplerates.

Inside the gain computer, there are 3 blocks doing the work: attackGR, hold and releaseEnv.


###attackGR

The attack is calculated as follows:
-currentdown represents the amount of decibels we need to go down for the current input sample to stay below the threshold.
-we make an array of 4, as follows:
    currentdown@1*(1/4)
    currentdown@2*(2/4)
    currentdown@3*(3/4)
    currentdown@4*(4/4)
-we take the minimum value of this array
-eventually, we do:
attackGR_with_hold_and_releaseEnv:db2linear*audio@4;
In effect, we have created at linear (in dB) fade-down with a duration of 4 samples, with the loudest sample ending up at exactly the threshold.

###hold

Hold works as follows:
-lastdown represents the amount of decibels we where down at the previous sample, iow a feedback loop coming from the end of the gain calculater.
-we make an array of 4, as follows:
(currentdown@(0):max(lastdown))
(currentdown@(1):max(lastdown))
(currentdown@(2):max(lastdown))
(currentdown@(3):max(lastdown))
-again we take the minimum of these values.
-in plain English: we check if any of the coming samples needs the same or more gain reduction then we currently have, and if so, we stay down.

###releaseEnv

We take the minimum of attack and hold, and enter it into the release function, which is just a 0 attack, logarithmic release envelope follower.
This is the signal that is multiplied with the delayed audio, as mentioned in the explanation of attack.

## further details

You can choose the maximum attack and hold time at compile time by changing maxAttackTime and maxHoldTime respectively.
I've made the shape of the attack curve variable, by putting a wave-shaping function called attackShaper after the "1/4 trough 4/4" of the attack example.
I've also made the hold time variable at run time.

## Thanks
I got a lot of [inspiration](https://github.com/sampov2/foo-plugins/blob/master/src/faust-source/compressor-basics.dsp#L126-L139) from Sampo Savolainens [foo-plugins](https://github.com/sampov2/foo-plugins).

My first implementation was a lot like the blockdiagram in the explantion; at usable predelay values it ate CPU's for breakfast.
[Yann Orlarey](http://www.grame.fr/qui-sommes-nous/compositeurs-associes/yann-orlarey) provided the brainpower to replace the cpu-power and made this thing actually usable!

Many thanks, also to the rest of the Faust team!
