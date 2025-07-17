Imagine you need or want to create a simple, but dynamic web application and it doesn't automatically mean installing 201 Node.js dependencies or accepting a subscription with a $25 monthly fee.

HTMX made an immense and fairly underrated contribution to solving this problem. But there's still an open question regarding a suitable back-end solution.
Usually you'll get the recommendation to use Django, Flask, or write the back-end in Go. But I would like to write my application logic in Lua. It's a great, simple, and readable prototyping language. There might be better solutions for production, but not many for a quick working draft that can be understood by other team members.
HPLN was the first attempt at HTMX on the front-end and Lua on the back-end.

Generating HTML by having nginx execute Lua scripts felt natural at first. A look at the default.nix of this project will reveal quite some duct taping that was necessary to make it work.

So Lahna is just the next step in simplification. It's a web server written in Lua with just a couple of dependencies by default.
