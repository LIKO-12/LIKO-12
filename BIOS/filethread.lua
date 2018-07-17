--A thread to keep track of files being edited, and automatically update them in the appdata folder
--So there would be no longer need to restart LIKO-12 for some tasks.

--By default it only tracks the DiskOS folder.

require("love.system")
require("love.timer")

local reg = {}

local tpath = "/OS/DiskOS/" --Tracking Path
local dpath = "/drives/C/" --Destination Path

local channel = love.thread.getChannel("BIOSFileThread") --Stop the thread when needed.

local function checkDir(dir,r)
	dir = dir or ""
	r = r or reg
	local path = tpath..dir
	local items = love.filesystem.getDirectoryItems(path)
	for k, file in ipairs(items) do if file:sub(1,1) ~= "." then
		local fpath = path..file
		if love.filesystem.getInfo(fpath,"file") then --It's a file
			local fupdate = false --Should the file be updated ?
			if not love.filesystem.getInfo(dpath..dir..file) then --Add new file
				--print("New file added")
				fupdate = true
			else --Check old file
        local info = love.filesystem.getInfo(fpath)
				local modtime = info and info.modtime
				if modtime then
					if r[file] then --It's registered
						if modtime > r[file] then --It has been edited !
							fupdate = true
						end
					else --It's not registered !
						r[file] = info.modtime --Register it.
					end
				else
					print("Error: failed to get modification time.")
				end
			end
			
			--Update the file
			if fupdate then
        local info = love.filesystem.getInfo(fpath)
				r[file] = info and info.modtime or false
				local data, rerr = love.filesystem.read(fpath)
				if data then
					local ok, werr = love.filesystem.write(dpath..dir..file,data)
					if not ok then r[file] = nil print("Error: Failed to write,",werr) else
						--print("Updated File",fpath)
					end
				else
					print("Error: Failed to read,",rerr)
				end
			end
		else --Nested directory
			if not r[file] then r[file] = {} end
			checkDir(dir..file.."/",r[file])
		end
	end end
end

print("Started File Thread")

while true do
	local shut = channel:pop()
	if shut then break end --Finish the thread.
	
	checkDir()
  
  love.timer.sleep(3)
end

print("Finished File Thread")
