local core = require "modules.lua-light-wings" core.globalize(core)

local app = require "modules.server"
local test = require "modules.tests"

local load_conf = loadfile(arg[1] or "./conf.lua")
local succes, conf = pcall(load_conf)
if not succes then conf = require "conf" end

conf.version = "Lahna: Luaserver for HTMX on NixOS, Version 0.1"
conf.arguments = arg

_G.debug_mode = conf.debug_mode or true
_G.public_user_folder = conf.path

if debug_mode then test.prestart(conf) end
app.run(conf)

-- Replaced Lua with LuaJit
-- TODO: Add utils.write_file
-- TODO: Add utils.sanitize
-- TODO: Update to the new version of lua-light-wings
-- TODO: Remove need

