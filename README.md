LookaheadLimiter
================

A clean yet fast lookahead limiter written in faust.

It uses somewhat of a 'brute force' algorithm , so it's quite CPU-hungry.

Usage:
------

###threshold

The maximum output level.

###attack

0 gives a linear attack, 1 a strongly exponential one.

###hold time

The release phase is not started if any of the samples within the hold time is above the threshold.

###lin release

The maximum release rate expressed in dB/sec, so higher numbers equal a faster release.

###log release

Time constant in ms (1/e smoothing time) for the compression gain to approach (exponentially) a new higher target level (the compression 'releasing')

