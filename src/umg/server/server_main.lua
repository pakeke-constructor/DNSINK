
local connection = require("src.umg.shared.connection")


-- On boot, the server opens its ENet host and starts listening.
-- (localServer -> localhost:port, else serverIpPort; see launchArgs)
connection.start()


function love.update(dt)
    connection.poll()
    connection.flush()
end
