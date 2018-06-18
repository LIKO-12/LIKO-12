--ConfigUtils, used by programs which has to save some information about the user.

--Libraries
local JSON = require("Libraries.JSON")

--Localized Lua Library

--The API
local ConfigUtils = {}

--The path were the config file would be stored.
ConfigUtils.configPath = "user.json"

--Load the config.
function ConfigUtils.loadConfig()
  ConfigUtils.config = {}
end

--Save the config.
function ConfigUtils.saveConfig() end

--Get a sub config table.
function ConfigUtils.get(name)
  if not ConfigUtils.config[name] then
    ConfigUtils.config[name] = {}
  end
  
  return ConfigUtils.config[name]
end

ConfigUtils.loadConfig()

--Make the ConfigUtils a global.
_G["ConfigUtils"] = ConfigUtils