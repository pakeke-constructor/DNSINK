
local Class = require("src.modules.objects.Class")


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


---@param name string
---@param typelist table
function packets.definePacket(name, typelist)
    packetTypes[name] = currId
    currId = currId + 1
    -- todo, fill in
end


---@class umg.Packets.Buffer: objects.Class
local Buffer = Class("umg.packets:Buffer")

function Buffer:init()
    self.buf = {}
end

function Buffer:push(packetId,...)
    -- pushes to buf
end

---@return string serialized string
function Buffer:flush()
end




---@param name string
---@param typelist table
function packets.definePacket(name, typelist)
    packetTypes[name] = currId
    currId = currId + 1
end


do
local buffer = require("string.buffer")

print(buffer.decode(buffer.encode(42)))       --> 42
print(buffer.decode(buffer.encode("hello")))  --> hello
print(buffer.decode(buffer.encode({true, "hello"})))     --> {true, "hello"}

--[[
for this, you should ser/deser the entire table as one big go.
]]
end



return packets

