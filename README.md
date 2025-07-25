Lahna is a bare bone web server with focus on (but not limited to) developing simple htmx applications in Lua. [Project website is a simple demo of such.](https://lahna.burij.de)

Consider Lahna particulary for following use cases:
- exploring [htmx](https://htmx.org/), if you have little to no back-end experience
- learning basics of web development in general
- launching web sites in extremly limited amount of time
- prototyping back-end logic

⚠️ Be aware, that running Lahna as it is in production may bring potential risks, specially if data base queering and user input added. The web server is as minimalistic as possible and was not hardened for security concerns.

# Quick start
## NixOS 

Clone the repository and spin up development envioriment:

```
git clone https://github.com/burij/lahna.git && cd lahna && nix-shell -A
```

Start up webserver:

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

# Project structure
Lahna brings starter definition for a complete, but fairly minimal web stack in a single folder: Nix (development environment and package build definition) --> Lua (configuration, app logic, static file server, API definition) --> HTML (front end) --> Markdown (content).

## default.nix
Not the way, how things usually done in NixOS, but this file contains both, the definition of the environment and build script for deployment package.
This is an easy way to sync dependency definition between both. Downside is, that usual ```nix-shell``` doesn't work. 

You'll need to invoke the environment with ```nix-shell -A shell```. 

To build the package use ```nix-build -A package```. Inside the environment simple ```build``` can be used (alias). Be aware of the src definition. Default is to make derivation the latest release of this repository, not your modified version. To build your modified project src needs to be modified.

```make "commit tag"``` 

can be used to commit changes to git and run test build.

```lahna``` 

starts the server from builded package instead of the source code version.

## main.lua

Application entry point (Lua convention), used only as runtime composer. After necessary state is created, the server will be launched by a function call:

```
if debug_mode then test.prestart(conf) end
app.run(conf)
```

The runtime is composed trough following files:

### ./modules/lua-light-wings.lua

Custom Lua module (also avaible on luarocks), contains some language extensions, specificly type system and higher order function. In Lahna this module populates global space.

### ./modules/server.lua

Stand alone web server written in Lua. Relies on http module. Designed not to be modified during development. This module contains the main application logic (function server.run), it is only consumed by main and it consumes

### ./modules/router.lua

The back-end definition lives here. Depending on the request method function are called:

- router.get
- router.post
- router.delete

Those are reading the endpoint and dispatching request by upserting headers, setting status and calling endpoint specific functions. This is how route definition looks inside router.get function:

```
    if x:match( "^/demo/?$" ) then
        headers:upsert("content-type", "text/html")
        result = M.init_demo()
        status = "200"
    end
```

Wild card requests are defined for get requests to /xml/anything and /md/anything, which is very handy working with htmx. Get request to /md/blogentry250724 would always return parsed html of /staticcontentfolder/blogentry250724.md. Same with xml (exept no parsing is involved). This allows to add content and components to the application, without touching the API definition or restarting the web server.

### conf.lua

Basic server settings:

```
conf.port = 8000
conf.host = "localhost"
conf.path = "./public/"
```

Typical configuration file, all additional user settings can be declared here and passed trough the application. This also makes sense, because a path to a custom configuration can be passed as first argument to main.lua:
```lua main.lua '/home/to/other/config/``` 
or in the enviroment :
```run '/home/to/other/config/```

This design makes possible to run multiple front-ends via single back-end or run back-end in a read only location (like nix-store) by maintaining frontend and content editable.

# Usage (opinionated)

Web server is running, let's explore, how a web application can be developed. 

The whole application is written in pragmatic semi-functional style. Data modification, loops and other OOP concepts are mostly encapsulated in functions, which are organised in modules. No inheritance is used. Those are self-indicted rules, to make data flow simple and the application easier to maintain and debug.

Embrasing htmx possibilitys might require some radical changes in the way how to aproach web development, specialy coming from big popular frameworks. It might be necessary to get familiar with writing straight html and working with dome directly. Only if interactiv behaviour is required, the straight forward workflow would be:

1. Bind a http-request to something already existing in the dome (via htmx in html).
2. Decide what needs to be returned.
3. Register request route
4. Write a function to parse desired response.

Probably in most cases the request is triggered by click, and can be predefined in advance. For example opening a submenu or loading up contact information. In that conditions steps 3 and 4 can be skipped. You can prestore content as .md or .xml in your static files folder and use predefinded /md/filename and /xml/filename endpoints. It is often surprising how little operations on a website actually do require data base communication or calculation and following do would need a custom end point in this model.

Storing the response data as xml allows to apply powerful patterns. We can create html chuncks as resusable components, which contain local styling and new htmx triggers. Basicly nested components. By the way, xml was also chosen for purely pragmatic reasons: to have easy disctinction between pages like index.html and chuncks which will be passed around. Also some editors would complain about missing header in html-files.

What about templates? Templates are big part of the web, every web page needs a template engine! Well maybe, but does it need to be very complicated. In the end, what would usually be done, is to prewrite 99,9% percent of the rendered html and replace values with something calculated or queryied. Lahna has a simple function utils.process_template, which accepts a template as strings and a dictionary with values to replace. This dictionary can also contain functions for replacing of specific variables, which makes the construct ones again simple but powerful.

So approach Lahna takes here, is simmilar to Lua as language itself. In opposite to frameworks, which kinda bring all the tools you can pick from, Lahna has the absolutly necessary to acomplish a simple task fast. This minimizes dependencies, which makes the software durably. If the task to acomplish grows, Lahna can be extended with potentially anything a framework can do and you end up with another framework, but at least to any point in time your software complexity matched the task.

# Status and Roadmap

Version 0.1 is created from a conceptual idea, how an application could work. To test core functionality, application logic and the [demo page](https://lahna.burij.de) were developed in parallel.

Next step will be a development of a real web application, using Lahna as starting template. In case missing tools will be discovered along the way, they will be included in Lahna repository.

It is most likely, that ./modules/utils.lua will become additional helping functions, but also changes in the core server are possible.

After this process around end of 2026 beta version 0.9 is planed. 

















