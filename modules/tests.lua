local M = {}

function M.prestart()
    print "debug mode active, launching prestart script..."
    local utils = require "modules.utils"
    local variable_set = {
        VAR = "Replaced unprotected",
        ["$PROTECTED"] = "Replaced protected"
    }

    local template = [[
        This is a test template, if the function works
            - VAR
            - $PROTECTED
    ]]

    local result = utils.process_template(template, variable_set)
    print(result)
end


return M