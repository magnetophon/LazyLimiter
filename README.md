LookaheadLimiter
================

A clean yet fast lookahead limiter written in faust.

It uses a 'brute force' algorithm , so it's quite CPU-hungry.

Usage:
------

###Threshold

the maximum output level.

###punch

0 gives a linear attack, 1 a strongly exponential one.

###stayDown

When 1, this will makes sure the release phase is not started if any of the samples within the lookahead time is above the threshold.

###ratelimit amount

If 0 the maximum decay is infinite.
If 1 the maximum decay is determined by 'max decay'.

###max decay

The maximum decay rate expressed in dB/sec, so higher numbers equal a faster decay.
