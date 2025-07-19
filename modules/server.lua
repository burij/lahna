local M = {}

--------------------------------------------------------------------------------

function M.run(user_configuration)
    local x = is_dictionary(user_configuration)
    if debug_mode then print "application starting..." end
    -- TODO handling of initial files and folders
    print("🚀 Starting server...")

    local server = M.create_server(x.host, x.port)
    M.start_server(server)
end

--------------------------------------------------------------------------------

function M.create_server(host, port)
    local x = is_string(host)
    local y = is_number(port)
    local http_server = require "http.server"
    local settings = {host = x, port = y, onstream = M.handle_request}
    local result = http_server.listen(settings)
    if not result then
        print("💥 Error: Could not bind to " .. x .. ":" .. y)
    else
        print("📍 Server running at http://" .. x .. ":" .. y)
    end
    return result
end

--------------------------------------------------------------------------------

function M.start_server(server)
    local x = is_dictionary(server)
    local ok, err = pcall(x.loop, x)
    if not ok and debug_mode then
        print("☔ Server error:", err)
    end
    print "💥\n🛬 Shutting down server..."
    return ok, err
end

--------------------------------------------------------------------------------

function M.handle_request(server, stream)
    local ok, err = pcall(function()
        local http_headers = require "http.headers"
        local route = require "modules.router"
        local request_headers = stream:get_headers()
        local request_method = request_headers:get(":method")
        local request_path = request_headers:get(":path")
        print(
            string.format("🙏 %s %s", request_method, request_path)
        )

        local response_headers = http_headers.new()
        response_headers:append(":status", "200")
        response_headers:append("content-type", "text/html")

        local response_body = ""
        local status = "200"

        if request_method == "GET" then
            response_body, status = route.get(request_path, response_headers)
            if response_body == "" then
                response_body, status = M.handle_static_files(
                    request_path, response_headers
                )
            end
        elseif request_method == "POST" then
            response_body, status = route.post(
                request_path, stream, response_headers
            )
        elseif request_method == "DELETE" then
            response_body, status = route.delete(request_path, response_headers)
        else
            response_headers:upsert(":status", "405")
            response_body = "405: Method Not Allowed"
            status = "405"
        end

        response_body = response_body or ""
        status = status or "500"
        response_headers:upsert(":status", status)
        stream:write_headers(response_headers, false)
        stream:write_chunk(response_body, true)
    end)
    if not ok then
        print("Request error:", err)
        -- Optionally, send a 500 response to the client here
    end
end

--------------------------------------------------------------------------------

function M.handle_static_files(path, headers)
    local x = is_string(path)
    local y = headers
    local z = is_string(_G.public_user_folder or "public/")

    local clean_path = x:gsub("^/", ""):gsub("%.%./", "")
    local file_path = clean_path == "" and
        z .. "index.html" or z .. clean_path

    local content, err = M.serve_file(file_path)
    local content_type = "text/plain"
    if content and content ~= "" then
        content_type = M.get_content_type(file_path)
        y:upsert("content-type", content_type)
        return content, "200"
    else
        content = "404: File Not Found"
        return content, "404"
    end
end

--------------------------------------------------------------------------------

function M.get_content_type(file_path)
    local x = is_string(file_path)
    local ext = x:match("%.([^%.]+)$")
    local content_types = {
        html = "text/html",
        css = "text/css",
        js = "application/javascript",
        json = "application/json",
        png = "image/png",
        jpg = "image/jpeg",
        jpeg = "image/jpeg",
        gif = "image/gif",
        svg = "image/svg+xml",
    }
    return content_types[ext] or "text/plain"
end

--------------------------------------------------------------------------------

function M.serve_file(path)
    print("🌐 Serving file called with path:", path)
    if not path then
        print("serve_file called with nil path! Defaulting to empty string.")
        path = ""
    end
    local x = is_string(path)
    local file = io.open(x, "r")
    local content, err = nil, "File not found"
    if file then
        content = file.read(file, "*all")
        file.close(file)
        err = nil
    end
    -- Defensive: always return a string for content
    if not content then
        content = ""
    end
    return content, err
end

--------------------------------------------------------------------------------

return M