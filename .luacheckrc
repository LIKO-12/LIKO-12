codes = true --Enable warnings codes

self = false --Ignore unused self warnings
max_line_length = false --Disable max line length warnings.

std = "luajit+love" --Lua and LuaJIT standard environment.

globals = {
	"_LVer","_LVERSION", --LIKO-12 Version variables.
	
	--Missing love globals.
	
	"love.arg.parseGameArguments",
	
	"love.audio.newQueueableSource",
	
	"love.data.compress",
	"love.data.decode",
	"love.data.decompress",
	"love.data.encode",
	"love.data.hash",
	
	"love.errorhandler",
	
	"love.filesystem.getInfo",
	"love.filesystem.newDirectory",
	
	"love.graphics.isActive",
	"love.graphics.isCreated",
	
	"love.keyboard.getKeyRepeat",
	"love.keyboard.getTextInput",
	
	"love.mouse.isCursorSupported"
}

--The most annoying warnings
ignore = {
	"212", --Unused argument.
	"213", --Unused loop variable.
	"542", --Empty if branch.
	"611", --A line consists of nothing but whitespace.
	"613", --Trailing whitespace in a string.
}

--Configuration for LIKO-12 operating systems.
files["OS"] = {
	global = false,
	unused = false,
	redefined = false,
	unused_args = false,
	unused_secondaries = false,

	allow_defined = true,
	allow_defined_top = true,
	not_globals = {"_LVer","_LVERSION"}
}

--Ignore long line warnings for conf.lua
files["conf.lua"] = {
	ignore={"631"} --Line is too long.
}