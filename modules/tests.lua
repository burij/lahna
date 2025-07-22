local M = {}

function M.prestart(userconfig)
    print "debug mode active, launching prestart script..."
    local conf = is_dictionary(userconfig)
    local utils = require "modules.utils"

    msg(conf)

end


return M