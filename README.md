A clean yet fast lookahead limiter written in Faust.
It uses somewhat of a 'brute force' algorithm , so it's quite CPU-hungry.

#features

* brick-wall limiter
* starts fading down before each peak
 * fade down can be anything between linear, and strongly exponential
* will not start fading up if it needs to be down at least the same amount soon
* the elaborate auto release algorithm allows you to set a musical trade-off between clean and loud

In combination, these features provide the holy grail of limiters: fast reaction on peaks, yet hardly any distortion on sustained material.
Sine waves even have zero distortion down to the very low bass, at any level.

The cost is heavy CPU usage, and a lot of latency (186 ms by default)

## building and installing:
```
git clone https://github.com/magnetophon/LazyLimiter
cd CharacterCompressor
make
sudo make install
```

#usage:

## minimum gain reduction
There will never be less gain reduction then what these setting dictate.
You can have gain reduction completely without distortion, yet still react quick to transients.
To hear this effect, set the minimum hold time from the next section to full and the anti pump from the 3rd section to 0.  
While very clean and fast, this sound has two problems:  
1. It can be a bit too conservative. The dynamic hold section can fix that.  
2. Simultaneously, it releases to quick in quiet parts. The musical release section fixes that.  
### input gain
Input gain in dB
### threshold
maximum output level in dB
### attack shape
0 gives a linear attack (slow), 1 a strongly exponential one (fast).
Linear sounds cleaner, exponential punchier/louder.  
This is how the curve of the attack varies it's shape:
![](https://github.com/magnetophon/LazyLimiter/raw/master/docs/attack.gif)
### minimum release time
Minimum time in ms for the GR to go up
### stereo link
0 means independent, 1 fully linked

## dynamic hold
The GR will not go up if it has to be back here within the hold time.
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
- gain reduction in dB
- average gain reduction in dB
- hold time in ms

#Inner workings

## conceptual idea
Here is [a block-diagram](https://github.com/magnetophon/LazyLimiter/raw/master/docs/blockDiagram-svg/process.svg) to help explain.
A clickable version can be found at https://magnetophon.github.io/LazyLimiter/.
In this example, the lookahead time has been set to 4 samples, the actual limiter uses 8192 at a samplerate of 44100, and even more at higher samplerates.

As with any lookahead limiter, there is a block calculating the gain reduction (GR), and that value is multiplied with the delayed signal.

Notice that all values inside GainCalculator are in dB:
0dB meaning no gain reduction, and -infinite meaning full gain reduction; silence, and 
In other words, the smaller the value, the more gain reduction.

Inside the GainCalculator, there are 3 blocks doing the work: attackGainReduction, hold and releaseEnvelope.  
1. attackGainReduction calculates gradual fade down towards the eventual gain reduction.  
2. hold makes sure we don't fade back up if we need to be down at least the same amount soon.  
Together they make up minimumGainReduction.  
3. this goes into releaseEnvelope, to tweak the release to be musical.  

###attackGainReduction

The attack is calculated as follows:
- currentdown represents the amount of decibels we need to go down for the current input sample to stay below the threshold.
- we make an array of 4, as follows:
```
    currentdown@1*(1/4)  
    currentdown@2*(2/4)  
    currentdown@3*(3/4)  
    currentdown@4*(4/4)  
```
- we take the minimum value of this array
In effect, we have created a constantly moving linear fade-down with a duration of 4 samples.

###hold

Hold works as follows:
- lastdown represents the amount of decibels we where down at the previous sample, iow a feedback loop coming from the end of the GainCalculator.
- we make an array of 4, as follows:
```
(currentdown@(0):max(lastdown))  
(currentdown@(1):max(lastdown))  
(currentdown@(2):max(lastdown))  
(currentdown@(3):max(lastdown))  
```
- again we take the minimum of these values.
- in plain English: we check if any of the coming samples needs the same or more gain reduction then we currently have, and if so, we stay down.

###releaseEnvelope

We take the minimum of attack and hold, and enter it into the release function, which is just a 0 attack, logarithmic release envelope follower.
This is the signal that is multiplied with the delayed audio, as mentioned in the explanation of attack.

## actual implementation:

You can choose the maximum attack and hold time at compile time by changing [maxAttackTime](https://github.com/magnetophon/LazyLimiter/blob/master/GUI.lib#L38) and [maxHoldTime](https://github.com/magnetophon/LazyLimiter/blob/master/GUI.lib#L30).
This way various compromises between quality and CPU usage can be made.
They are scaled with samplerate, but you have to [manually set it](https://github.com/magnetophon/LazyLimiter/blob/master/GUI.lib#L21) at compile time.

I've made the shape of the attack curve variable, by putting a wave-shaping function after the "1/4 trough 4/4" of the attack example.
Both the hold time and the time of the releaseEnvelope automatically adapt to the input material.

I am looking for ways to reduce the amount of parameters, either by choosing good defaults or by intelligently coupling them.

# Thanks
I got a lot of [inspiration](https://github.com/sampov2/foo-plugins/blob/master/src/faust-source/compressor-basics.dsp#L126-L139) from Sampo Savolainen's [foo-plugins](https://github.com/sampov2/foo-plugins).

My first implementation was a lot like the blockdiagram in the explanation; at usable predelay values it ate CPU's for breakfast.
[Yann Orlarey](http://www.grame.fr/qui-sommes-nous/compositeurs-associes/yann-orlarey) provided [the brainpower to replace the cpu-power](https://github.com/magnetophon/LazyLimiter/blob/master/LazyLimiter.lib#L54-L66) and made this thing actually usable!

Many thanks, also to the rest of the Faust team!
