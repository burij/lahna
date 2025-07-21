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

function M.md_to_html(markdown)
    local x = is_string(markdown or "")

    local clean_md = string.gsub(x, "'", "'\"'\"'") -- escape single quotes
    local pandoc_cmd = "echo '" .. clean_md .. "' | pandoc -f markdown -t html"
    local handle = io.popen(pandoc_cmd)

    local result = "Could not execute pandoc command"
    if not handle then
        return is_string(result)
    end

    local result = handle:read("*a")
    local success = handle:close()
    if not success then
        result = "Pandoc conversion failed, Pandoc installed?"
    end

    return is_string(result)
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

function M.process_template(template, variable_set)
    local x = is_string(template)
    local y = is_dictionary(variable_set)
    local result = x
    for k, v in pairs(y) do
        if string.find(result, k, 1, true) then
            result = string.gsub(result, k, v)
        end
    end
    return is_string(result)
end

--------------------------------------------------------------------------------

function M.get_parent(folder)
    local x = is_path(folder)
    local result = nil

    if not x or x == "" then result = nil
    elseif x:match("^[/\\]+$") then result = "/"
    elseif x:match("^%a:[/\\]*$") then
        -- Handle Windows drive root (e.g., "C:" or "C:\")
        local drive_letter = x:match("^(%a:)")
        result = drive_letter .. "\\"
    else
        local clean_path = x:gsub("[/\\]+$", "")
        if clean_path == "" then result = "/"
        else
            local parent = clean_path:match("^(.+)[/\\][^/\\]*$")
            if not parent then result = "."
            elseif parent == "" then result = "/"
            else result = parent end
        end
    end
    return is_path(result)
end

--------------------------------------------------------------------------------
return M