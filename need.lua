local autodownload = false
--------------------------------------------------------------------------------
local M = function (module, source)
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

return M