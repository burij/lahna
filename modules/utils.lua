local M = {}
--------------------------------------------------------------------------------

function M.file_exists(path)
    local x = is_path(path)
    local f = io.open(x, "r")
    local result = false
    if f ~= nil then
        io.close(f)
        result = true
    end
    return is_boolean(result)
end

--------------------------------------------------------------------------------

function M.parse_form(body)
    if not body then return {} end

    local function decode_url(input)
        local x = input or ""
        local result = string.gsub(
            string.gsub(x, "+", " "),
            "%%(%x%x)",
            function(hex) return string.char(tonumber(hex, 16)) end
        )
        return is_string(result)
    end

    local function parse_pair(pair)
        local key, value = string.match(pair, "([^=]+)=([^=]*)")
        if key and value then
            return decode_url(key), decode_url(value)
        end
        return nil, nil
    end

    local result = {}
    for pair in string.gmatch(body, "[^&]+") do
        local key, value = parse_pair(pair)
        if key then
            result[key] = value
        end
    end
    return is_table(result)
end

--------------------------------------------------------------------------------

function M.read_file(path)
    -- returns content of given file
    local x = is_string(path)
    local file = io.open(path, "r")
    if file then
        content = file:read("*all")
        file:close()
    else
        content = filename .. " not found or not readable!"
    end
    local str = content
    return str
end

--------------------------------------------------------------------------------

function M.replace(text, variable, value)
    local x = is_string(text)
    local y = is_string(variable)
    local z = is_string(value)
    local result = x
    if result:find(y, 1, true) then
        return result:gsub(y, z)
    else
        return result
    end
end

--------------------------------------------------------------------------------
return M