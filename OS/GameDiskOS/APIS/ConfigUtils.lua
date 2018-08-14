--ConfigUtils, used by programs which has to save some information about the user.

--Libraries
local JSON = require("Libraries.JSON")

--Localized Lua Library

--The API
local ConfigUtils = {}

--The path were the config file would be stored.
ConfigUtils.configPath = _SystemDrive..":/user.json"

--Load the config.
function ConfigUtils.loadConfig()
  if _GameDiskOS then ConfigUtils.config = {} return end
  local jsonData = fs.read(ConfigUtils.configPath)
  
  ConfigUtils.config = JSON:decode(jsonData)
end

--Save the config.
function ConfigUtils.saveConfig()
  if _GameDiskOS then return end
  local jsonData = JSON:encode_pretty(ConfigUtils.config)
  
  fs.write(ConfigUtils.configPath, jsonData)
end

--Get a sub config table.
function ConfigUtils.get(name)
  if not ConfigUtils.config[name] then
    ConfigUtils.config[name] = {}
  end
  
  return ConfigUtils.config[name]
end

--Initialize the ConfigUtils
if not fs.exists(ConfigUtils.configPath) and not _GameDiskOS then
  fs.write(ConfigUtils.configPath,"[]")
end

ConfigUtils.loadConfig()

--Make the ConfigUtils a global.
_G["ConfigUtils"] = ConfigUtils