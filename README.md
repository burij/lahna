Lahna is a bare-bones web server focused on (but not limited to) developing simple htmx applications in Lua. [The project website is a simple demo of this.](https://lahna.burij.de)

> **💡 Author’s Note:**
> There aren’t many simple, fun ways to do web development in Lua. Lahna is my attempt to fill that gap for fellow Lua enthusiasts who want to experiment, learn, or just build something quickly without the usual overhead.

Consider Lahna particularly for the following use cases:
- exploring [htmx](https://htmx.org/) if you have little to no back-end experience
- learning the basics of web development in general
- launching websites in an extremely limited amount of time
- prototyping back-end logic

⚠️ Be aware that running Lahna as it is in production may bring potential risks, especially if database querying and user input are added. The web server is as minimalistic as possible and has not been hardened for security concerns.

# Quick start
## NixOS 

Clone the repository and spin up the development environment:

```
git clone https://github.com/burij/lahna.git && cd lahna && nix-shell -A
```

Start up the webserver:

```
run
```

Visit [localhost:8000](http://localhost:8000)

## Common Linux
1. Install system dependencies:
	- Lua >5.4 (older versions should work, but untested)
	- Luarocks
	- Pandoc
2. Install Lua modules via luarocks: ```luarocks install http```
3. Start the server: ```lua main.lua```
4. Visit [localhost:8000](http://localhost:8000)

# Core Helpers and Extensions

Lahna comes with a set of language extensions and functional helpers (from `lua-light-wings.lua`) that are available globally:

- **Type checks:** `is_string`, `is_number`, `is_table`, `is_function`, `is_boolean`, `is_dictionary`, `is_list`, `is_path`, `is_email`, `is_url`, `is_any` — these throw helpful errors if types are wrong, making debugging easier.
- **Functional helpers:** `map`, `filter`, `reduce` — for working with tables in a functional style.
- **Globalize:** All these helpers are loaded into the global namespace for convenience.

> **💡 Author’s Note:**
> These helpers make the code more robust and let you write Lua in a more expressive, functional way. If you want to extend Lahna, you’ll probably use them a lot!

# Utility Functions

The `modules/utils.lua` file provides handy utilities for:
- Checking if files exist
- Converting Markdown to HTML (requires Pandoc)
- Parsing form data from POST requests
- Reading and writing files
- Simple template processing (see `process_template`)
- Path manipulation

> **Note:** If Pandoc is not installed, Markdown conversion will fail gracefully with a helpful error message.

# Configuration Options

Lahna’s configuration (see `conf.lua`) supports:
- `port`: Port to run the server on (default: 8000)
- `host`: Host address (default: "localhost"; use "0.0.0.0" to share on your network)
- `path`: Path to your public/static files (default: `./public/`)
- `debug_mode`: Enables extra logging and developer features (default: `true`)

You can pass a custom config file as the first argument to `main.lua` or the `run` command.

# Endpoints Overview

Lahna comes with several built-in endpoints:

| Method | Path Pattern         | Description                                      |
|--------|---------------------|--------------------------------------------------|
| GET    | `/`                 | Serves `index.html` from the public folder       |
| GET    | `/demo`             | Serves the demo XML chunk                        |
| GET    | `/readme`           | Renders the project README as HTML               |
| GET    | `/xml/<name>`       | Serves `<name>.xml` from the public folder       |
| GET    | `/md/<name>`        | Renders `<name>.md` as HTML (Markdown to HTML)   |
| POST   | `/api/countletters` | Returns a template with the count of letters in a submitted string |

> **Tip:** You can add your own endpoints by editing `modules/router.lua`.

# Using Lahna as a Project Template

Lahna is designed to be a starting point for your own Lua web projects. Here’s how to make it your own:

1. **Copy the Repository:**  
   Clone or fork Lahna to start your project.
2. **Customize Content:**  
   Replace the files in `public/` with your own HTML, XML, or Markdown content.
3. **Add Routes:**  
   Edit `modules/router.lua` to define new endpoints or API logic.
4. **Tweak the Stack:**  
   Adjust `conf.lua` for your preferred settings, or add new modules as needed.

> **📝 Author’s Tip:**
> I use Lahna as a boilerplate for my own experiments—feel free to rip out what you don’t need and build on what you do!

# Project structure
Lahna brings a starter definition for a complete, but fairly minimal web stack in a single folder: Nix (development environment and package build definition) → Lua (configuration, app logic, static file server, API definition) → HTML (front end) → Markdown (content).

## default.nix
This is not the usual way things are done in NixOS, but this file contains both the definition of the environment and the build script for the deployment package.
This is an easy way to synchronize dependency definitions between both. The downside is that the usual ```nix-shell``` doesn't work.

You'll need to invoke the environment with ```nix-shell -A shell```.

To build the package, use ```nix-build -A package```. Inside the environment, simply use ```build``` (an alias). Be aware of the src definition. By default, the derivation is made from the latest release of this repository, not your modified version. To build your modified project, the src needs to be modified.

```make "commit tag"```

can be used to commit changes to git and run a test build.

```lahna```

starts the server from the built package instead of the source code version.

## main.lua

Application entry point (Lua convention), used only as a runtime composer. After the necessary state is created, the server will be launched by a function call:

```
if debug_mode then test.prestart(conf) end
app.run(conf)
```

The runtime is composed through the following files:

### ./modules/lua-light-wings.lua

Custom Lua module (also available on luarocks), contains some language extensions, specifically a type system and higher-order functions. In Lahna, this module populates the global space.

### ./modules/server.lua

Standalone web server written in Lua. Relies on the http module. Designed not to be modified during development. This module contains the main application logic (function server.run); it is only consumed by main and it consumes

### ./modules/router.lua

The back-end definition lives here. Depending on the request method, functions are called:

- router.get
- router.post
- router.delete

These read the endpoint and dispatch the request by upserting headers, setting status, and calling endpoint-specific functions. This is how a route definition looks inside the router.get function:

```
    if x:match( "^/demo/?$" ) then
        headers:upsert("content-type", "text/html")
        result = M.init_demo()
        status = "200"
    end
```

Wildcard requests are defined for GET requests to /xml/anything and /md/anything, which is very handy when working with htmx. A GET request to /md/blogentry250724 would always return the parsed HTML of /staticcontentfolder/blogentry250724.md. The same applies to XML (except no parsing is involved). This allows you to add content and components to the application without touching the API definition or restarting the web server.

### conf.lua

Basic server settings:

```
conf.port = 8000
conf.host = "localhost"
conf.path = "./public/"
```

This is a typical configuration file; all additional user settings can be declared here and passed through the application. This also makes sense because a path to a custom configuration can be passed as the first argument to main.lua:
```lua main.lua '/home/to/other/config/'``` 
or in the environment:
```run '/home/to/other/config/'```

This design makes it possible to run multiple front-ends via a single back-end or run the back-end in a read-only location (like nix-store) by maintaining the frontend and content as editable.

# Usage (opinionated)

The web server is running, so let's explore how a web application can be developed.

The whole application is written in a pragmatic, semi-functional style. Data modification, loops, and other OOP concepts are mostly encapsulated in functions, which are organized in modules. No inheritance is used. These are self-imposed rules to make data flow simple and the application easier to maintain and debug.

> **💡 Author’s Note:**
> Embracing htmx might mean rethinking how you approach web development—especially if you’re used to big frameworks. I found that writing plain HTML and working directly with the DOM can be surprisingly liberating and fun!

Embracing htmx possibilities might require some radical changes in the way you approach web development, especially if you are coming from big popular frameworks. It might be necessary to get familiar with writing straight HTML and working with the DOM directly. Only if interactive behavior is required, the straightforward workflow would be:

1. Bind an HTTP request to something already existing in the DOM (via htmx in HTML).
2. Decide what needs to be returned.
3. Register the request route.
4. Write a function to parse the desired response.

Probably in most cases, the request is triggered by a click and can be predefined in advance. For example, opening a submenu or loading up contact information. In those conditions, steps 3 and 4 can be skipped. You can pre-store content as .md or .xml in your static files folder and use predefined /md/filename and /xml/filename endpoints. It is often surprising how few operations on a website actually require database communication or calculation, and those that do would need a custom endpoint in this model.

Storing the response data as XML allows you to apply powerful patterns. We can create HTML chunks as reusable components, which contain local styling and new htmx triggers—basically nested components. By the way, XML was also chosen for purely pragmatic reasons: to have an easy distinction between pages like index.html and chunks which will be passed around. Also, some editors would complain about missing headers in HTML files.

What about templates? Templates are a big part of the web; every web page needs a template engine! Well, maybe, but does it need to be very complicated? In the end, what is usually done is to prewrite 99.9% of the rendered HTML and replace values with something calculated or queried. Lahna has a simple function, utils.process_template, which accepts a template as a string and a dictionary with values to replace. This dictionary can also contain functions for replacing specific variables, which makes the construct once again simple but powerful.

So, the approach Lahna takes here is similar to Lua as a language itself. In contrast to frameworks, which bring all the tools you can pick from, Lahna has only what is absolutely necessary to accomplish a simple task fast. This minimizes dependencies, which makes the software durable. If the task to accomplish grows, Lahna can be extended with potentially anything a framework can do and you end up with another framework, but at least at any point in time your software complexity matches the task.

# Status and Roadmap

Version 0.1 was created from a conceptual idea of how an application could work. To test core functionality, application logic and the [demo page](https://lahna.burij.de) were developed in parallel.

The next step will be the development of a real web application, using Lahna as a starting template. In case missing tools are discovered along the way, they will be included in the Lahna repository.

It is most likely that ./modules/utils.lua will become additional helping functions, but changes in the core server are also possible.

After this process, around the end of 2026, beta version 0.9 is planned.

# Why Lahna? (Philosophy Recap)

- **Minimal by Design:** Only the essentials—no bloat, no magic.
- **Fun with Lua:** Web development should be accessible and enjoyable for Lua fans.
- **Pragmatic, Not Dogmatic:** Use what works, skip what doesn’t.
- **Easy to Hack:** Everything’s in one place, ready to be customized.
- **Personal Touch:** This project reflects my own journey—hopefully, it helps yours too!











