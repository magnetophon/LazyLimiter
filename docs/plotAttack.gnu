reset
set term gif animate
set output "attack.gif"

attackShaper(x,attack)= tanh(x**((attack+1)**7)*(attack*5+.1))/tanh(attack*5+.1)

n=50 #n frames
dt=0.02
set xrange [0:1]
do for [i=0:n]{
  plot attackShaper(x,i*dt) title sprintf("attack percentage: %i",i*2)
  }
set output
