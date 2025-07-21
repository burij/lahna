local core = require "modules.lua-light-wings" core.globalize(core)

local app = require "modules.server"

local load_conf = loadfile(arg[1] or "./conf.lua")
local succes, conf = pcall(load_conf)
if not succes then conf = require "conf" end

conf.version = "Lahna: Luaserver for HTMX on NixOS, Version 0.0.3dev"
conf.arguments = arg

_G.debug_mode = conf.debug_mode or true
_G.public_user_folder = conf.path

app.run(conf)