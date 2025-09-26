local M = {}
--------------------------------------------------------------------------------
function M.need(module, source, autodownload)
    -- phase 1: extend paths, if not already done
    local version = _VERSION:match("%d+%.%d+")
    local user = os.getenv('USER') or os.getenv('USERNAME')
    local custom_path = "/home/" .. user .. "/.lua-modules"
    local l_paths = {
        "./modules/?.lua",
        custom_path .. "/?.lua",
        "./pkgs/share/lua/" .. version .. "/?.lua",
        "./pkgs/share/lua/" .. version .. "/?/init.lua",
        "/home/" .. user .. "/.luarocks/share/lua/" .. version .. "/?.lua",
        "/home/" .. user .. "/.luarocks/share/lua/" .. version .. "/?/init.lua",
    }

    local c_paths = {
        "./pkgs/lib/lua/" .. version .. "/?.so",
        "/home/" .. user .. "/.luarocks/lib/lua/" .. version .. "/?.so",
    }

    if not string.find(package.path, "modules", 1, true) then
        for i, v in ipairs(l_paths) do
            package.path = l_paths[i] .. ";" .. package.path end
        for i, v in ipairs(c_paths) do
            package.cpath = c_paths[i] .. ";" .. package.cpath end
    end

    -- returns false, if module not avaible
    local function is_module_available(x)
        local ok, y = pcall(require, x)
        return ok and y
    end

    if autodownload == true then
        -- try find via luarocks
        if not is_module_available(module) then
            local query = source or module
            os.execute([[luarocks install "]] .. query .. [[" --local]])
        end

            -- try find via luarocks inside result (for test builds in NixOS)
        if not is_module_available(module) then
            local query = source or module
            os.execute([[./result/bin/luarocks install "]] .. query
                .. [[" --local]])
        end

        -- try download via curl
        if not is_module_available(module)
        and string.find(source, "https://", 1, true) then
            os.execute("mkdir " .. custom_path)
            os.execute([[curl -O ]] .. custom_path .. [[/]]
                .. module .. [[.lua ]] .. source)
        end

        -- try download via wget
        if not is_module_available(module)
        and string.find(source, "https://", 1, true) then
            os.execute("mkdir " .. custom_path)
            os.execute([[wget -O ]] .. custom_path .. [[/]]
                .. module .. [[.lua ]] .. source)
        end
    end

    -- last check. if still fails, give warning or sucseed
    local result = is_module_available(module)
    if not result == false then
        return require (module)
    else
        print("warning: required module '" .. module .. "' is missing")
    end
end

--------------------------------------------------------------------------------
function M.msg(x)
    -- -- console output, can handle tables
    if type(x) ~= "table" then
       print(x)
       return
    end

    local function is_identifier(str)
       return type(str) == "string" and str:match("^[_%a][_%a%d]*$")
    end

    local function get_keys(t)
       -- Get sequential keys
       local seq_len = 1
       while rawget(t, seq_len) ~= nil do
          seq_len = seq_len + 1
       end
       seq_len = seq_len - 1

       -- Get remaining keys
       local keys = {}
       for k in next, t do
          if not (type(k) == "number"
            and math.floor(k) == k and 1 <= k and k <= seq_len) then
             keys[#keys + 1] = k
          end
       end

       -- Sort keys
       table.sort(keys, function(a, b)
          local ta, tb = type(a), type(b)
          if ta == tb and (ta == 'string' or ta == 'number') then
             return a < b
          end
          return tostring(a) < tostring(b)
       end)

       return keys, #keys, seq_len
    end

    local function smart_quote(str)
       if str:match('"') and not str:match("'") then
          return "'" .. str .. "'"
       end
       return '"' .. str:gsub('"', '\\"') .. '"'
    end

    local function put_value(buf, v, level, visited)
       if visited[v] then
          buf[#buf + 1] = "<cycle>"
          return
       end

       local tv = type(v)
       if tv == 'string' then
          buf[#buf + 1] = smart_quote(v)
       elseif tv == 'number' or tv == 'boolean' or tv == 'nil' then
          buf[#buf + 1] = tostring(v)
       elseif tv == 'table' then
          visited[v] = true

          local keys, key_len, seq_len = get_keys(v)
          buf[#buf + 1] = "{ "

          -- Handle sequential part
          for i = 1, seq_len do
             if i > 1 then buf[#buf + 1] = ", " end
             put_value(buf, v[i], level + 1, visited)
          end

          -- Handle remaining keys
          for i = 1, key_len do
             if seq_len > 0 or i > 1 then buf[#buf + 1] = ", " end
             buf[#buf + 1] = "\n" .. string.rep("  ", level + 1)

             local k = keys[i]
             if is_identifier(k) then
                buf[#buf + 1] = k
             else
                buf[#buf + 1] = "["
                put_value(buf, k, level + 1, visited)
                buf[#buf + 1] = "]"
             end
             buf[#buf + 1] = " = "
             put_value(buf, v[k], level + 1, visited)
          end

          if key_len > 0 then
             buf[#buf + 1] = "\n" .. string.rep("  ", level)
          elseif seq_len > 0 then
             buf[#buf + 1] = " "
          end

          buf[#buf + 1] = "}"
          visited[v] = nil
       else
          buf[#buf + 1] = "<" .. tv .. ">"
       end
    end

    local buf = {}
    put_value(buf, x, 0, {})
    print(table.concat(buf))
    return type(x)
 end
--------------------------------------------------------------------------------
function M.globalize(x)
    -- loads content of a module to a global space
    M.is_dictionary(x)
    for k, v in pairs(x) do
        _G[k] = v
    end
end
--------------------------------------------------------------------------------
function M.is_dictionary(x)
    if type(x) ~= "table" then
        error("expected a dictionary, got " .. type(x), 2)
    end
    local has_non_numeric_key = false
    local numeric_keys = {}
    for k, _ in pairs(x) do
        if type(k) ~= "number" then
            has_non_numeric_key = true
            break
        end
        table.insert(numeric_keys, k)
    end
    if not has_non_numeric_key and #numeric_keys > 0 then
        table.sort(numeric_keys)
        for i = 1, #numeric_keys do
            if numeric_keys[i] ~= i then
                has_non_numeric_key = true
                break
            end
        end
        if not has_non_numeric_key then
            error("expected a dictionary, got " .. type(x), 2)
        end
    end
    return x
end
--------------------------------------------------------------------------------
function M.is_any(x)
    if x == nil then
        error("expected a value, got nil", 2)
    end
    return x
end
--------------------------------------------------------------------------------
function M.is_path(x)
    if type(x) ~= "string" then
        error("expected a path string, got " .. type(x), 2)
    end
    local file = io.open(x, "r")
    if not file then
        error("path does not exist or is not accessible: " .. x, 2)
    end
    file:close()
    return x
end
--------------------------------------------------------------------------------
function M.is_email(x)
    if type(x) ~= "string" then
        error("expected an email string, got " .. type(x), 2)
    end
    local pattern = "^[%w%.%%%+%-]+@[%w%.%%%+%-]+%.%w+$"
    if not string.match(x, pattern) then
        error("invalid email format: " .. x, 2)
    end
    return x
end
--------------------------------------------------------------------------------
function M.is_url(x)
    if type(x) ~= "string" then
        error("expected a URL string, got " .. type(x), 2)
    end
    local pattern = "^https?://[%w%.%%%+%-]+%.[%w%.%%%+%-]+[%w%.%%%+%-/%?=&#]+$"
    if not string.match(x, pattern) then
        error("invalid URL format: " .. x, 2)
    end
    return x
end
--------------------------------------------------------------------------------
function M.is_list(x)
    if type(x) ~= "table" then
        error("expected a list, got " .. type(x), 2)
    end
    local len = #x
    for k, _ in pairs(x) do
        local is_not_number = type(k) ~= "number"
        local is_out_of_bounds = k > len or k <= 0
        local is_not_integer = math.floor(k) ~= k
        if is_not_number or is_out_of_bounds or is_not_integer then
            error("expected a list, got " .. type(x), 2)
        end
    end
    return x
end
--------------------------------------------------------------------------------
function M.is_boolean(x)
    if type(x) ~= "boolean" then
        error("expected a boolean, got " .. type(x), 2)
    end
    return x
end
--------------------------------------------------------------------------------
function M.is_string(x)
    if type(x) ~= "string" then
        error("expected a string, got " .. type(x), 2)
    end
    return x
end
--------------------------------------------------------------------------------
function M.is_number(x)
    if type(x) ~= "number" then
        error("expected a number, got " .. type(x), 2)
    end
    return x
end
--------------------------------------------------------------------------------
function M.is_table(x)
    if type(x) ~= "table" then
        error("expected a table, got " .. type(x), 2)
    end
    return x
end
--------------------------------------------------------------------------------
function M.is_function(x)
    if type(x) ~= "function" then
        error("expected a function, got " .. type(x), 2)
    end
    return x
end
--------------------------------------------------------------------------------
function M.map(x, y)
    -- calls function on every element of a table
    M.is_table(x)
    M.is_function(y)
    local tbl = {}
    local is_list = (#x > 0)
    if is_list then
        for i, v in ipairs(x) do
            tbl[i] = y(v)
        end
    else
        for k, v in pairs(x) do
            tbl[k] = y(v)
        end
    end
    return tbl
end
--------------------------------------------------------------------------------
function M.filter(x, y)
    -- filters table elements based on predicate function
    M.is_table(x)
    M.is_function(y)
    local tbl = {}
    local is_list = (#x > 0)
    if is_list then
        for i, v in ipairs(x) do
            if y(v) then
                table.insert(tbl, v)
            end
        end
    else
        for k, v in pairs(x) do
            if y(v) then
                tbl[k] = v
            end
        end
    end
    return tbl
end
--------------------------------------------------------------------------------
function M.reduce(x, y, var)
    -- reduces table to single value using accumulator function
    M.is_table(x)
    M.is_function(y)
    local is_list = (#x > 0)
    local accumulator = var
    if is_list then
        for _, v in ipairs(x) do
            accumulator = y(accumulator, v)
        end
    else
        for _, v in pairs(x) do
            accumulator = y(accumulator, v)
        end
    end
    return accumulator
end
--------------------------------------------------------------------------------
return M
