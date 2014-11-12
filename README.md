LookaheadLimiter
================

A clean yet fast lookahead limiter written in faust.

It uses somewhat of a 'brute force' algorithm , so it's quite CPU-hungry.

Usage:
------

###threshold

The maximum output level.

###attack shape

0 gives a linear attack, 1 a strongly exponential one.

###hold time

The release phase is not started if any of the samples within the hold time needs more gain reduction then we currently have.
This greatly reduces distortion while 

###release time

Time constant in ms (1/e smoothing time) for the compression gain to approach (exponentially) a new higher target level (the compression 'releasing')

###release shape



Inner workings:
---------------

Conceptually, there are 3 blocks doing the work: attack, hold and release.
The attack and hold are implemented in the same function, called LookaheadSeq. (seq for sequential, I also have a parallel implementation)
The release is implemented in releaseEnv.

If you want to look at the block-diagram, I recommend changing  maxAttackTime and maxHoldTime to a low value, otherwise you get huge block-diagrams for LookaheadSeq and LookaheadPar.
In the examples below I've chosen 4 for both.

###attack

The attack is calculated as follows:
-currentdown represents the amount of decibels we need to go down for the current input sample to stay below the threshold.
-we make an array of 4, as follows:
    currentdown@1*(1/4)
    currentdown@2*(2/4)
    currentdown@3*(3/4)
    currentdown@4*(4/4)
-we take the minimum value of this array (let's call that value attack for now)
-eventually, after hold and release have taken their effect, we do:
attack_with_hold_and_release:db2linear*audio@4;
In effect, we have created at linear (in dB) fade-down with a duration of 4 samples.

###hold

Hold works as follow:
-lastdown represents the amount of decibels we where down at the previous sample, iow a feedback loop coming from the end of the gain calculater.
-we make an array of 4, as follows:
(currentdown@(0):max(lastdown))
(currentdown@(1):max(lastdown))
(currentdown@(2):max(lastdown))
(currentdown@(3):max(lastdown))
-again we take the minimum of these values.
-in plain English: we check if any of the coming samples needs the same or more gain reduction then we currently have, and if so, we stay down.

###release

We take the minimum of attack and hold, and enter it into the release function, which is just a 0 attack, logarithmic release envelope follower.
This is the signal that is multiplied with the delayed audio, as mentioned in the explanation of attack.

###further details

You can choose the maximum attack and hold time at compile time by changing maxAttackTime and maxHoldTime respectively.
I've made the shape of the attack curve variable, by putting a wave-shaping function called attackShaper after the "1/4 trough 4/4" of the attack example.
I've also made the hold time variable at run time.


This algorithm only starts working properly when using big predelays: ideally maxAttackTime = 1024 and maxHoldTime = 1024 up to 4096.
