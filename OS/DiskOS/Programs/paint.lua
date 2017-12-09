--Paint Program--
local args = {...}
if #args < 1 or args[1] == "-?" then
  printUsage("paint <filename>", "Creates or edits an existing image.",
             "paint @clip", "Creates or edits an existing image in the clipboard.",
             "paint @label", "Edits the disk label image (in the RAM).")
  return
end

local tar = table.concat(args," ") --The path may include whitespaces

local img, imgdata
local reload, save

if tar == "@label" then
  local limg = getLabelImage()
  imgdata = imagedata(limg:size())
  imgdata:paste(limg)
  img = imgdata:image()
  
  reload = function(tool)
    imgdata = imagedata(limg:size())
    imgdata:paste(limg)
    img = imgdata:image()
    tool.editor:import(img,imgdata)
    _systemMessage("Reloaded successfully",1)
  end
  
  save = function(tool)
    limg:paste(imgdata)
    _systemMessage("Saved successfully",1)
  end
elseif tar == "@clip" then
  local ok, err = pcall(imagedata,clipboard())
  if ok then
    imgdata = err
  else
    color(9) print("Input image size:")
  
    color(11) print("Width: ",false)
    color(7) local width = input()
    if not width or width:len() == 0 then print("") return end
    local w = tonumber(width)
    if not w then color(8) print("\nInvalid Width: "..width..", width must be a number !") return end
  
    color(11) print(", Height: ",false)
    color(7) local height = input()
    if not height or height:len() == 0 then print("") return end
    local h = tonumber(height)
    if not h then color(8) print("\nInvalid Height: "..height..", height must be a number !") return end
    print("")
  
    imgdata = imagedata(w,h)
    clipboard(imgdata:encode())
  end
  
  img = imgdata:image()
  
  reload = function(tool)
    imgdata = imagedata(clipboard())
    img = imgdata:image()
    tool.editor:import(img,imgdata)
    _systemMessage("Reloaded successfully",1)
  end
  
  save = function(tool)
    local ndata = tool.editor:export()
    clipboard(ndata)
    _systemMessage("Saved successfully",1)
  end
else
  if tar:sub(-5,-1) ~= ".lk12" then tar = tar..".lk12" end
  local term = require("terminal")
  tar = term.resolve(tar)

  if fs.exists(tar) and fs.isDirectory(tar) then color(8) print("Can't edit directories !") return end
  
  if not fs.exists(tar) then --Create a new image
    color(9) print("Input image size:")
  
    color(11) print("Width: ",false)
    color(7) local width = input()
    if not width or width:len() == 0 then print("") return end
    local w = tonumber(width)
    if not w then color(8) print("\nInvalid Width: "..width..", width must be a number !") return end
  
    color(11) print(", Height: ",false)
    color(7) local height = input()
    if not height or height:len() == 0 then print("") return end
    local h = tonumber(height)
    if not h then color(8) print("\nInvalid Height: "..height..", height must be a number !") return end
    print("")
  
    imgdata = imagedata(w,h)
    img = imgdata:image()
  else --Load the image
    local data = fs.read(tar)
    local ok, err = pcall(image,data)
    if not ok then color(8) print(err) return end
    img = err
    imgdata = img:data()
  end
  
  reload = function(tool)
    if fs.exists(tar) then
      local data = fs.read(tar)
      local ok, err = pcall(image,data)
      if not ok then
        _systemMessage("ERR: "..tostring(err),5,9,4)
        cprint("[Paint]: Failed to reload: "..tostring(err))
        return
      end
      img = err
      imgdata = img:data()
      tool.editor:import(img,imgdata)
      _systemMessage("Reloaded successfully",1)
    end
  end
  
  save = function(tool)
    local ndata = tool.editor:export()
    fs.write(tar,ndata)
    _systemMessage("Saved successfully",1)
  end
end

local eutils = require("Editors.utils")
local tool = eutils:newTool()

local ok, editor = assert(pcall(assert(fs.load("C:/Editors/paint.lua")),tool,img,imgdata))

tool:start(editor,reload,save)