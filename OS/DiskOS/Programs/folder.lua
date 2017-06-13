--Opens the host file explorer in the current active folder

local term = require("C://terminal")
openAppData("/drives/"..term.getdrive()..term.getdirectory())