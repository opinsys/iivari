#!/bin/sh
# turn info-tv display off
export DISPLAY=:0.0
xset dpms force standby

# write status to hidden text file (for tests)
echo 'off' > .iivari-power-status
