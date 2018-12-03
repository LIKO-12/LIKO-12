-- The Music Editor

local songobj = require("Libraries.song") --The song object

local eapi = select(1,...)
local sw, sh = screenSize()
local tw, th = termSize()
local ss = _SystemSheet

local me = {}

-- Todo: multiple songs
local songdata = songobj()

local playing = false
local cur_slot = 0
local cur_sheet = 0
local cur_chan = 1
local cur_OAI = {4,5,1}

-- Used to countdown time to stop note
-- after the user taps a piano key
local added_note_timer = 0

-- Testing
local imported = "|0:C 0450,8:D#,12:A#03,20:G#,22:A#,24:C 04,32:D#,36:A#03,46:r,48:C 045,56:D#,60:A#,68:G#,72:D#,80:C#,82:C ,84:A#03,92:r;|0:E 0450,2:C ;|"

local _PianoSprite = image(fs.read(_SystemDrive..":/piano.lk12"))

local pianoRoll = {
	["xo"] = 13,["yo"] = 16,
	["xw"] = 176,["yw"] = 39,
	["cell_x"] = 11,["cell_y"]=10,
}

function me:isInVisibleRange(index)
	assert(type(index) == "number", "isInVisibleRange - index given was not a number!")
	if(index >= cur_sheet*16 and index < (cur_sheet+1)*16)then
	return true end
	return false
end

function me:drawBorders()
	rect(0,58,sw,4,false,9)
	for i=0,sw do
		local off = 0
		if(i % 2 == 0)then off = 1 end
		point(i,59+off,4)
	end
end

function me:drawKey(index,note,octave,amplitude,channel)
	while(index > 15)do index = index - 16 end
	local pr = pianoRoll
	local note_string = AudioUtils.Notes[note]
	local ind_off = (index) * pr.cell_x
	local chan_off = (channel-1) * pr.cell_y
	color(7)
	if(amplitude ~= 0)then
		rect(pr.xo + ind_off, pr.yo+pr.cell_y-1 + chan_off, pr.cell_x,-octave-1, false, 2)
	else
		note_string = "r"
		rect(pr.xo + ind_off, pr.yo+pr.cell_y-1 + chan_off, pr.cell_x,-9, false, 2)
	end
	print(note_string,pr.xo + ind_off + 1, pr.yo + chan_off + 3)
end
function me:drawPianoRoll()
	local pr = pianoRoll
	-- Draw Roll background
	rect(pr.xo,pr.yo,pr.xw,pr.yw,false,0)
	-- Draw channel labels
	for i=1,4 do
		color(9)
		print("C"..i, pr.xo-11, pr.yo+pr.cell_y*(i-1)+2)
	end
	-- Draw time index lines
	for i=1,15 do
		local col = 1
		if(i == 8)then col = 13 end
		line(pr.xo + i*11, pr.yo, pr.xo + i*11, pr.yo + pr.yw, col)
	end
	-- Draw caret
	if(self:isInVisibleRange(songdata.timer))then
		local caret_x = math.floor(((songdata.timer)*11) % pr.xw)
		-- Caret Top
		rect(pr.xo + caret_x - 2, pr.yo-4, 8,4, false, 13)
		-- Channel Box
		if(not playing)then rect(pr.xo + caret_x, pr.yo + (cur_chan-1)*pr.cell_y, pr.cell_x, pr.cell_y-1, false, 13) end
		-- Caret Line
		rect(pr.xo + caret_x, pr.yo, 4, pr.yw, false,13)
		color(7)
		print(math.floor(songdata.timer),pr.xo+caret_x,pr.yo-7, nil, "center")
	end
	-- Draw channel separators
	for i=1,3 do
		line(pr.xo-1,pr.yo+i*pr.cell_y-1,pr.xo+pr.xw,pr.yo+i*pr.cell_y-1,5)
	end
	-- Draw orange edges
	line(pr.xo-1,pr.yo-1,pr.xo-1,pr.yo+pr.yw+1, 9)
	line(pr.xo+pr.xw,pr.yo-1,pr.xo+pr.xw,pr.yo+pr.yw+1, 9)
	-- Draw Notes
	for i=1,4 do
		if(songdata:getChannelSize(i) > 0)then
			for j=1,songdata:getChannelSize(i) do
				local kt, kn, ko, ka, ki = songdata:getKeyByIndex(i,j)
				if(self:isInVisibleRange(kt))then
					self:drawKey(kt,kn,ko,ka,i)
				end
			end
		end
	end
	
end

local playButtons = {
	["xo"]=82,["yo"]=74,
	["x_spacing"] = 10,
	["down"] = {false,false,false,false,false},
}
function me:drawPlayButtons()
	local pb = playButtons
	
	local my_x = function(x_ind) return pb.xo + x_ind * pb.x_spacing end
	for i=1,5 do
		pal(6,13)
		ss:draw(154+i, my_x(i-1), pb.yo+1) pal()
		if(pb.down[i])then pal(6,1) end
		ss:draw(154+i, my_x(i-1)-1, pb.yo)
		pal()
	end
	color(9)
	print("SHEET:", pb.xo,pb.yo - 8)
	rect(pb.xo+29,pb.yo-9,17,7,false,13)
	color(6)
	print(cur_sheet,pb.xo+28,pb.yo-8,fontWidth()*4+2,"right")
end

local pianoKeys = {
	["xo"]=67,["yo"]=85,
	["down"]={}
}
for i=1,12 do pianoKeys.down[i]=false end
function me:drawPianoKeys()
	-- Draw the piano keys
	local pk = pianoKeys
	local sharps = {2,4,7,9,11}
	for i=1,12 do
		local base_col = 6
		local push_col = 5
		for k,v in pairs(sharps) do
			if(i == v)then
				base_col = 5
				push_col = 2
				break
			end
		end
		if(pk.down[i])then
			pal(i+3,push_col)
		else
			pal(i+3,base_col)
		end
	end
	_PianoSprite:draw(pk.xo,pk.yo)
	pal()
	
	-- Draw Rest key
	local box_color = 6
	if(pk.down[13])then box_color = 2 end
	rect(pk.xo + 58, pk.yo, 10, 32, true, 1)
	rect(pk.xo + 59, pk.yo+1, 8,30, false, box_color)
	color(13)
	print("REST", pk.xo + 61,pk.yo+3,fontWidth()+2)
end

local caretPad = {
	["xo"]=48,["yo"]=68,
	["down"] = {false,false,false,false}
}
function me:drawCaretPad()
	local cp = caretPad
	pal(9,13)
	ss:draw(160,cp.xo+15, cp.yo+6)
	ss:draw(160,cp.xo+4,cp.yo+6,nil,-1)
	ss:draw(160,cp.xo+6,cp.yo+8,-math.pi/2)
	ss:draw(160,cp.xo+13,cp.yo+11,math.pi/2)
	pal(9,6)
	if(cp.down[1])then pal(6,1) end ss:draw(160,cp.xo+14, cp.yo+5)
	if(cp.down[2])then pal(6,1) end ss:draw(160,cp.xo+3,cp.yo+5,nil,-1)
	if(cp.down[3])then pal(6,1) end ss:draw(160,cp.xo+5,cp.yo+7,-math.pi/2)
	if(cp.down[4])then pal(6,1) end ss:draw(160,cp.xo+12,cp.yo+10,math.pi/2)
	pal()
end

local rollers = {
	["xo"]=168,["yo"]=65,
	["xo2"]=48,["yo2"]=90,
	["cell_x"]=17,["cell_y"]=7,
	["y_off"]=9,
	["arw1_xoff"]=-5,["arw2_xoff"]=18,["arw3_xoff"]=14,
	["down"]={}
}
for i=1,10 do rollers.down[i]=false end
function me:drawRollers()
	local rl = rollers
	local text_max = fontWidth()*4+2
	local font_x = rl.xo-1
	local font_x2= rl.xo2-1
	
	-- Simplifies y offsets
	local y_index = 0
	local my_y = function(ind)
		if(ind == 2)then return rl.yo2+rl.y_off * y_index end
		return rl.yo+rl.y_off * y_index
	end

	-- Draw Slot Box
	color(12)
	print("SLOT",rl.xo - fontWidth()*6.5,my_y()+1)
	rect(rl.xo,rl.yo,rl.cell_x,rl.cell_y,false,6)
	color(13)
	print(cur_slot, font_x,rl.yo+1,text_max,"right")
	if(rl.down[1])then pal(9,4) end _SystemSheet:draw(164, rl.xo + rl.arw1_xoff, my_y())
	if(rl.down[2])then pal(9,4) end _SystemSheet:draw(165, rl.xo + rl.arw2_xoff, my_y())
	pal()
	y_index = y_index + 1
	
	-- Draw BPM Box
	color(9)
	print("BPM", rl.xo - fontWidth()*5.5,my_y()+1)
	rect(rl.xo,my_y(),rl.cell_x,rl.cell_y,false,6)
	color(13)
	print(songdata.bpm.."", font_x,my_y()+1,text_max, "right")
	if(rl.down[3])then pal(9,4) end _SystemSheet:draw(164, rl.xo + rl.arw1_xoff, my_y())
	if(rl.down[4])then pal(9,4) end _SystemSheet:draw(165, rl.xo + rl.arw2_xoff, my_y())
	pal()
	y_index = 0
	
	-- Draw OAI boxes
	local OAI = {"OCT","AMP","INS",}
	for i=1,3 do
		color(9)
		print(OAI[i], rl.xo2 - fontWidth()*5.5,my_y(2)+1)
		rect(rl.xo2,my_y(2),rl.cell_x-4,rl.cell_y,false,6)
		color(13)
		print(cur_OAI[i],font_x2,my_y(2)+1,fontWidth()*3+2,"right")
		if(rl.down[5+y_index])then pal(9,4) end _SystemSheet:draw(164, rl.xo2 + rl.arw1_xoff, my_y(2))
		if(rl.down[5+y_index])then pal(9,4) end _SystemSheet:draw(165, rl.xo2 + rl.arw3_xoff, my_y(2))
		pal()
		y_index = y_index + 1
	end
end


function me:doDraw()
	eapi:drawUI()
	me:drawBorders()
	me:drawPianoRoll()
	me:drawPlayButtons()
	me:drawPianoKeys()
	me:drawRollers()
	me:drawCaretPad()
end

function me:playButton()
	if(songdata:getSongDuration() == 0)then return end
	playing = not playing
	if(not playing)then Audio.generate() songdata:clearHeld() end
	songdata.timer = math.floor(songdata.timer)
	me:doDraw()
end
function me:goToStart()
	playing = false
	songdata.timer = 0
	cur_sheet = 0
	me:update()
	Audio.generate()
	me:doDraw()
end
function me:goToEnd()
	playing = false
	songdata.timer = songdata:getSongDuration()
	me:scrollToCaretSheet()
	me:update()
	Audio.generate()
	me:doDraw()
end

function me:scrollChannel(dir)
	if(playing)then return end
	if(dir == -1 and cur_chan > 1)then cur_chan = cur_chan-1
	elseif(dir == 1 and cur_chan <4)then cur_chan = cur_chan+1 end
	me:doDraw()
end
function me:scrollCaret(dir)
	if(playing)then return end
	if(dir == -1 and songdata.timer > 0)then
		songdata.timer = math.max(math.floor(songdata.timer - 1),0)		
	end
	if(dir == 1 and songdata.timer < 255)then
		songdata.timer = math.min(math.floor(songdata.timer + 1),255)
	end
	me:scrollToCaretSheet()
	me:doDraw()
end
function me:getCaretPosition()
	return math.floor(songdata.timer)
end
function me:scrollSheet(dir)
	if(playing)then return end
	if(dir == -1 and cur_sheet > 0)then
		cur_sheet = cur_sheet -1
	elseif(dir == 1 and cur_sheet < 128)then
		cur_sheet = cur_sheet + 1
	end
	me:doDraw()
end
function me:scrollToCaretSheet()
	while(songdata.timer >= (cur_sheet+1)*16)do self:scrollSheet(1) end
	while(songdata.timer < cur_sheet*16)do self:scrollSheet(-1) end
end

function me:scrollOAI(OAI, dir)
	local ranges = {{1,8},{1,7},{1,32}}
	if(dir > 0 and cur_OAI[OAI] < ranges[OAI][2])then
		cur_OAI[OAI] = cur_OAI[OAI] +1
	elseif(dir < 0 and cur_OAI[OAI] > ranges[OAI][1])then
		cur_OAI[OAI] = cur_OAI[OAI] -1
	end
	me:doDraw()
end
function me:scrollBPM(dir)
	local bpm = songdata.bpm
	if(dir == -1 and bpm > 25)then bpm = bpm -1
	elseif(dir == 1 and bpm < 300)then bpm = bpm + 1 end
	songdata.bpm = bpm
	me:doDraw()
end

function me:addPianoKey(piano_key, chan, time_index)
	chan = chan or cur_chan
	time_index = time_index or self:getCaretPosition()
	_systemMessage("User pressed: "..AudioUtils.Notes[piano_key])
	local new_key = {math.floor(songdata.timer), piano_key, cur_OAI[1], cur_OAI[2], cur_OAI[3]}
	songdata:insertKey(cur_chan, new_key)
	-- Play the note for the user to hear
	added_note_timer = 0.22
	Audio.generate(cur_OAI[3], AudioUtils.noteFrequency(piano_key, cur_OAI[1]),cur_OAI[2])
	me:doDraw()
end
function me:addRestNote(chan, time_index)
	chan = chan or cur_chan
	time_index = time_index or self.getCaretPosition()
	local rest_key = {time_index,1,1,0,1}
	songdata:insertKey(cur_chan, rest_key)
	me:doDraw()
end
function me:deleteKey(chan, time_index)
	chan = chan or cur_chan
	time_index = time_index or math.floor(songdata.timer)
	local key_index = songdata:getKeyIndexByTime(chan, time_index)
	songdata:deleteKey(chan, key_index)
	me:doDraw()
end


function me:update(t)	
	if(playing)then
		if(added_note_timer ~= 0)then added_note_timer = 0 end
		-- Move the roll to match current song position
		cur_sheet = math.floor(songdata.timer / 16)
		self:doDraw()
		songdata:updateDataTime(t)
		if(songdata.timer >= songdata:getSongDuration()+1)then
			playing = false
			me:doDraw()
		end
	else
		if(added_note_timer > 0)then
			added_note_timer = added_note_timer - t
		else
			added_note_timer = 0
			Audio.generate()
		end
	end
end


me.keymap = {
	-- Restart song
	["space"] = me.playButton,
	["i"] = function()
		me:import(imported)
		_systemMessage("Imported test song")
	end,
	["o"] = function()
		cprint(songdata:export())
	end,
	[","] = function()
		me:scrollSheet(-1)
	end,
	["."] = function()
		me:scrollSheet(1)
	end,
	["left"] = function()
		me:scrollCaret(-1)
	end,
	["right"] = function()
		me:scrollCaret(1)
	end,
	["up"] = function()
		me:scrollChannel(-1)
	end,
	["down"] = function()
		me:scrollChannel(1)
	end,
	["home"] = me.goToStart,
	["end"] = me.goToEnd,
	["delete"] = me.deleteKey,
	
	-- OAI rollers
	["o"] = function() me:scrollOAI(1,1) end,
	["l"] = function() me:scrollOAI(1,-1) end,
	["p"] = function() me:scrollOAI(2,1) end,
	[";"] = function() me:scrollOAI(2,-1) end,
	["["] = function() me:scrollOAI(3,1) end,
	["'"] = function() me:scrollOAI(3,-1) end,
	["]"] = function() me:scrollBPM(1) end,
	["\\"] = function() me:scrollBPM(-1) end,
	-- Rest note
	["r"] = me.addRestNote,
}
local piano_keyboard = {"z","s","x","d","c","v","g","b","h","n","j","m"}
for i=1,12 do
	table.insert(me.keymap, piano_keyboard[i])
	me.keymap[piano_keyboard[i]] = function()
		me:addPianoKey(i)
	end
end

function me:entered()
	self:doDraw()
	
end

function me:leaved()
	playing = false
	Audio.generate()
end

function me:import(data)
	songdata:import(data)
	self:doDraw()
end

function me:export()
	return songdata:export()
end

return me
