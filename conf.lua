local conf = {debug_mode = true}

conf.port = tonumber(os.getenv("LAHNA_PORT")) or 8000

conf.host = os.getenv("LAHNA_HOST") or "localhost"
-- to share on network: "0.0.0.0"

conf.path = "./public/"

return conf