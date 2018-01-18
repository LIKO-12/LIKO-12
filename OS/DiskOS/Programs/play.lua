local params = {
  repeatspeed = 0,
  waveform = 0, --*
  envelope = {
    attack = 0,
    sustain = 0.3,
    punch = 0,
    decay = 0.4
  },
  frequency = {
    start = 0.3,
    min = 0,
    slide = 0, --
    dslide = 0 --
  },
  vibrato = {
    depth = 0,
    speed = 0
  },
  change = {
    amount = 0, --
    speed = 0
  },
  duty = {
    ratio = 0,
    sweep = 0 --
  },
  phaser = {
    offset = 0, --
    sweep = 0
  },
  lowpass = {
    cutoff = 1,
    sweep = 0, --
    resonance = 0
  },
  highpass = {
    cutoff = 0,
    sweep = 0 --
  }
}

Audio.play(1,params)

for event,a in pullEvent do
  if event == "keypressed" and a == "escape" then
    break
  elseif event == "keypressed" then
    Audio.play(2,params)
  end
end