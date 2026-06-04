local enet = require("enet")
local packets = require("src.umg.shared.packets")


---@class umg.connection
local connection = {}


local host -- the enet host
local serverPeer -- (client only) peer pointing at the server

local clientUnicastBuffers = {--[[
    [clientId] -> Buffer
    clients must have "personal" buffers for unicasting, or else it'll be mixed into the broadcast buffer
]]}

local clients = {} -- (server only) set of connected peers


local function getIpPort()
    if SERVER then
        if launchArgs.localServer then
            return consts.LOCALHOST_UDP_IPPORT
        end
        return launchArgs.serverIpPort
    else
        if launchArgs.localClient then
            return consts.LOCALHOST_UDP_IPPORT
        end
        return launchArgs.clientIpPort
    end
end


---Start the connection. On server, listens; on client, connects to server.
function connection.start()
    local ipport = getIpPort()
    if SERVER then
        host = enet.host_create(ipport)
        log.info("Server listening on " .. ipport)
    else
        host = enet.host_create()
        serverPeer = host:connect(ipport)
        log.info("Client connecting to " .. ipport)
    end
end


---@param ev table enet event
local function handleReceive(ev)
    local ok, result = packets.deserialize(ev.data)
    if not ok then
        log.warn("bad packet: " .. tostring(result))
        return
    end
    assert(type(result)=="table")
    for _, packet in ipairs(result) do
        local name = packet[1]
        umg.call(name, ev.peer, unpack(packet, 2))
    end
end


---Pump the network. Call every frame.
---@param timeout? number ms to block (default 0)
function connection.poll(timeout)
    if not host then return end
    local ev = host:service(timeout or 0)
    while ev do
        if ev.type == "connect" then
            if SERVER then
                clients[ev.peer] = true
                umg.call("clientConnected", ev.peer)
            else
                umg.call("connectedToServer")
            end
        elseif ev.type == "receive" then
            handleReceive(ev)
        elseif ev.type == "disconnect" then
            if SERVER then
                clients[ev.peer] = nil
                umg.call("clientDisconnected", ev.peer)
            else
                umg.call("disconnectedFromServer")
            end
        end
        ev = host:service(0)
    end
end


---(client) send a buffer to the server.
---@param buf umg.Packets.Buffer
function connection.sendToServer(buf)
    serverPeer:send(buf:flush(), 0, "reliable")
end


local function clientIdToPeer(clientId)
    error("not yet implemented, do this later.")
end


---(server) send a buffer to a specific client peer.
---@param clientId string
---@param packetType string
---@param ... any
function connection.unicastToClient(clientId, packetType, ...)
    local peer = clientIdToPeer(clientId)
    error("not yet implemented, dont worry about this for now.")
end


---(server) broadcast a packet +args to all clients.
---@param packetType string
---@param ... any
function connection.broadcastToClients(packetType, ...)
    host:broadcast(...) -- todo, fill this in
end


---(server) broadcast a packet +args to all clients.
---@param packetType string
---@param ... any
function connection.sendToServer(packetType, ...)
    -- todo, fill this in
end


function connection.flush()
    -- flushes ALL buffers and sends them over network
end


function connection.handle(packetName, func)
    -- register packet handler, func is called when recv packet
end



return connection
