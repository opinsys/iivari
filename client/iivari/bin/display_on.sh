#!/bin/sh
# turn info-tv display on
export DISPLAY=:0.0
xset s reset
xset s 0 0
xset s off
xset s noblank
xset dpms 0 0 0
xset -dpms
xset dpms force on

# write status to hidden text file (for tests)
echo 'on' > .iivari-power-status
