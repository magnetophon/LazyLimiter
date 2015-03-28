LookaheadLimiter
================

A clean yet fast lookahead limiter written in faust.

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

###threshold

The maximum output level.

###attack shape

0 gives a linear attack, 1 a strongly exponential one.

###hold time

The release phase is not started if any of the samples within the hold time needs more gain reduction then we currently have.

###release time

Time constant in ms (1/e smoothing time) for the compression gain to approach (exponentially) a new higher target level (the compression 'releasing')

###release shape

0.2 is a fast release shape, 5 is slow.


Inner workings:
---------------

There are 3 blocks doing the work: attackGR, hold and releaseEnv.

If you want to look at the block-diagram, I recommend changing maxHoldTime to a low value, otherwise you get huge block-diagrams for LookaheadSeq and LookaheadPar.
In the examples below I've chosen 4; by default, it is 1024 (23 ms).

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

###further details

You can choose the maximum attack and hold time at compile time by changing maxAttackTime and maxHoldTime respectively.
I've made the shape of the attack curve variable, by putting a wave-shaping function called attackShaper after the "1/4 trough 4/4" of the attack example.
I've also made the hold time variable at run time.


This algorithm only starts working properly when using big predelays: ideally maxAttackTime = 1024 and maxHoldTime = 1024 up to 4096.
