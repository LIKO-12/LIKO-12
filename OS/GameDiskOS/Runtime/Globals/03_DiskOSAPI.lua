--DiskOS API Loader

local Globals = (...) or {}

Globals.SpriteGroup = SpriteGroup
Globals.isInRect = isInRect
Globals.whereInGrid = whereInGrid
Globals.input = function(historyTable,preinput)
    local pauseDisabled = Globals._DISABLE_PAUSE --Backup the original value
    Globals._DISABLE_PAUSE = true --Make sure pause is disabled
    local buffer = TextUtils.textInput(historyTable,preinput) --Input text
    Globals._DISABLE_PAUSE = pauseDisabled --Restore back the original value
    return buffer --Return the inputted data, or nil if canceled
end

return Globals