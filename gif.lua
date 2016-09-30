-- GIF encoder specialized for PICO-8
-- by gamax92.
-- Updated for liko12 by RamiLego4Game
local palmap={}

for i=1, 16 do
	local palette=_ColorSet[i]
	local value=bit.lshift(palette[1], 16)+bit.lshift(palette[2], 8)+palette[3]
	palmap[i-1]=value
	palmap[value]=i-1
end

	
local function num2str(data)
	return string.char(bit.band(data, 0xFF), bit.rshift(data, 8))
end

local gif={}

function gif:frame(data)
  --[[data:mapPixel(function(x,y,r,g,b,a)
    local lk12id = _GetColorID(r,g,b,255) or 1
    return unpack(_ColorSet[lk12id])
  end)]]
	self.file:write("\33\249\4\4\3\0\0\0")
	local last=self.last
	local x0, y0, x1, y1=0, nil, 192*_GIFSCALE-1, 128*_GIFSCALE-1
	if self.first then
		y0=0
		self.first=nil
	else
		for y=0, y1 do
			local kill=false
			for x=x0, x1 do
				local r1, g1, b1=last:getPixel(x, y)
				local r2, g2, b2=data:getPixel(x, y)
				if r1~=r2 or g1~=g2 or b1~=b2 then
					y0=y
					kill=true
					break
				end
			end
			if kill then
				break
			end
		end
		if y0==nil then
			-- TODO: Output longer delay instead of bogus frame
			x0, y0, x1, y1=0, 0, 0, 0
		end
		for x=x0, x1 do
			local kill=false
			for y=y0, y1 do
				local r1, g1, b1=last:getPixel(x, y)
				local r2, g2, b2=data:getPixel(x, y)
				if r1~=r2 or g1~=g2 or b1~=b2 then
					x0=x
					kill=true
					break
				end
			end
			if kill then
				break
			end
		end
		for y=y1, y0, -1 do
			local kill=false
			for x=x0, x1 do
				local r1, g1, b1=last:getPixel(x, y)
				local r2, g2, b2=data:getPixel(x, y)
				if r1~=r2 or g1~=g2 or b1~=b2 then
					y1=y
					kill=true
					break
				end
			end
			if kill then
				break
			end
		end
		for x=x1, x0, -1 do
			local kill=false
			for y=y0, y1 do
				local r1, g1, b1=last:getPixel(x, y)
				local r2, g2, b2=data:getPixel(x, y)
				if r1~=r2 or g1~=g2 or b1~=b2 then
					x1=x
					kill=true
					break
				end
			end
			if kill then
				break
			end
		end
	end
	self.file:write("\44"..num2str(x0)..num2str(y0)..num2str(x1-x0+1)..num2str(y1-y0+1).."\0\4")
	local codetbl={}
	for i=0, 15 do
		codetbl[string.char(i)]=i
	end
	local last=17
	local buffer=""
	local stream={16}
	for y=y0, y1 do
		for x=x0, x1 do
			local r, g, b=data:getPixel(x, y)
			local index=string.char(palmap[bit.lshift(r, 16)+bit.lshift(g, 8)+b]) --FIXME PLEASE
			local temp=buffer..index
			if codetbl[temp] then
				buffer=temp
			else
				stream[#stream+1]=codetbl[buffer]
				last=last+1
				if last<4095 then
					codetbl[temp]=last
				else
					stream[#stream+1]=16
					codetbl={}
					for i=0, 15 do
						codetbl[string.char(i)]=i
					end
					last=17
				end
				buffer=tostring(index)
			end
		end
	end
	stream[#stream+1]=codetbl[buffer]
	stream[#stream+1]=17
	local output={}
	local size=5
	local bits=0
	local pack=0
	local base=-16
	for i=1, #stream do
		pack=pack+bit.lshift(stream[i], bits)
		bits=bits+size
		while bits>=8 do
			bits=bits-8
			output[#output+1]=string.char(bit.band(pack, 0xFF))
			pack=bit.rshift(pack, 8)
		end
		if i-base>=2^size then
			size=size+1
		end
		if stream[i]==16 then
			base=i-17
			size=5
		end
	end
	while bits>0 do
		bits=bits-8
		output[#output+1]=string.char(bit.band(pack, 0xFF))
		pack=bit.rshift(pack, 8)
	end
	output=table.concat(output)
	while #output>0 do
		self.file:write(string.char(math.min(#output, 255))..output:sub(1, 255))
		output=output:sub(256)
	end
	self.file:write("\0")
	self.last=data
end

function gif:close()
	self.file:write("\59")
	self.file:close()
	self.file=nil
	self.last=nil
end

local gifmt={
	__index=function(t, k)
		return gif[k]
	end
}

local giflib={}

function giflib.new(filename)
	local file, err=love.filesystem.newFile(filename, "w")
	if not file then
		return nil, err
	end
	file:write("GIF89a"..num2str(192*_GIFSCALE)..num2str(128*_GIFSCALE).."\243\0\0")
	for i=1, 16 do
		local palette=_ColorSet[i]
		file:write(string.char(palette[1], palette[2], palette[3]))
	end
	file:write("\33\255\11NETSCAPE2.0\3\1\0\0\0")
	local last=love.image.newImageData(192*_GIFSCALE, 128*_GIFSCALE)
	return setmetatable({filename=filename, file=file, last=last, first=true}, gifmt)
end

return giflib
