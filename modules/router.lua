local M = {}

--------------------------------------------------------------------------------

function M.get(path, headers)
    local x = is_string(path)
    local result, status = "", "404"
    if x:match( "^/api/users/?$" ) then
        result = M.get_users(headers)
        status = "200"
    end
    if x:match( "^/demo/?$" ) then
        result = M.init_demo(headers)
        status = "200"
    end
    if x:match( "^/xml/" ) then
        result = M.get_xml(headers, x)
        status = "200"
    end
    return result, status
end


--------------------------------------------------------------------------------

function M.post(path, stream, headers)
    local x = is_string(path)
    local utils = require "modules.utils"
    local result, status = "405: Method not allowed", "405"

    if x:match( "^/api/users/?$" ) then
        local body = stream:get_body_as_string()
        local data = utils.parse_form(body)
        if debug_mode then msg(data) end
        result = M.create_user(data, headers)
        status = "202"
    end
    if x:match( "^/api/countletters/?$" ) then
        local body = stream:get_body_as_string()
        local data = utils.parse_form(body)
        if debug_mode then msg(data) end
        result = M.countletters(data, headers)
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
        result = M.delete_user(user_id, headers)
        status = "200"
    end
    return result, status
end

--------------------------------------------------------------------------------

function M.get_users(headers)
    headers:upsert("content-type", "application/json")
    local users = {
        {id = 1, name = "Alice", email = "alice@example.com"},
        {id = 2, name = "Bob", email = "bob@example.com"},
        {id = 3, name = "Charlie", email = "charlie@example.com"}
    }
    local format_user = function(user)
        return string.format('{"id": %d, "name": "%s", "email": "%s"}',
                           user.id, user.name, user.email)
    end
    local user_json_parts = {}
    for i, user in ipairs(users) do
        user_json_parts[i] = format_user(user)
    end
    local json_response = '{"users": ['
        .. table.concat(user_json_parts, ", ") .. ']}'
    return json_response
end

--------------------------------------------------------------------------------

function M.init_demo(headers)
    headers:upsert("content-type", "text/html")
    local utils = require "modules.utils"
    local path = _G.public_user_folder .. "demo.xml"
    local result = utils.read_file(path) or ""
    return result
end

--------------------------------------------------------------------------------

function M.get_xml(headers, path)
    headers:upsert("content-type", "text/html")
    local x = is_string(path)
    local utils = require "modules.utils"
    local filename = string.match(x, "([^/]+)$") .. ".xml"
    local path = _G.public_user_folder .. filename
    local result = utils.read_file(path) or ""
    return result
end

--------------------------------------------------------------------------------

function M.create_user(userdata, headers)
    headers:upsert("content-type", "text/html")
    local name = userdata.name or "Unknown"
    local email = userdata.email or "mail@example.com"
    local user_id = math.random(1000, 9999)
    local result = string.format([[
        <tr id="user-%d">
            <td>%d</td>
            <td>%s</td>
            <td>%s</td>
            <td>
                <button
                    hx-delete="/api/users/%d"
                    hx-target="#user-%d"
                    hx-swap="outerHTML">
                    Delete
                </button>
            </td>
        </tr>
    ]], user_id, user_id, name, email, user_id, user_id)
    return is_string(result)
end

--------------------------------------------------------------------------------

function M.countletters(userdata, headers)
    headers:upsert("content-type", "text/html")
    local data = userdata.string or "nothing"
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

function M.delete_user(id, headers)
    headers:upsert("content-type", "text/html")
    local x = is_string(id)
    print("Deleting user with ID:", x)
    local result = ""
    return is_string(result)
end

--------------------------------------------------------------------------------
return M