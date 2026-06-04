local enet = require "enet"

local host = enet.host_create("localhost:6789")
print("Server listening on port 6789...")

while true do
    local event = host:service(100)
    if event then
        if event.type == "connect" then
            print("Client connected:", event.peer)
            event.peer:send("Welcome to the server!")

        elseif event.type == "receive" then
            print("Received:", event.data, "from", event.peer)
            -- Broadcast to all peers
            host:broadcast("Echo: " .. event.data)

        elseif event.type == "disconnect" then
            print("Client disconnected:", event.peer)
        end
    end
end














local enet = require "enet"

local host = enet.host_create()
local server = host:connect("localhost:6789")

local running = true
local connected = false

while running do
    local event = host:service(100)
    if event then
        if event.type == "connect" then
            print("Connected to server!")
            connected = true
            server:send("Hello, server!")

        elseif event.type == "receive" then
            print("Received:", event.data)

            -- Disconnect after getting a reply
            server:disconnect()

        elseif event.type == "disconnect" then
            print("Disconnected from server.")
            running = false
        end
    end
end



enet.host_create(addr)Creates a host. Pass an address to listen (server), or nil/nothing for a client.host:service(timeout_ms)Pumps the network loop. Returns an event or nil.event.type"connect", "receive", or "disconnect"event.peerThe remote peer involved in the eventevent.dataThe message string (on "receive")peer:send(data, channel, flag)Send data. flag can be "reliable", "unsequenced", or "unreliable"host:broadcast(data)Send to all connected peers


peer:send("critical data", 0, "reliable")     -- TCP-like, guaranteed delivery
peer:send("position update", 1, "unreliable") -- Fast, may drop packets
peer:send("fire and forget", 0, "unsequenced")-- Reliable but no order guarantee
