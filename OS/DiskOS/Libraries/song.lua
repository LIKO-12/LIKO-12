--Song Object--

local function newSong(bpm)
	
	local song = {
		{},{},{},{},
	}
	song.bpm = bpm or 75
	song.timer = 0
	song.held = {
		["note"] = {1,1,1,1},
		["octa"] = {1,1,1,1},
		["ampl"] = {0,0,0,0},
		["inst"] = {1,1,1,1},
	}

	function song:updateDataTime(t)
		local length = self:getSongDuration()
		if(length == 0)then return end
		
		local time_index = self:getTimeIndex()
		
		for chan=1,1 do
			-- Don't iterate if it's zero length
			if(self:getChannelDuration(chan) == 0)then break end
			-- Find our current note key
			for i=0,(#song[chan]/5) do
				local key_time = song[1][i*5 + 1]
				
				if(key_time ~= nil and key_time == time_index)then
					local key_note = song[chan][i*5 + 2]
					local key_octa = song[chan][i*5 + 3]
					local key_ampl = song[chan][i*5 + 4]
					local key_inst = song[chan][i*5 + 5]
					song.held.note[chan] = key_note
					song.held.octa[chan] = key_octa
					song.held.ampl[chan] = key_ampl
					song.held.inst[chan] = key_inst
					break
				end
			end
		end
		
		-- Todo make this four channels
		if(song.held.ampl[1] > 0 and song.held.inst[1] > -1)then
			local note = math.floor(AudioUtils.noteFrequency(song.held.note[1],song.held.octa[1]))
			local amp = 0.5--(math.min(math.max(song.held.ampl[1],1),7) / 7)
			local inst = song.held.inst[1]
			Audio.generate(inst,note,amp)
		else
			--Audio.stop()
			Audio.generate()
		end
		
		if(song.timer < length+1)then
			song.timer = song.timer + t * (song.bpm*8/60)
		end
		if(song.timer > length+1)then
			song.timer = length+1
			song:clearHeld()
			Audio.generate()
		end
	end
	
	--clear all song data
	function song:clearData(channel)
		if(channel == nil)then
			for i=1,4 do song[i] = {} end
		else
			song[channel] = {}
		end
	end
	-- Clear held note data
	function song:clearHeld()
		song.held = {
			["note"] = {1,1,1,1},
			["octa"] = {1,1,1,1},
			["ampl"] = {0,0,0,0},
			["inst"] = {1,1,1,1},
		}
	end
	
	-- Find last keyframe time index. Aka song duration
	function song:getSongDuration()
		return math.max(self:getChannelDuration(1),self:getChannelDuration(2), self:getChannelDuration(3), self:getChannelDuration(4))
	end
	-- Find last keyframe of given channel and return its time index
	function song:getChannelDuration(channel)
		local length = 0
		if(#song[channel] >= 5)then length = song[channel][#song[channel] - 4] end
		return length
	end
	function song:getChannelSize(chan)
		assert(type(chan) == "number" and chan > 0 and chan < 5, "Invalid channel given")
		return #song[chan]/5
	end
	-- Return a keyframe by the entry index
	function song:getKeyByIndex(chan, index)
		assert(index >= 1 and index <= self:getChannelSize(chan), "Tried to get keyframe outside available range")
		local key = {}
		for i=1,5 do
			key[i] = song[chan][(index-1)*5+i]
		end
		return key[1],key[2],key[3],key[4],key[5]
	end
	-- Return the keyframe at the given time if available
	function song:getKeyIndexByTime(chan, timer)
		local index = -1
		if(self:getChannelSize(chan) > 0)then
			for i=0,self:getChannelSize(chan)-1 do
				if(song[chan][i*5 +1] == timer)then
					index = i+1
					break
				end
			end
		end
		return index
	end
	
	-- Return the currently 'held' keyframe data
	function song:getHeld(heldType,channel)
		local types = {"note","octa","ampl","inst",}
		if(type(heldType) == "number")then
			return song.held[types[heldType]][channel]
		else
			return song.held[heldType][channel]
		end
	end
	
	function song:getTimeIndex()
		return math.floor(song.timer)
	end
	function song:getBeatIndex()
		return math.floor(song.timer/8)+1
	end
	
	-- Editing --
	
	-- Add keyframe
	function song:insertKey(chan, key)
		local my_index = 1
		local chan_size = self:getChannelSize(chan)
		
		if(chan_size > 0)then
			for i=1,chan_size do
				local time_index = self:getKeyByIndex(chan, i)
				-- Slot already taken? Replace it
				cprint("Is "..time_index.." = "..(key[1]).."?")
				if(key[1] == time_index)then
					self:deleteKey(chan,i)
					my_index = (i-1)*5+1
					cprint("Key replaced")
					break
				-- Keep adding up until there's nothing above us
				elseif(key[1] > time_index)then
					my_index = (i-1)*5+6
				end
			end
		end
		-- Insert the key
		for j=1,5 do table.insert(song[chan], my_index, key[6-j]) end
		self:printSongToConsole()
	end
	-- Delete keyframe
	-- TODO: This isn't working properly
	function song:deleteKey(chan, key_index)
		
		--assert(key_index > 0 and key_index <= self:getChannelSize(chan), "song:deleteKey - provided key_index ("..key_index..") lies outside valid range.")
		if(key_index < 1 or key_index > self:getChannelSize(chan))then
			cprint("song:deleteKey(chan,key_index) - provided key_index ("..key_index..") lies outside valid range")
		end
		local table_index = (key_index-1)*5+1
		for i=1,5 do
			table.remove(song[chan], table_index)
		end
		self:printSongToConsole()
	end
	
	function song:import(data)
		assert(type(data) == "string", "Imported music data must be string.")
		-- Get BPM
		local bpm_data = data:sub(1,data:find("|")-1)
		if(bpm_data == nil)then song.bpm = tonumber(bpm_data) end
		-- Everything AFTER the first ' | ' is channel data.
		local channel_data = data:sub(data:find("|")+1)
		-- Chop channels up into separate strings
		local channels = {}
		for strip in channel_data:gmatch("(.-)|")do
			table.insert(channels, strip)
		end
		local channel_data = nil
		
		for chan=1,4 do
			if(channels[chan] ~= nil)then
				-- Clean out semicolons
				if(channels[chan]:find(";") ~= nil)then channels[chan] = channels[chan]:sub(1,channels[chan]:find(";")-1).."," end
				self:clearData(chan)
				local id = 1
				for key in channels[chan]:gmatch("(.-),") do
					local col = key:find(":")
					song[chan][id] = tonumber(key:sub(1,col-1))
					local keysize = #key-col
					if(keysize == 1)then
						song[chan][id+1] = 1
						song[chan][id+2] = 1
						song[chan][id+3] = 0
						song[chan][id+4] = song[chan][id+4-5]
					else
						if(keysize > 1)then
							local note = key:sub(col+1,col+2)
							if(note:sub(2,2) == " ")then note = note:sub(1,1) end
							song[chan][id+1] = AudioUtils.Notes[note]
						else
							song[chan][id+1] = 1
						end
						if(keysize > 3)then song[chan][id+2] = tonumber(key:sub(col+3,col+4)) else song[chan][id+2] = song[chan][id+2-5] end
						if(keysize > 4)then song[chan][id+3] = tonumber(key:sub(-2,-2)) else song[chan][id+3] = song[chan][id+3-5] end
						if(keysize > 5)then song[chan][id+4] = tonumber(key:sub(-1)) else song[chan][id+4] = song[chan][id+3-4] end
					end
					id = id + 5
				end
				cprint("\n==Importing Channel #"..chan.."==\n")
				cprint("Raw:\n"..channels[chan].."\n")
				cprint("Baked: ")
				self:printSongToConsole()
			end
		end
		cprint("Done")
	end
	
	function song:export()
		local export = song.bpm.."|"
		for c=1,4 do
			local chan = ""
			for i=0,#song[c]/5-1 do
				local id = i*5+1
				local time_id = song[c][id]
				chan = chan..time_id..":"
				-- Amplitude Zero means rest note
				if(song[c][id+3] == 0)then
					chan = chan.."r,"
				-- Otherwise add the note data
				else			
					local note = AudioUtils.Notes[song[c][id+1]]
					-- Note at minimum must be supplied
					if(#note == 1)then note = note.." " end
					local octave = ""
					if(song[c][id+2] ~= -1)then
						octave = song[c][id+2]..""
						if(#octave == 1)then octave = "0"..octave end
					end
					local amplitude = ""
					if(song[c][id+3] ~= -1)then
						amplitude = song[c][id+3]..""
					end	
					local instrument = ""
					if(song[c][id+4] ~= -1)then
						instrument = song[c][id+4]..""
					end
					chan = chan..note..octave..amplitude..instrument..","
				end
			end
			if(chan:sub(-1) == ",")then chan = chan:sub(1,#chan-1)..";" end
			export = export..chan.."|"
		end
		return export
	end
	
	function song:printSongToConsole()
		for chan=1,4 do
			if(#song[chan] > 0)then
				local keys = ""
				for i=1,self:getChannelSize(chan) do
					if(song[chan][i] ~= nil)then
						keys = keys..song[chan][i]..","
						if(i % 5 == 0)then keys = keys.."\n" end
					end
				end
				cprint(keys)
				cprint("Duration: "..self:getChannelDuration(chan))
			end
		end
	end
	
	return song
end

return newSong