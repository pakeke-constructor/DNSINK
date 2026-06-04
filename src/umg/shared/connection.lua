local enet = require("enet")
local packets = require("src.umg.shared.packets")


---@class umg.connection
local connection = {}


-- enet channels: reliable packets and unreliable packets are kept on
-- separate channels so a backlog of reliable data can't stall unreliable data.
local RELIABLE_CHANNEL = 0
local UNRELIABLE_CHANNEL = 1


local host -- the enet host
local serverPeer -- (client only) peer pointing at the server

local clients = {--[[
    [clientId] -> peer    (server only) connected clients
]]}

-- [packetName] -> function(clientId_or_nil, ...) registered packet handlers
local handlers = {}


---@param peer table
local function peerToClientId(peer)
    return peer:index()
end



--------------------------------------------------------------------
-- Buffers
-- reliable and unreliable packets get separate buffers so that a
-- big reliable buffer never blocks unreliable (or vice-versa).
--------------------------------------------------------------------

local function newBufferPair()
    return {
        [RELIABLE_CHANNEL] = packets.Buffer(),
        [UNRELIABLE_CHANNEL] = packets.Buffer(),
    }
end

-- (client) buffers destined for the server
local clientBuffers = newBufferPair()

-- (server) per-client buffers, plus broadcast buffers
local clientUnicastBuffers = {--[[ [clientId] -> bufferPair ]]}
local broadcastBuffers = newBufferPair()


local function channelOf(packetType)
    return packets.isPacketUnreliable(packetType) and UNRELIABLE_CHANNEL or RELIABLE_CHANNEL
end


local function getUnicastBuffers(clientId)
    local b = clientUnicastBuffers[clientId]
    if not b then
        b = newBufferPair()
        clientUnicastBuffers[clientId] = b
    end
    return b
end



--------------------------------------------------------------------
-- Connection setup
--------------------------------------------------------------------

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
        host = enet.host_create(ipport, nil, 2)
        log.info("Server listening on " .. ipport)
    else
        host = enet.host_create(nil, 1, 2)
        serverPeer = host:connect(ipport, 2)
        log.info("Client connecting to " .. ipport)
    end
end



--------------------------------------------------------------------
-- Receiving
--------------------------------------------------------------------

---@param clientId integer? nil on client (packet came from server)
---@param data string
local function dispatch(clientId, data)
    local ok, result = packets.deserialize(data)
    if not ok then
        log.warn("bad packet: " .. tostring(result))
        return
    end
    ---@cast result table[]
    for _, packet in ipairs(result) do
        local name = packet[1]
        local handler = handlers[name]
        if handler then
            handler(clientId, unpack(packet, 2))
        else
            log.warn("no handler for packet: " .. tostring(name))
        end
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
                clients[peerToClientId(ev.peer)] = ev.peer
            end
        elseif ev.type == "receive" then
            dispatch(SERVER and peerToClientId(ev.peer) or nil, ev.data)
        elseif ev.type == "disconnect" then
            if SERVER then
                local id = peerToClientId(ev.peer)
                clients[id] = nil
                clientUnicastBuffers[id] = nil
            end
        end
        ev = host:service(0)
    end
end



--------------------------------------------------------------------
-- Sending (internal queueing)
--------------------------------------------------------------------

-- (client) queue a packet to the server
local function queueToServer(packetType, ...)
    clientBuffers[channelOf(packetType)]:push(packetType, ...)
end

-- (server) queue a packet to one client
local function queueToClient(clientId, packetType, ...)
    getUnicastBuffers(clientId)[channelOf(packetType)]:push(packetType, ...)
end

-- (server) queue a packet to all clients
local function queueBroadcast(packetType, ...)
    broadcastBuffers[channelOf(packetType)]:push(packetType, ...)
end


local function sendBufferPair(target, bufs)
    for channel, flag in pairs({[RELIABLE_CHANNEL]="reliable", [UNRELIABLE_CHANNEL]="unsequenced"}) do
        local data = bufs[channel]:flush()
        if #data > 0 then
            target:send(data, channel, flag)
        end
    end
end


---Flush all buffers and send them over the network.
function connection.flush()
    if SERVER then
        for clientId, bufs in pairs(clientUnicastBuffers) do
            local peer = clients[clientId]
            if peer then
                sendBufferPair(peer, bufs)
            end
        end
        sendBufferPair(host, broadcastBuffers)
    else
        if serverPeer then
            sendBufferPair(serverPeer, clientBuffers)
        end
    end
end



--------------------------------------------------------------------
-- RPC
--------------------------------------------------------------------

---@param packetType string
---@param typelist umg.packets.PacketType[]
---@param func function
local function defineRPC(packetType, typelist, func, isUnreliable)
    packets.definePacketType(packetType, typelist, isUnreliable)
    handlers[packetType] = func
end


---Define a client->server RPC.
---`func(clientId, ...)` runs on the SERVER when the packet is received.
---The returned function, called on the CLIENT, queues the packet to the server.
---@param packetType string
---@param typelist umg.packets.PacketType[]
---@param func fun(clientId:integer, ...)
---@param isUnreliable? boolean
---@return fun(...)
function connection.clientToServerRPC(packetType, typelist, func, isUnreliable)
    if SERVER then
        defineRPC(packetType, typelist, func, isUnreliable)
        return function() error("clientToServerRPC '" .. packetType .. "' cannot be sent from server") end
    else
        packets.definePacketType(packetType, typelist, isUnreliable)
        return function(...)
            queueToServer(packetType, ...)
        end
    end
end


---Define a server->client RPC.
---`func(...)` runs on the CLIENT when the packet is received.
---The returned function, called on the SERVER, queues the packet.
---Call `rpc(clientId, ...)` to unicast, or `rpc(nil, ...)` to broadcast.
---@param packetType string
---@param typelist umg.packets.PacketType[]
---@param func fun(...)
---@param isUnreliable? boolean
---@return fun(clientId:integer?, ...)
function connection.serverToClientRPC(packetType, typelist, func, isUnreliable)
    if SERVER then
        packets.definePacketType(packetType, typelist, isUnreliable)
        return function(clientId, ...)
            if clientId then
                queueToClient(clientId, packetType, ...)
            else
                queueBroadcast(packetType, ...)
            end
        end
    else
        defineRPC(packetType, typelist, func, isUnreliable)
        return function() error("serverToClientRPC '" .. packetType .. "' cannot be sent from client") end
    end
end



return connection
