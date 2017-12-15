-- sfxr.lua
-- original by Tomas Pettersson, ported to Lua by nucular

--[[
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]--

--[[--
A port of the sfxr sound effect synthesizer to pure Lua, designed to be used
together with the *awesome* [LÖVE](https://love2d.org) game framework.
]]--
-- @module sfxr
local sfxr = {}
local bit = bit32 or require("bit")

-- Constants

--- The module version (SemVer format)
-- @within Constants
sfxr.VERSION = "0.0.2"

--- [Waveform](https://en.wikipedia.org/wiki/Waveform) constants
-- @within Constants
-- @field SQUARE [square wave](https://en.wikipedia.org/wiki/Square_wave) (`= 0`)
-- @field SAW [saw wave](https://en.wikipedia.org/wiki/Sawtooth_wave) (`= 1`)
-- @field SINE [sine wave](https://en.wikipedia.org/wiki/Sine_wave) (`= 2`)
-- @field NOISE [white noise](https://en.wikipedia.org/wiki/White_noise) (`= 3`)
sfxr.WAVEFORM = {
  SQUARE = 0,
  [0] = 0,
  SAW = 1,
  [1] = 1,
  SINE = 2,
  [2] = 2,
  NOISE = 3,
  [3] = 3
}

--- [Sampling rate](https://en.wikipedia.org/wiki/Sampling_(signal_processing)#Sampling_rate) constants
-- (use the number values directly, these are just for lookup)
-- @within Constants
-- @field 22050 22.05 kHz (`= 22050`)
-- @field 44100 44.1 kHz (`= 44100`)
sfxr.SAMPLERATE = {
  [22050] = 22050, --- 22.05 kHz
  [44100] = 44100 --- 44.1 kHz
}

--- [Bit depth](https://en.wikipedia.org/wiki/Audio_bit_depth) constants
-- (use the number values directly, these are just for lookup)
-- @within Constants
-- @field 0 floating point bit depth, -1 to 1 (`= 0`)
-- @field 8 unsigned 8 bit, 0x00 to 0xFF (`= 8`)
-- @field 16 unsigned 16 bit, 0x0000 to 0xFFFF (`= 16`)
sfxr.BITDEPTH = {
  [0] = 0,
  [16] = 16,
  [8] = 8
}

--- [Endianness](https://en.wikipedia.org/wiki/Endianness) constants
-- @within Constants
-- @field LITTLE little endian (`= 0`)
-- @field BIG big endian (`= 1`)
sfxr.ENDIANNESS = {
  LITTLE = 0,
  [0] = 0,
  BIG = 1,
  [1] = 1
}

-- Utilities

--- Truncate a number to an unsigned integer.
-- @tparam number n a (signed) number
-- @treturn int the number, truncated and unsigned
local function trunc(n)
    if n >= 0 then
        return math.floor(n)
    else
        return -math.floor(-n)
    end
end

--- Set the random seed and initializes the generator.
-- @tparam number seed the random seed
local function setseed(seed)
    math.randomseed(seed)
    for i=0, 5 do
        math.random()
    end
end

--- Return a random number between low and high.
-- @tparam number low the lower bound
-- @tparam number high the upper bound
-- @treturn number a random number where `low < n < high`
local function random(low, high)
    return low + math.random() * (high - low)
end

--- Return a random boolean weighted towards false by n.
-- w = 1: uniform distribution
-- w = n: false is n times as likely as true
-- Note: n < 0 do not work, use `not maybe(w)` instead
-- @tparam[opt=1] number w the weight towards false
-- @treturn bool a random boolean
local function maybe(w)
    return trunc(random(0, w or 1)) == 0
end

--- Clamp n between min and max.
-- @tparam number n the number
-- @tparam number min the lower bound
-- @tparam number max the upper bound
-- @treturn number the number where `min <= n <= max`
local function clamp(n, min, max)
    return math.max(min or -math.huge, math.min(max or math.huge, n))
end

--- Copy a table (shallow) or a primitive.
-- @param t a table or primitive
-- @return a copy of t
local function shallowcopy(t)
    if type(t) == "table" then
        local t2 = {}
        for k,v in pairs(t) do
            t2[k] = v
        end
        return t2
    else
        return t
    end
end

--- Recursively merge table t2 into t1.
-- @tparam tab t1 a table
-- @tparam tab t2 a table to merge into t1
-- @treturn tab t1
local function mergetables(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" then
            if type(t1[k] or false) == "table" then
                mergetables(t1[k] or {}, t2[k] or {})
            else
                t1[k] = v
            end
        else
            t1[k] = v
        end
    end
    return t1
end

--- Pack a number into a IEEE754 32-bit big-endian floating point binary string.
-- [source](https://stackoverflow.com/questions/14416734/)
-- @tparam number number a number
-- @treturn string a binary string
local function packIEEE754(number)
	if number == 0 then
		return string.char(0x00, 0x00, 0x00, 0x00)
	elseif number ~= number then
		return string.char(0xFF, 0xFF, 0xFF, 0xFF)
	else
		local sign = 0x00
		if number < 0 then
			sign = 0x80
			number = -number
		end
		local mantissa, exponent = math.frexp(number)
		exponent = exponent + 0x7F
		if exponent <= 0 then
			mantissa = math.ldexp(mantissa, exponent - 1)
			exponent = 0
		elseif exponent > 0 then
			if exponent >= 0xFF then
				return string.char(sign + 0x7F, 0x80, 0x00, 0x00)
			elseif exponent == 1 then
				exponent = 0
			else
				mantissa = mantissa * 2 - 1
				exponent = exponent - 1
			end
		end
		mantissa = math.floor(math.ldexp(mantissa, 23) + 0.5)
		return string.char(
			sign + math.floor(exponent / 2),
			(exponent % 2) * 0x80 + math.floor(mantissa / 0x10000),
			math.floor(mantissa / 0x100) % 0x100,
			mantissa % 0x100)
	end
end

--- Unpack a IEEE754 32-bit big-endian floating point string to a number.
-- [source](https://stackoverflow.com/questions/14416734/)
-- @tparam string packed a binary string
-- @treturn number a number
local function unpackIEEE754(packed)
	local b1, b2, b3, b4 = string.byte(packed, 1, 4)
	local exponent = (b1 % 0x80) * 0x02 + math.floor(b2 / 0x80)
	local mantissa = math.ldexp(((b2 % 0x80) * 0x100 + b3) * 0x100 + b4, -23)
	if exponent == 0xFF then
		if mantissa > 0 then
			return 0 / 0
		else
			mantissa = math.huge
			exponent = 0x7F
		end
	elseif exponent > 0 then
		mantissa = mantissa + 1
	else
		exponent = exponent + 1
	end
	if b1 >= 0x80 then
		mantissa = -mantissa
	end
	return math.ldexp(mantissa, exponent - 0x7F)
end

--- Construct and return a new @{Sound} instance.
-- @treturn Sound a Sound instance
function sfxr.newSound(...)
    local instance = setmetatable({}, sfxr.Sound)
    instance:__init(...)
    return instance
end

--- The main Sound class.
-- @type Sound
sfxr.Sound = {}
sfxr.Sound.__index = sfxr.Sound

--- Initialize the Sound instance.
-- Called by @{sfxr.newSound|the constructor}.
function sfxr.Sound:__init()
    --- Number of supersampling passes to perform (*default* 8)
    -- @within Parameters
    self.supersampling = 8
    --- Repeat speed:
    -- Times to repeat the frequency slide over the course of the envelope
    -- (*default* 0.0, *min* 0.0, *max* 1.0)
    -- @within Parameters
    self.repeatspeed = 0.0
    --- The base @{WAVEFORM|waveform} (*default* @{WAVEFORM|SQUARE})
    -- @within Parameters
    self.waveform = sfxr.WAVEFORM.SQUARE

    -- Build tables to store the parameters in

    --- **The sound volume and gain all samples are multiplied with**
    -- @within Volume
    self.volume = {}
    --- **The [ASD envelope](https://en.wikipedia.org/wiki/Synthesizer#Attack_
    --Decay_Sustain_Release_.28ADSR.29_envelope) that controls the sound
    -- amplitude (volume) over time**
    -- @within Envelope
    self.envelope = {}
    --- **The base and minimum frequencies of the tone generator and their
    -- slides**
    -- @within Frequency
    self.frequency = {}
    --- **A [vibrato](https://en.wikipedia.org/wiki/Vibrato)-like amplitude
    -- modulation effect**
    -- SerializationVibrato
    self.vibrato = {}
    --- **Changes the frequency mid-sound to create a characteristic
    -- "coin"-effect**
    -- @within Change
    self.change = {}
    --- **The [duty](https://en.wikipedia.org/wiki/Duty_cycle) of the square
    -- waveform**
    -- @within Duty
    self.duty = {}
    --- **A simple [phaser](https://en.wikipedia.org/wiki/Phaser_(effect))
    -- effect**
    -- @within Phaser
    self.phaser = {}
    --- **A [lowpass filter](https://en.wikipedia.org/wiki/Low-pass_filter)
    -- effect**
    -- @within Lowpass
    self.lowpass = {}
    --- **A [highpass filter](https://en.wikipedia.org/wiki/High-pass_filter)
    -- effect**
    -- @within Highpass
    self.highpass = {}

    -- These are not affected by resetParameters()

    --- Master volume (*default* 0.5)
    -- @within Volume
    self.volume.master = 0.5
    --- Additional gain (*default* 0.5)
    -- @within Volume
    self.volume.sound = 0.5

    self:resetParameters()
end

--- Set all parameters to their default values. Does not affect
-- @{self.supersampling|supersampling} and @{self.volume|volume}.
-- Called by @{sfxr.Sound:__init|the initializer}.
function sfxr.Sound:resetParameters()
    self.repeatspeed = 0.0
    self.waveform = sfxr.WAVEFORM.SQUARE

    --- Attack time:
    -- Time the sound takes to reach its peak amplitude
    -- (*default* 0.0, *min* 0.0, *max* 1.0)
    -- @within Envelope
    self.envelope.attack = 0.0
    --- Sustain time:
    -- Time the sound stays on its peak amplitude
    -- (*default* 0.0, *min* 0.0, *max* 1.0)
    -- @within Envelope
    self.envelope.sustain = 0.3
    --- Sustain punch:
    -- Amount by which the sound peak amplitude is increased at the start of the
    -- sustain time
    -- (*default* 0.0, *min* 0.0, *max* 1.0)
    -- @within Envelope
    self.envelope.punch = 0.0
    --- Decay time:
    -- Time the sound takes to decay after its sustain time
    -- (*default* 0.0, *min* 0.0, *max* 1.0)
    -- @within Envelope
    self.envelope.decay = 0.4

    --- Start frequency:
    -- Base tone of the sound, before sliding
    -- (*default* 0.0, *min* 0.0, *max* 1.0)
    -- @within Frequency
    self.frequency.start = 0.3
    --- Min frequency:
    -- Tone below which the sound will get cut off
    -- (*default* 0.0, *min* 0.0, *max* 1.0)
    -- @within Frequency
    self.frequency.min = 0.0
    --- Slide:
    -- Amount by which the frequency is increased or decreased over time
    -- (*default* 0.0, *min* -1.0, *max* 1.0)
    -- @within Frequency
    self.frequency.slide = 0.0
    --- Delta slide:
    -- Amount by which the slide is increased or decreased over time
    -- (*default* 0.0, *min* -1.0, *max* 1.0)
    -- @within Frequency
    self.frequency.dslide = 0.0

    --- Vibrato depth:
    -- Amount of amplitude modulation
    -- (*default* 0.0, *min* 0.0, *max* 1.0)
    -- @within Vibrato
    self.vibrato.depth = 0.0
    --- Vibrato speed:
    -- Oscillation speed of the vibrato
    -- (*default* 0.0, *min* 0.0, *max* 1.0)
    -- @within Vibrato
    self.vibrato.speed = 0.0
    --- Vibrato delay:
    -- Unused and unimplemented
    -- (*default* 0.0, *min* 0.0, *max* 1.0)
    -- @within Vibrato
    self.vibrato.delay = 0.0

    --- Change amount:
    -- Amount by which the frequency is changed mid-sound
    -- (*default* 0.0, *min* -1.0, *max* 1.0)
    -- @within Change
    self.change.amount = 0.0
    --- Change speed:
    -- Time before the frequency change happens
    -- (*default* 0.0, *min* 0.0, *max* 1.0)
    -- @within Change
    self.change.speed = 0.0

    --- Square duty:
    -- Width of the square wave pulse cycle (doesn't affect other waveforms)
    -- (*default* 0.0, *min* 0.0, *max* 1.0)
    -- @within Duty
    self.duty.ratio = 0.0
    --- Duty sweep:
    -- Amount by which the square duty is increased or decreased over time
    -- (*default* 0.0, *min* -1.0, *max* 1.0)
    -- @within Duty
    self.duty.sweep = 0.0

    --- Phaser offset:
    -- Amount by which the phaser signal is offset from the sound
    -- (*default* 0.0, *min* -1.0, *max* 1.0)
    -- @within Phaser
    self.phaser.offset = 0.0
    --- Phaser sweep:
    -- Amount by which the phaser offset is increased or decreased over time
    -- (*default* 0.0, *min* -1.0, *max* 1.0)
    -- @within Phaser
    self.phaser.sweep = 0.0

    --- Lowpass filter cutoff:
    -- Lower bound for frequencies allowed to pass through this filter
    -- (*default* 0.0, *min* 0.0, *max* 1.0)
    -- @within Lowpass
    self.lowpass.cutoff = 1.0
    --- Lowpass filter cutoff sweep:
    -- Amount by which the LP filter cutoff is increased or decreased
    -- over time
    -- (*default* 0.0, *min* -1.0, *max* 1.0)
    -- @within Lowpass
    self.lowpass.sweep = 0.0
    --- Lowpass filter resonance:
    -- Amount by which certain resonant frequencies near the cutoff are
    -- increased
    -- (*default* 0.0, *min* 0.0, *max* 1.0)
    -- @within Lowpass
    self.lowpass.resonance = 0.0
    --- Highpass filter cutoff:
    -- Upper bound for frequencies allowed to pass through this filter
    -- (*default* 0.0, *min* 0.0, *max* 1.0)
    -- @within Highpass
    self.highpass.cutoff = 0.0
    --- Highpass filter cutoff sweep:
    -- Amount by which the HP filter cutoff is increased or decreased
    -- over time
    -- (*default* 0.0, *min* -1.0, *max* 1.0)
    -- @within Highpass
    self.highpass.sweep = 0.0
end

--- Clamp all parameters within their sane ranges.
function sfxr.Sound:sanitizeParameters()
    self.repeatspeed = clamp(self.repeatspeed, 0, 1)
    self.waveform = clamp(self.waveform, 0, #sfxr.WAVEFORM)

    self.envelope.attack = clamp(self.envelope.attack, 0, 1)
    self.envelope.sustain = clamp(self.envelope.sustain, 0, 1)
    self.envelope.punch = clamp(self.envelope.punch, 0, 1)
    self.envelope.decay = clamp(self.envelope.decay, 0, 1)

    self.frequency.start = clamp(self.frequency.start, 0, 1)
    self.frequency.min = clamp(self.frequency.min, 0, 1)
    self.frequency.slide = clamp(self.frequency.slide, -1, 1)
    self.frequency.dslide = clamp(self.frequency.dslide, -1, 1)

    self.vibrato.depth = clamp(self.vibrato.depth, 0, 1)
    self.vibrato.speed = clamp(self.vibrato.speed, 0, 1)
    self.vibrato.delay = clamp(self.vibrato.delay, 0, 1)

    self.change.amount = clamp(self.change.amount, -1, 1)
    self.change.speed = clamp(self.change.speed, 0, 1)

    self.duty.ratio = clamp(self.duty.ratio, 0, 1)
    self.duty.sweep = clamp(self.duty.sweep, -1, 1)

    self.phaser.offset = clamp(self.phaser.offset, -1, 1)
    self.phaser.sweep = clamp(self.phaser.sweep, -1, 1)

    self.lowpass.cutoff = clamp(self.lowpass.cutoff, 0, 1)
    self.lowpass.sweep = clamp(self.lowpass.sweep, -1, 1)
    self.lowpass.resonance = clamp(self.lowpass.resonance, 0, 1)
    self.highpass.cutoff = clamp(self.highpass.cutoff, 0, 1)
    self.highpass.sweep = clamp(self.highpass.sweep, -1, 1)
end

--- Generate the sound and yield the sample data.
-- @tparam[opt=44100] SAMPLERATE rate the sampling rate
-- @tparam[opt=0] BITDEPTH depth the bit depth
-- @treturn function() a generator that yields the next sample when called
-- @usage for s in sound:generate(44100, 0) do
--   -- do something with s
-- end
-- @raise "invalid sampling rate: x", "invalid bit depth: x"
function sfxr.Sound:generate(rate, depth)
    rate = rate or 44100
    depth = depth or 0
    assert(sfxr.SAMPLERATE[rate], "invalid sampling rate: " .. tostring(rate))
    assert(sfxr.BITDEPTH[depth], "invalid bit depth: " .. tostring(depth))

    -- Initialize all locals
    local fperiod, maxperiod
    local slide, dslide
    local square_duty, square_slide
    local chg_mod, chg_time, chg_limit

    local phaserbuffer = {}
    local noisebuffer = {}

    -- Initialize the sample buffers
    for i=1, 1024 do
        phaserbuffer[i] = 0
    end

    for i=1, 32 do
        noisebuffer[i] = random(-1, 1)
    end

    --- Reset the sound period
    local function reset()
        fperiod = 100 / (self.frequency.start^2 + 0.001)
        maxperiod = 100 / (self.frequency.min^2 + 0.001)
        period = trunc(fperiod)

        slide = 1.0 - self.frequency.slide^3 * 0.01
        dslide = -self.frequency.dslide^3 * 0.000001

        square_duty = 0.5 - self.duty.ratio * 0.5
        square_slide = -self.duty.sweep * 0.00005

        if self.change.amount >= 0 then
            chg_mod = 1.0 - self.change.amount^2 * 0.9
        else
            chg_mod = 1.0 + self.change.amount^2 * 10
        end

        chg_time = 0
        if self.change.speed == 1 then
            chg_limit = 0
        else
            chg_limit = trunc((1 - self.change.speed)^2 * 20000 + 32)
        end
    end

    local phase = 0
    reset()

    local second_sample = false

    local env_vol = 0
    local env_stage = 1
    local env_time = 0
    local env_length = {self.envelope.attack^2 * 100000,
        self.envelope.sustain^2 * 100000,
        self.envelope.decay^2 * 100000}

    local fphase = self.phaser.offset^2 * 1020
    if self.phaser.offset < 0 then fphase = -fphase end
    local dphase = self.phaser.sweep^2
    if self.phaser.sweep < 0 then dphase = -dphase end
    local ipp = 0

    local iphase = math.abs(trunc(fphase))

    local fltp = 0
    local fltdp = 0
    local fltw = self.lowpass.cutoff^3 * 0.1
    local fltw_d = 1 + self.lowpass.sweep * 0.0001
    local fltdmp = 5 / (1 + self.lowpass.resonance^2 * 20) * (0.01 + fltw)
    fltdmp = clamp(fltdmp, nil, 0.8)
    local fltphp = 0
    local flthp = self.highpass.cutoff^2 * 0.1
    local flthp_d = 1 + self.highpass.sweep * 0.0003

    local vib_phase = 0
    local vib_speed = self.vibrato.speed^2 * 0.01
    local vib_amp = self.vibrato.depth * 0.5

    local rep_time = 0
    local rep_limit = trunc((1 - self.repeatspeed)^2 * 20000 + 32)
    if self.repeatspeed == 0 then
        rep_limit = 0
    end

    -- The main closure (returned as a generator)

    local function next()
        -- Repeat when needed
        rep_time = rep_time + 1
        if rep_limit ~= 0 and rep_time >= rep_limit then
            rep_time = 0
            reset()
        end

        -- Update the change time and apply it if needed
        chg_time = chg_time + 1
        if chg_limit ~= 0 and chg_time >= chg_limit then
            chg_limit = 0
            fperiod = fperiod * chg_mod
        end

        -- Apply the frequency slide and stuff
        slide = slide + dslide
        fperiod = fperiod * slide

        if fperiod > maxperiod then
            fperiod = maxperiod
            -- Fail if the minimum frequency is too small
            if (self.frequency.min > 0) then
                return nil
            end
        end

        -- Vibrato
        local rfperiod = fperiod
        if vib_amp > 0 then
            vib_phase = vib_phase + vib_speed
            -- Apply to the frequency period
            rfperiod = fperiod * (1.0 + math.sin(vib_phase) * vib_amp)
        end

        -- Update the period
        period = trunc(rfperiod)
        if (period < 8) then period = 8 end

        -- Update the square duty
        square_duty = clamp(square_duty + square_slide, 0, 0.5)

        -- Volume envelopes

        env_time = env_time + 1

        if env_time > env_length[env_stage] then
            env_time = 0
            env_stage = env_stage + 1
            -- After the decay stop generating
            if env_stage == 4 then
                return nil
            end
        end

        -- Attack, Sustain, Decay/Release
        if env_stage == 1 then
            env_vol = env_time / env_length[1]
        elseif env_stage == 2 then
            env_vol = 1 + (1 - env_time / env_length[2])^1 * 2 * self.envelope.punch
        elseif env_stage == 3 then
            env_vol = 1 - env_time / env_length[3]
        end

        -- Phaser

        fphase = fphase + dphase
        iphase = clamp(math.abs(trunc(fphase)), nil, 1023)

        -- Filter stuff

        if flthp_d ~= 0 then
            flthp = clamp(flthp * flthp_d, 0.00001, 0.1)
        end

        -- And finally the actual tone generation and supersampling

        local ssample = 0
        for si = 0, self.supersampling-1 do
            local sample = 0

            phase = phase + 1

            -- fill the noise buffer every period
            if phase >= period then
                --phase = 0
                phase = phase % period
                if self.waveform == sfxr.WAVEFORM.NOISE then
                    for i = 1, 32 do
                        noisebuffer[i] = random(-1, 1)
                    end
                end
            end

            -- Tone generators ahead

            local fp = phase / period

            -- Square, including square duty
            if self.waveform == sfxr.WAVEFORM.SQUARE then
                if fp < square_duty then
                    sample = 0.5
                else
                    sample = -0.5
                end

            -- Sawtooth
            elseif self.waveform == sfxr.WAVEFORM.SAWTOOTH then
                sample = 1 - fp * 2

            -- Sine
            elseif self.waveform == sfxr.WAVEFORM.SINE then
                sample = math.sin(fp * 2 * math.pi)

            -- Pitched white noise
            elseif self.waveform == sfxr.WAVEFORM.NOISE then
                sample = noisebuffer[trunc(phase * 32 / period) % 32 + 1]
            end

            -- Apply the lowpass filter to the sample

            local pp = fltp
            fltw = clamp(fltw * fltw_d, 0, 0.1)
            if self.lowpass.cutoff ~= 1 then
                fltdp = fltdp + (sample - fltp) * fltw
                fltdp = fltdp - fltdp * fltdmp
            else
                fltp = sample
                fltdp = 0
            end
            fltp = fltp + fltdp

            -- Apply the highpass filter to the sample

            fltphp = fltphp + (fltp - pp)
            fltphp = fltphp - (fltphp * flthp)
            sample = fltphp

            -- Apply the phaser to the sample

            phaserbuffer[bit.band(ipp, 1023) + 1] = sample
            sample = sample + phaserbuffer[bit.band(ipp - iphase + 1024, 1023) + 1]
            ipp = bit.band(ipp + 1, 1023)

            -- Accumulation and envelope application
            ssample = ssample + sample * env_vol
        end

        -- Apply the volumes
        ssample = (ssample / self.supersampling) * self.volume.master
        ssample = ssample * (2 * self.volume.sound)

        -- Hard limit
        ssample = clamp(ssample, -1, 1)

        -- Frequency conversion
        second_sample = not second_sample
        if rate == 22050 and second_sample then
            -- hah!
            local nsample = next()
            if nsample then
                return (ssample + nsample) / 2
            else
                return nil
            end
        end

        -- bit conversions
        if depth == 0 then
            return ssample
        elseif depth == 16 then
            return trunc(ssample * 32000)
        else
            return trunc(ssample * 127 + 128)
        end
    end

    return next
end

--- Get the maximum sample limit allowed by the current envelope.
-- Does not take any other limits into account, so the returned count might be
-- higher than samples actually generated. Still useful though.
-- @tparam[opt=44100] SAMPLERATE rate the sampling rate
-- @raise "invalid sampling rate: x", "invalid bit depth: x"
function sfxr.Sound:getEnvelopeLimit(rate)
    rate = rate or 44100
    assert(sfxr.SAMPLERATE[rate], "invalid sampling rate: " .. tostring(rate))

    local env_length = {
        self.envelope.attack^2 * 100000, --- attack
        self.envelope.sustain^2 * 100000, --- sustain
        self.envelope.decay^2 * 100000 --- decay
    }
    local limit = trunc(env_length[1] + env_length[2] + env_length[3] + 2)

    return math.ceil(limit / (rate / 44100))
end

--- Generate the sound into a table.
-- @tparam[opt=44100] SAMPLERATE rate the sampling rate
-- @tparam[opt=0] BITDEPTH depth the bit depth
-- @tparam[opt] {} tab the table to synthesize into
-- @treturn {number,...} the table filled with sample data
-- @treturn int the number of written samples (== #tab)
-- @raise "invalid sampling rate: x", "invalid bit depth: x"
function sfxr.Sound:generateTable(rate, depth, tab)
    rate = rate or 44100
    depth = depth or 0
    assert(sfxr.SAMPLERATE[rate], "invalid sampling rate: " .. tostring(rate))
    assert(sfxr.BITDEPTH[depth], "invalid bit depth: " .. tostring(depth))

    -- this could really use table pre-allocation, but Lua doesn't provide that
    local t = tab or {}
    local i = 1
    for v in self:generate(rate, depth) do
        t[i] = v
        i = i + 1
    end
    return t, i
end

--- Generate the sound to a binary string.
-- @tparam[opt=44100] SAMPLERATE rate the sampling rate
-- @tparam[opt=16] BITDEPTH depth the bit depth (may not be @{BITDEPTH|0})
-- @tparam[opt=0] ENDIANNESS endianness the endianness (ignored when depth == 8)
-- @treturn string a binary string of sample data
-- @treturn int the number of written samples
-- @raise "invalid sampling rate: x", "invalid bit depth: x", "invalid endianness: x"
function sfxr.Sound:generateString(rate, depth, endianness)
    rate = rate or 44100
    depth = depth or 16
    endianness = endianness or 0
    assert(sfxr.SAMPLERATE[rate], "invalid sampling rate: " .. tostring(rate))
    assert(sfxr.BITDEPTH[depth] and depth ~= 0, "invalid bit depth: " .. tostring(depth))
    assert(sfxr.ENDIANNESS[endianness], "invalid endianness: " .. tostring(endianness))

    local s = ""
    --- buffer for arguments to string.char
    local buf = {}
    buf[100] = 0
    local bi = 1

    local i = 0
    for v in self:generate(rate, depth) do
        if depth == 8 then
            buf[i] = v
            bi = bi + 1
        else
            if endianness == sfxr.ENDIANNESS.BIG then
                buf[bi] = bit.rshift(v, 8)
                buf[bi + 1] = bit.band(v, 0xFF)
                bi = bi + 2
            else
                buf[bi] = bit.band(v, 0xFF)
                buf[bi + 1] = bit.rshift(v, 8)
                bi = bi + 2
            end
        end

        if bi >= 100 then
            s = s .. string.char(unpack(buf))
            bi = 0
        end
        i = i + 1
    end

    -- pass in up to 100 characters
    s = s .. string.char(unpack(buf, i, 100))
    return s, i
end

--- Synthesize the sound to a LÖVE SoundData instance.
-- @tparam[opt=44100] SAMPLERATE rate the sampling rate
-- @tparam[opt=0] BITDEPTH depth the bit depth
-- @tparam[opt] love.sound.SoundData sounddata a SoundData instance (will be
-- created if not passed)
-- @treturn love.sound.SoundData a SoundData instance
-- @treturn int the number of written samples
-- @raise "invalid sampling rate: x", "invalid bit depth: x"
function sfxr.Sound:generateSoundData(rate, depth, sounddata)
    rate = rate or 44100
    depth = depth or 0
    assert(sfxr.SAMPLERATE[rate], "invalid sampling rate: " .. tostring(rate))
    assert(sfxr.BITDEPTH[depth] and depth, "invalid bit depth: " .. tostring(depth))

    local tab, count = self:generateTable(rate, depth)

    if count == 0 then
        return nil
    end

    local data = sounddata or love.sound.newSoundData(count, freq, bits, 1)

    for i = 0, #tab - 1 do
        data:setSample(i, tab[i + 1])
    end

    return data, count
end

--- Randomize all sound parameters
-- @within Randomization
-- @tparam[opt] number seed a random seed
function sfxr.Sound:randomize(seed)
    if seed then setseed(seed) end

    local waveform = self.waveform
    self:resetParameters()
    self.waveform = waveform

    if maybe() then
        self.repeatspeed = random(0, 1)
    end

    if maybe() then
        self.frequency.start = random(-1, 1)^3 + 0.5
    else
        self.frequency.start = random(-1, 1)^2
    end
    self.frequency.limit = 0
    self.frequency.slide = random(-1, 1)^5
    if self.frequency.start > 0.7 and self.frequency.slide > 0.2 then
        self.frequency.slide = -self.frequency.slide
    elseif self.frequency.start < 0.2 and self.frequency.slide <-0.05 then
        self.frequency.slide = -self.frequency.slide
    end
    self.frequency.dslide = random(-1, 1)^3

    self.duty.ratio = random(-1, 1)
    self.duty.sweep = random(-1, 1)^3

    self.vibrato.depth = random(-1, 1)^3
    self.vibrato.speed = random(-1, 1)
    self.vibrato.delay = random(-1, 1)

    self.envelope.attack = random(-1, 1)^3
    self.envelope.sustain = random(-1, 1)^2
    self.envelope.punch = random(-1, 1)^2
    self.envelope.decay = random(-1, 1)

    if self.envelope.attack + self.envelope.sustain + self.envelope.decay < 0.2 then
        self.envelope.sustain = self.envelope.sustain + 0.2 + random(0, 0.3)
        self.envelope.decay = self.envelope.decay + 0.2 + random(0, 0.3)
    end

    self.lowpass.resonance = random(-1, 1)
    self.lowpass.cutoff = 1 - random(0, 1)^3
    self.lowpass.sweep = random(-1, 1)^3
    if self.lowpass.cutoff < 0.1 and self.lowpass.sweep < -0.05 then
        self.lowpass.sweep = -self.lowpass.sweep
    end
    self.highpass.cutoff = random(0, 1)^3
    self.highpass.sweep = random(-1, 1)^5

    self.phaser.offset = random(-1, 1)^3
    self.phaser.sweep = random(-1, 1)^3

    self.change.speed = random(-1, 1)
    self.change.amount = random(-1, 1)

    self:sanitizeParameters()
end

--- Mutate all sound parameters
-- @within Randomization
-- @tparam[opt=1] number amount by how much to mutate the parameters
-- @tparam[opt] number seed a random seed
-- @tparam[changefreq=true] bool changefreq whether to change the frequency parameters
function sfxr.Sound:mutate(amount, seed, changefreq)
    if seed then setseed(seed) end
    local amount = (amount or 1)
    local a = amount / 20
    local b = (1 - a) * 10
    local changefreq = (changefreq == nil) and true or changefreq

    if changefreq == true then
        if maybe(b) then self.frequency.start = self.frequency.start + random(-a, a) end
        if maybe(b) then self.frequency.slide = self.frequency.slide + random(-a, a) end
        if maybe(b) then self.frequency.dslide = self.frequency.dslide + random(-a, a) end
    end

    if maybe(b) then self.duty.ratio = self.duty.ratio + random(-a, a) end
    if maybe(b) then self.duty.sweep = self.duty.sweep + random(-a, a) end

    if maybe(b) then self.vibrato.depth = self.vibrato.depth + random(-a, a) end
    if maybe(b) then self.vibrato.speed = self.vibrato.speed + random(-a, a) end
    if maybe(b) then self.vibrato.delay = self.vibrato.delay + random(-a, a) end

    if maybe(b) then self.envelope.attack = self.envelope.attack + random(-a, a) end
    if maybe(b) then self.envelope.sustain = self.envelope.sustain + random(-a, a) end
    if maybe(b) then self.envelope.punch = self.envelope.punch + random(-a, a) end
    if maybe(b) then self.envelope.decay = self.envelope.decay + random(-a, a) end

    if maybe(b) then self.lowpass.resonance = self.lowpass.resonance + random(-a, a) end
    if maybe(b) then self.lowpass.cutoff = self.lowpass.cutoff + random(-a, a) end
    if maybe(b) then self.lowpass.sweep = self.lowpass.sweep + random(-a, a) end
    if maybe(b) then self.highpass.cutoff = self.highpass.cutoff + random(-a, a) end
    if maybe(b) then self.highpass.sweep = self.highpass.sweep + random(-a, a) end

    if maybe(b) then self.phaser.offset = self.phaser.offset + random(-a, a) end
    if maybe(b) then self.phaser.sweep = self.phaser.sweep + random(-a, a) end

    if maybe(b) then self.change.speed = self.change.speed + random(-a, a) end
    if maybe(b) then self.change.amount = self.change.amount + random(-a, a) end

    if maybe(b) then self.repeatspeed = self.repeatspeed + random(-a, a) end

    self:sanitizeParameters()
end

--- Randomize all sound parameters to generate a "pick up" sound
-- @within Randomization
-- @tparam[opt] number seed a random seed
function sfxr.Sound:randomPickup(seed)
    if seed then setseed(seed) end
    self:resetParameters()
    self.frequency.start = random(0.4, 0.9)
    self.envelope.attack = 0
    self.envelope.sustain = random(0, 0.1)
    self.envelope.punch = random(0.3, 0.6)
    self.envelope.decay = random(0.1, 0.5)

    if maybe() then
        self.change.speed = random(0.5, 0.7)
        self.change.amount = random(0.2, 0.6)
    end
end

--- Randomize all sound parameters to generate a laser sound
-- @within Randomization
-- @tparam[opt] number seed a random seed
function sfxr.Sound:randomLaser(seed)
    if seed then setseed(seed) end
    self:resetParameters()
    self.waveform = trunc(random(0, 3))
    if self.waveform == sfxr.WAVEFORM.SINE and maybe() then
        self.waveform = trunc(random(0, 1))
    end

    if maybe(2) then
        self.frequency.start = random(0.3, 0.9)
        self.frequency.min = random(0, 0.1)
        self.frequency.slide = random(-0.65, -0.35)
    else
        self.frequency.start = random(0.5, 1)
        self.frequency.min = clamp(self.frequency.start - random(0.2, 0.4), 0.2)
        self.frequency.slide = random(-0.35, -0.15)
    end

    if maybe() then
        self.duty.ratio = random(0, 0.5)
        self.duty.sweep = random(0, 0.2)
    else
        self.duty.ratio = random(0.4, 0.9)
        self.duty.sweep = random(-0.7, 0)
    end

    self.envelope.attack = 0
    self.envelope.sustain = random(0.1, 0.3)
    self.envelope.decay = random(0, 0.4)

    if maybe() then
        self.envelope.punch = random(0, 0.3)
    end

    if maybe(2) then
        self.phaser.offset = random(0, 0.2)
        self.phaser.sweep = random(-0.2, 0)
    end

    if maybe() then
        self.highpass.cutoff = random(0, 0.3)
    end
end

--- Randomize all sound parameters to generate an explosion sound
-- @within Randomization
-- @tparam[opt] number seed a random seed
function sfxr.Sound:randomExplosion(seed)
    if seed then setseed(seed) end
    self:resetParameters()
    self.waveform = sfxr.WAVEFORM.NOISE

    if maybe() then
        self.frequency.start = random(0.1, 0.5)
        self.frequency.slide = random(-0.1, 0.3)
    else
        self.frequency.start = random(0.2, 0.9)
        self.frequency.slide = random(-0.2, -0.4)
    end
    self.frequency.start = self.frequency.start^2

    if maybe(4) then
        self.frequency.slide = 0
    end
    if maybe(2) then
        self.repeatspeed = random(0.3, 0.8)
    end

    self.envelope.attack = 0
    self.envelope.sustain = random(0.1, 0.4)
    self.envelope.punch = random(0.2, 0.8)
    self.envelope.decay = random(0, 0.5)

    if maybe() then
        self.phaser.offset = random(-0.3, 0.6)
        self.phaser.sweep = random(-0.3, 0)
    end
    if maybe() then
        self.vibrato.depth = random(0, 0.7)
        self.vibrato.speed = random(0, 0.6)
    end
    if maybe(2) then
        self.change.speed = random(0.6, 0.9)
        self.change.amount = random(-0.8, 0.8)
    end
end

--- Randomize all sound parameters to generate a "power up" sound
-- @within Randomization
-- @tparam[opt] number seed a random seed
function sfxr.Sound:randomPowerup(seed)
    if seed then setseed(seed) end
    self:resetParameters()
    if maybe() then
        self.waveform = sfxr.WAVEFORM.SAWTOOTH
    else
        self.duty.ratio = random(0, 0.6)
    end

    if maybe() then
        self.frequency.start = random(0.2, 0.5)
        self.frequency.slide = random(0.1, 0.5)
        self.repeatspeed = random(0.4, 0.8)
    else
        self.frequency.start = random(0.2, 0.5)
        self.frequency.slide = random(0.05, 0.25)
        if maybe() then
            self.vibrato.depth = random(0, 0.7)
            self.vibrato.speed = random(0, 0.6)
        end
    end
    self.envelope.attack = 0
    self.envelope.sustain = random(0, 0.4)
    self.envelope.decay = random(0.1, 0.5)
end

--- Randomize all sound parameters to generate a hit sound
-- @within Randomization
-- @tparam[opt] number seed a random seed
function sfxr.Sound:randomHit(seed)
    if seed then setseed(seed) end
    self:resetParameters()
    self.waveform = trunc(random(0, 3))

    if self.waveform == sfxr.WAVEFORM.SINE then
        self.waveform = sfxr.WAVEFORM.NOISE
    elseif self.waveform == sfxr.WAVEFORM.SQUARE then
        self.duty.ratio = random(0, 0.6)
    end

    self.frequency.start = random(0.2, 0.8)
    self.frequency.slide = random(-0.7, -0.3)
    self.envelope.attack = 0
    self.envelope.sustain = random(0, 0.1)
    self.envelope.decay = random(0.1, 0.3)

    if maybe() then
        self.highpass.cutoff = random(0, 0.3)
    end
end

--- Randomize all sound parameters to generate a jump sound
-- @within Randomization
-- @tparam[opt] number seed a random seed
function sfxr.Sound:randomJump(seed)
    if seed then setseed(seed) end
    self:resetParameters()
    self.waveform = sfxr.WAVEFORM.SQUARE

    self.duty.value = random(0, 0.6)
    self.frequency.start = random(0.3, 0.6)
    self.frequency.slide = random(0.1, 0.3)

    self.envelope.attack = 0
    self.envelope.sustain = random(0.1, 0.4)
    self.envelope.decay = random(0.1, 0.3)

    if maybe() then
        self.highpass.cutoff = random(0, 0.3)
    end
    if maybe() then
        self.lowpass.cutoff = random(0.4, 1)
    end
end

--- Randomize all sound parameters to generate a "blip" sound
-- @within Randomization
-- @tparam[opt] number seed a random seed
function sfxr.Sound:randomBlip(seed)
    if seed then setseed(seed) end
    self:resetParameters()
    self.waveform = trunc(random(0, 2))

    if self.waveform == sfxr.WAVEFORM.SQUARE then
        self.duty.ratio = random(0, 0.6)
    end

    self.frequency.start = random(0.2, 0.6)
    self.envelope.attack = 0
    self.envelope.sustain = random(0.1, 0.2)
    self.envelope.decay = random(0, 0.2)
    self.highpass.cutoff = 0.1
end

--- Generate and export the audio data to a PCM WAVE file.
-- @within Serialization
-- @tparam ?string|file|love.filesystem.File f a path or file in `wb`-mode
-- (passed files will not be closed)
-- @tparam[opt=44100] SAMPLERATE rate the sampling rate
-- @tparam[opt=0] BITDEPTH depth the bit depth
-- @raise "invalid sampling rate: x", "invalid bit depth: x"
function sfxr.Sound:exportWAV(f, rate, depth)
    rate = rate or 44100
    depth = depth or 16
    assert(sfxr.SAMPLERATE[rate], "invalid sampling rate: " .. tostring(rate))
    assert(sfxr.BITDEPTH[depth] and depth ~= 0, "invalid bit depth: " .. tostring(depth))

    local close = false
    if type(f) == "string" then
        f = io.open(f, "wb")
        close = true
    end

    -- Some utility functions
    function seek(pos)
        if io.type(f) == "file" then
            f:seek("set", pos)
        else
            f:seek(pos)
        end
    end

    function tell()
        if io.type(f) == "file" then
            return f:seek()
        else
            return f:tell()
        end
    end

    function bytes(num, len)
        local str = ""
        for i = 1, len do
            str = str .. string.char(num % 256)
            num = math.floor(num / 256)
        end
        return str
    end

    function w16(num)
        f:write(bytes(num, 2))
    end

    function w32(num)
        f:write(bytes(num, 4))
    end

    function ws(str)
        f:write(str)
    end

    -- These will hold important file positions
    local pos_fsize
    local pos_csize

    -- Start the file by writing the RIFF header
    ws("RIFF")
    pos_fsize = tell()
    w32(0) -- remaining file size, will be replaced later
    ws("WAVE") -- type

    -- Write the format chunk
    ws("fmt ")
    w32(16) -- chunk size
    w16(1) -- compression code (1 = PCM)
    w16(1) -- channel number
    w32(freq) -- sampling rate
    w32(freq * bits / 8) -- bytes per second
    w16(bits / 8) -- block alignment
    w16(bits) -- bits per sample

    -- Write the header of the data chunk
    ws("data")
    pos_csize = tell()
    w32(0) -- chunk size, will be replaced later

    -- Aand write the actual sample data
    local samples = 0

    for v in self:generate(rate, depth) do
        samples = samples + 1

        if depth == 16 then
            -- wrap around a bit
            if v >= 256^2 then v = 0 end
            if v < 0 then v = 256^2 + v end
            w16(v)
        else
            f:write(string.char(v))
        end
    end

    -- Seek back to the stored positions
    seek(pos_fsize)
    w32(pos_csize - 4 + samples * bits / 8) -- remaining file size
    seek(pos_csize)
    w32(samples * bits / 8) -- chunk size

    if close then
        f:close()
    end
end

--- Save the sound parameters to a file as a Lua table
-- @within Serialization
-- @tparam ?string|file|love.filesystem.File f a path or file in `w`-mode
-- (passed files will not be closed)
-- @tparam[opt=true] bool minify whether to minify the output or not
function sfxr.Sound:save(f, minify)
    local close = false
    if type(f) == "string" then
        f = io.open(f, "w")
        close = true
    end

    local code = "local "

    -- we'll compare the current parameters with the defaults
    local defaults = sfxr.newSound()

    -- this part is pretty awful but it works for now
    function store(keys, obj)
        local name = keys[#keys]

        if type(obj) == "number" then
            -- fetch the default value
            local def = defaults
            for i=2, #keys do
                def = def[keys[i]]
            end

            if obj ~= def then
                local k = table.concat(keys, ".")
                if not minify then
                    code = code .. "\n" .. string.rep(" ", #keys - 1)
                end
                code = code .. string.format("%s=%s;", name, obj)
            end

        elseif type(obj) == "table" then
            local spacing = minify and "" or "\n" .. string.rep(" ", #keys - 1)
            code = code .. spacing .. string.format("%s={", name)

            for k, v in pairs(obj) do
                local newkeys = shallowcopy(keys)
                newkeys[#newkeys + 1] = k
                store(newkeys, v)
            end

            code = code .. spacing .. "};"
        end
    end

    store({"s"}, self)
    code = code .. "\nreturn s, \"" .. sfxr.VERSION .. "\""
    f:write(code)

    if close then
        f:close()
    end
end

--- Load the sound parameters from a file containing a Lua table
-- @within Serialization
-- @tparam ?string|file|love.filesystem.File f a path or file in `r`-mode
-- (passed files will not be closed)
-- @raise "incompatible version: x.x.x"
function sfxr.Sound:load(f)
    local close = false
    if type(f) == "string" then
        f = io.open(f, "r")
        close = true
    end

    local code
    if io.type(f) == "file" then
        code = f:read("*a")
    else
        code = f:read()
    end

    local params, version = assert(loadstring(code))()
    -- check version compatibility
    assert(version > sfxr.VERSION, "incompatible version: " .. tostring(version))

    self:resetParameters()
    -- merge the loaded table into the own
    mergetables(self, params)

    if close then
        f:close()
    end
end

--- Save the sound parameters to a file in the sfxr binary format (version 102)
-- @within Serialization
-- @tparam ?string|file|love.filesystem.File f a path or file in `wb`-mode
-- (passed files will not be closed)
function sfxr.Sound:saveBinary(f)
    local close = false
    if type(f) == "string" then
        f = io.open(f, "w")
        close = true
    end

    function writeFloat(x)
        local packed = packIEEE754(x):reverse()
        assert(packed:len() == 4)
        f:write(packed)
    end

    f:write('\x66\x00\x00\x00') -- version 102
    assert(self.waveform < 256)
    f:write(string.char(self.waveform) .. '\x00\x00\x00')
    writeFloat(self.volume.sound)

    writeFloat(self.frequency.start)
    writeFloat(self.frequency.min)
    writeFloat(self.frequency.slide)
    writeFloat(self.frequency.dslide)
    writeFloat(self.duty.ratio)
    writeFloat(self.duty.sweep)

    writeFloat(self.vibrato.depth)
    writeFloat(self.vibrato.speed)
    writeFloat(self.vibrato.delay)

    writeFloat(self.envelope.attack)
    writeFloat(self.envelope.sustain)
    writeFloat(self.envelope.decay)
    writeFloat(self.envelope.punch)

    f:write('\x00') -- unused filter_on boolean
    writeFloat(self.lowpass.resonance)
    writeFloat(self.lowpass.cutoff)
    writeFloat(self.lowpass.sweep)
    writeFloat(self.highpass.cutoff)
    writeFloat(self.highpass.sweep)

    writeFloat(self.phaser.offset)
    writeFloat(self.phaser.sweep)

    writeFloat(self.repeatspeed)

    writeFloat(self.change.speed)
    writeFloat(self.change.amount)

    if close then
        f:close()
    end
end

--- Load the sound parameters from a file in the sfxr binary format
-- (version 100-102)
-- @within Serialization
-- @tparam ?string|file|love.filesystem.File f a path or file in `rb`-mode
-- (passed files will not be closed)
-- @raise "incompatible version: x", "unexpected file length"
function sfxr.Sound:loadBinary(f)
    local close = false
    if type(f) == "string" then
        f = io.open(f, "r")
        close = true
    end

    local s
    if io.type(f) == "file" then
        s = f:read("*a")
    else
        s = f:read()
    end

    if close then
        f:close()
    end

    self:resetParameters()

    local off = 1

    local function readFloat()
        local f = unpackIEEE754(s:sub(off, off+3):reverse())
        off = off + 4
        return f
    end

    -- Start reading the string

    local version = s:byte(off)
    off = off + 4
    if version < 100 or version > 102 then
        error("incompatible version: " .. tostring(version))
    end

    self.waveform = s:byte(off)
    off = off + 4
    self.volume.sound = version==102 and readFloat() or 0.5

    self.frequency.start = readFloat()
    self.frequency.min = readFloat()
    self.frequency.slide = readFloat()
    self.frequency.dslide = version>=101 and readFloat() or 0

    self.duty.ratio = readFloat()
    self.duty.sweep = readFloat()

    self.vibrato.depth = readFloat()
    self.vibrato.speed = readFloat()
    self.vibrato.delay = readFloat()

    self.envelope.attack = readFloat()
    self.envelope.sustain = readFloat()
    self.envelope.decay = readFloat()
    self.envelope.punch = readFloat()

    off = off + 1 -- filter_on - seems to be ignored in the C++ version
    self.lowpass.resonance = readFloat()
    self.lowpass.cutoff = readFloat()
    self.lowpass.sweep = readFloat()
    self.highpass.cutoff = readFloat()
    self.highpass.sweep = readFloat()

    self.phaser.offset = readFloat()
    self.phaser.sweep = readFloat()

    self.repeatspeed = readFloat()

    if version >= 101 then
        self.change.speed = readFloat()
        self.change.amount = readFloat()
    end

    assert(off-1 == s:len(), "unexpected file length")
end

return sfxr
