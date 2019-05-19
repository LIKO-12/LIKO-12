--Thread used to keep track of files being edited and automatically update them
--in the appdata folder so LIKO-12 does not need to be restarted for some tasks

--Only track the DiskOS folder by default

require("love.system")
require("love.timer")

local reg = {}

local tpath = "/OS/DiskOS/" --Tracking path
local dpath = "/drives/C/" --Destination path

local channel = love.thread.getChannel("BIOSFileThread") --Stop the thread when needed

local function checkDir(dir, r)
    dir = dir or ""
    r = r or reg
    local path = tpath .. dir
    local items = love.filesystem.getDirectoryItems(path)

    -- Check every file in the tracking path
    for k, file in ipairs(items) do
        if file:sub(1, 1) ~= "." then
            local fpath = path .. file
            if love.filesystem.getInfo(fpath, "file") then
                -- It's a file
                local fupdate = false --Should the file be updated?
                if not love.filesystem.getInfo(dpath .. dir .. file) then
                    -- The files does not exist in the destination path, create it
                    fupdate = true
                else
                    -- Get the last timestamp at which the file was modified
                    local info = love.filesystem.getInfo(fpath)
                    local modtime = info and info.modtime
                    if modtime then
                        --Check the previous timestamp to see if the file need to be updated
                        if r[file] then
                            --The file is already registered
                            if modtime > r[file] then
                                --The file has been edited since last time, update it
                                fupdate = true
                            end
                        else
                            --The file is not registered yet, register it
                            r[file] = info.modtime
                        end
                    else
                        print("Error: failed to get modification time.")
                    end
                end
                --Update the file if needed
                if fupdate then
                    local info = love.filesystem.getInfo(fpath)
                    r[file] = info and info.modtime or false
                    local data, rerr = love.filesystem.read(fpath)
                    if data then
                        local ok, werr = love.filesystem.write(dpath .. dir .. file, data)
                        if not ok then
                            r[file] = nil
                            print("Error: failed to write,", werr)
                        end
                    else
                        print("Error: failed to read,", rerr)
                    end
                end
            else
                --It's a directory, recursively check its content
                if not r[file] then
                    r[file] = {}
                end
                checkDir(dir .. file .. "/", r[file])
            end
        end
    end
end

print("Started File Thread")

while true do
    local shut = channel:pop()
    if shut then
        --Finish the thread
        break
    end 

    checkDir()

    love.timer.sleep(3)
end

print("Finished File Thread")
