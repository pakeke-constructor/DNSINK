
local objects = require("src.modules.objects.objects")
local table_clear = require("table.clear")

---@class umg.ecs.ECSWorld: objects.Class
---@field public data table<string, any>
local ECSWorld = objects.Class("umg.ecs:ECSWorld")


local PARTITION_CHUNKSIZE = 32

function ECSWorld:init(systemNames)
    self.entities = objects.BufferedSet()

    self.componentIndex = {} -- [componentName] -> {ent, ent, ...}
    self.trackedComponents = objects.Set()
end

function ECSWorld:setBorder(w, h)
    self.border = {0, 0, w, h}
end

function ECSWorld:addEntity(e)
    self.entities:addBuffered(e)
end

function ECSWorld:removeEntity(e)
    e.___removed = true
    self.entities:removeBuffered(e)
end

local function entHas(e, k)
    if rawget(e, k) ~= nil then return true end
    local mt = getmetatable(e)
    local base = mt and rawget(mt, "__index")
    return type(base) == "table" and base[k] ~= nil
end

function ECSWorld:_rebuildComponentIndex()
    local idx = self.componentIndex
    for _, list in pairs(idx) do
        table_clear(list)
    end
    local tracked = self.trackedComponents
    for ti = 1, tracked.len do
        local k = tracked[ti]
        local list = idx[k]
        for i = 1, self.entities.len do
            local e = self.entities[i]
            if entHas(e, k) then
                list[#list + 1] = e
            end
        end
    end
end


function ECSWorld:update(dt)
    self.entities:flush()
    self:_rebuildComponentIndex()
    g.call("preUpdate", dt)

    for i = 1, self.entities.len do
        local e = self.entities[i]
        if e.onUpdate then
            e:onUpdate(dt)
        end
        if e.lifetime then
            e.lifetime = e.lifetime - dt
            if e.lifetime <= 0 then
                self:removeEntity(e)
            end
        end
    end

    g.call("postUpdate", dt)
    self.entities:flush()
end

local function getDrawY(e)
    return e.y - (e.z or 0) / 2
end

local function sortOrder(a, b)
    local ya = getDrawY(a) + (a.drawOrder or 0)
    local yb = getDrawY(b) + (b.drawOrder or 0)
    if ya == yb then return a.id < b.id end
    return ya < yb
end

function ECSWorld:draw(transform)
    g.call("preDraw")

    local list = {}
    for i = 1, self.entities.len do
        list[#list + 1] = self.entities[i]
    end
    table.sort(list, sortOrder)
    for i = 1, #list do
        local e = list[i]
        g.drawEntity(e, e.x, getDrawY(e))
    end

    g.call("postDraw")
end


---@param component string
---@return fun(table: ecs.Entity[], i?: integer):integer
---@return ecs.Entity[]
---@return integer
function ECSWorld:iterate(component)
    local list = self.componentIndex[component]
    if not list then
        list = {}
        self.componentIndex[component] = list
        self.trackedComponents:add(component)
        for i = 1, self.entities.len do
            local e = self.entities[i]
            if entHas(e, component) then
                list[#list + 1] = e
            end
        end
    end
    return ipairs(list)
end



---@param partitionId string
---@param x number
---@param y number
---@param fn fun(ent: ecs.Entity)
---@param range number
function ECSWorld:iteratePartition(partitionId, x, y, fn, range)
    local part = self.partitions[partitionId]
    if part then
        part:query(x, y, fn, range)
    end
end

function ECSWorld:getAllyList()
    return self.allyList
end

function ECSWorld:getEnemyList()
    return self.enemyList
end

return ECSWorld
