

local connection = require("src.umg.shared.connection")


-- On boot, the client opens its ENet host and connects to the server.
-- (localClient -> localhost:port, else clientIpPort; see launchArgs)
connection.start()


function love.draw()
    love.graphics.print("[CLIENT LOADED]", 100,100)
end


function love.update(dt)
    connection.poll()
    connection.flush()
end
