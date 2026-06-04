
local Class = require("src.modules.objects.Class")
local buffer = require("string.buffer")


local packetTypes = {--[[
    [packetName] -> {packetId, "number", "number", "string", ...}
]]}

local packetIdToName = {--[[
    [integer-id] -> packetName
]]}


---@class umg.packets
local packets = {}

local currId = 0


---@alias umg.packets.PacketType "number"|"string"|"boolean"|"entity"

local VALID_TYPES = {
    number=true, string=true,
    boolean=true, entity=true,
}


-- TODO: fill these in once entity-replication exists.
local function entToId(ent)
    return 1
end

local function idToEnt(id)
    return {}
end


---@param name string
---@param typelist umg.packets.PacketType[]
function packets.definePacket(name, typelist)
    if packetTypes[name] then
        error("duplicate packet name: " .. name)
    end
    for i, ty in ipairs(typelist) do
        if not VALID_TYPES[ty] then
            error("invalid packet type at index " .. i .. ": " .. tostring(ty))
        end
    end

    local packetId = currId
    currId = currId + 1

    local entry = {packetId}
    ---@cast entry umg.packets.PacketType[]
    for i, ty in ipairs(typelist) do
        entry[i + 1] = ty
    end

    packetTypes[name] = entry
    packetIdToName[packetId] = name
end


---@class umg.Packets.Buffer: objects.Class
local Buffer = Class("umg.packets:Buffer")

function Buffer:init()
    self.buf = {}
end


---@param packetName string
function Buffer:push(packetName, ...)
    local entry = packetTypes[packetName]
    if not entry then
        error("unknown packet: " .. tostring(packetName))
    end

    local packet = {entry[1]}
    for i = 1, select("#", ...) do
        local ty = entry[i + 1]
        local val = select(i, ...)
        if ty == "entity" then
            val = entToId(val)
        end
        packet[i + 1] = val
    end

    self.buf[#self.buf + 1] = packet
end


---@return string serialized string
function Buffer:flush()
    local str = buffer.encode(self.buf)
    self.buf = {}
    return str
end


local luaTypeOf = {
    number = "number",
    string = "string",
    boolean = "boolean",
    entity = "number", -- entities are sent over the wire as numeric ids
}


---Deserialize a flushed buffer into a list of {packetName, ...} packets.
---On the server, the contents are type-validated (clients are untrusted).
---@param str string
---@return boolean ok, table[]|string resultOrError
function packets.deserialize(str)
    local ok, raw = pcall(buffer.decode, str)
    if not ok then
        return false, "failed to decode buffer: " .. tostring(raw)
    end
    if type(raw) ~= "table" then
        return false, "expected a table of packets"
    end

    local out = {}

    for i, packet in ipairs(raw) do
        if type(packet) ~= "table" then
            return false, "packet at index " .. i .. " is not a table"
        end

        local packetId = packet[1]
        local name = packetIdToName[packetId]
        if not name then
            return false, "unknown packet id: " .. tostring(packetId)
        end

        local entry = packetTypes[name]
        local result = {name}
        for j = 2, #entry do
            local ty = entry[j]
            local val = packet[j]

            if SERVER and type(val) ~= luaTypeOf[ty] then
                return false, ("packet '%s' field %d: expected %s, got %s")
                    :format(name, j - 1, ty, type(val))
            end

            if ty == "entity" then
                val = idToEnt(val)
            end
            result[j] = val
        end
        out[i] = result
    end

    return true, out
end



packets.Buffer = Buffer


return packets
