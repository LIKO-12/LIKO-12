codes = true --Enable warnings codes

std = "luajit+love" --Lua and LuaJIT standard environment.

globals = {
	"_LVer","_LVERSION", --LIKO-12 Version variables.
	
	--Missing love globals.
	"love.errorhandler",
	
	"love.arg.parseGameArguments",
	
	"love.filesystem.getInfo",
	
	"love.graphics.isActive",
	"love.graphics.isCreated",
	
	"love.mouse.isCursorSupported"
}

--The most annoying warnings
ignore = {
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
	inline = false,

	allow_defined = true,
	allow_defined_top = true,
	not_globals = {"_LVer","_LVERSION"}
}

--Ignore long line warnings for conf.lua
files["conf.lua"] = {
	ignore={"631"} --Line is too long.
}

--Ignore third-part libraries, I'm not going to cleanup their shit.
exclude_files = {
	--JSON Library.
	"Engine/JSON.lua",
	"OS/DiskOS/Libraries/JSON.lua",
	"OS/GameDiskOS/Libraries/JSON.lua",
}