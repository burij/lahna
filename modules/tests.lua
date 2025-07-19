local core = require "modules.lua-light-wings" core.globalize(core)

local utils = require "modules.utils"

local html = utils.md_to_html("# Header")
print(html)