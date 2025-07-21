local M = {}

--------------------------------------------------------------------------------

function M.get(path, headers)
    local x = is_string(path)
    local result, status = "", "404"
    if x:match( "^/demo/?$" ) then
        headers:upsert("content-type", "text/html")
        result = M.init_demo()
        status = "200"
    end
    if x:match( "^/mdtest/?$" ) then
        headers:upsert("content-type", "text/html")
        result = M.mdtest()
        status = "200"
    end
    if x:match( "^/xml/" ) then
        headers:upsert("content-type", "text/html")
        result = M.get_xml(x)
        status = "200"
    end
    return result, status
end


--------------------------------------------------------------------------------

function M.post(path, stream, headers)
    local x = is_string(path)
    local utils = require "modules.utils"
    local result, status = "405: Method not allowed", "405"

    if x:match( "^/api/countletters/?$" ) then
        headers:upsert("content-type", "text/html")
        local body = stream:get_body_as_string()
        local data = utils.parse_form(body)
        if debug_mode then msg(data) end
        result = M.countletters(data)
        status = "202"
    end

    if debug_mode then msg(status) end
    return result, status
end

--------------------------------------------------------------------------------

function M.delete(path, headers)
    local x = is_string(path)
    local user_id = x:match("^/api/users/(%d+)/?$")
    local result, status = "405: Method not allowed", "405"
    if user_id then
        headers:upsert("content-type", "text/html")
        result = M.delete_user(user_id)
        status = "200"
    end
    return result, status
end

--------------------------------------------------------------------------------

function M.init_demo()
    local utils = require "modules.utils"
    local path = _G.public_user_folder .. "demo.xml"
    local result = utils.read_file(path) or ""
    return is_string(result)
end

--------------------------------------------------------------------------------

function M.mdtest()
    local utils = require "modules.utils"
    local result = utils.md_to_html("## success") or "empty"
    return is_string(result)
end

--------------------------------------------------------------------------------

function M.get_xml(headers, path)
    local x = is_string(path)
    local utils = require "modules.utils"
    local filename = string.match(x, "([^/]+)$") .. ".xml"
    local path = _G.public_user_folder .. filename
    local result = utils.read_file(path) or ""
    return is_string(result)
end

--------------------------------------------------------------------------------

function M.countletters(userdata)
    local data = is_string(userdata.string or "nothing")
    if data == "" then data = "nothing" end
    local utils = require "modules.utils"
    local result = ""
    local count = 0
    for char in data:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        if char:match("[%a]") then
            count = count + 1
        end
    end
    local template = utils.read_file(_G.public_user_folder .. "count.xml")
    pre_result = utils.replace(template, "$USERINPUT", data)
    result = utils.replace(pre_result, "$VALUE", tostring(count))
    return is_string(result)
end


--------------------------------------------------------------------------------

function M.delete_user(id)
    local x = is_string(id)
    print("Deleting user with ID:", x)
    local result = ""
    return is_string(result)
end

--------------------------------------------------------------------------------
return M