local agentbridge = {}

local PORT = nil
local thread
local cmdChan = love.thread.newChannel()   -- main -> thread: quit command
local recvChan = love.thread.newChannel()  -- thread -> main: incoming messages
local sendChan = love.thread.newChannel()  -- main -> thread: outgoing responses
local crashChan = love.thread.newChannel() -- main -> thread: crash payload to broadcast

local commandHandlers = {}

function agentbridge.start(port)
    if thread and thread:isRunning() then return end
    PORT = port
    thread = love.thread.newThread("src/modules/agentbridge/thread.lua")
    thread:start(cmdChan, recvChan, sendChan, crashChan, PORT)
    log.info("[agentbridge] listening on port " .. PORT)
end

function agentbridge.stop()
    if thread and thread:isRunning() then
        cmdChan:push("quit")
        thread:wait()
    end
end

function agentbridge.registerCommand(name, fn)
    commandHandlers[name] = fn
end

local function handleMessage(clientIdx, raw)
    local ok, msg = pcall(json.decode, raw)
    if not ok or type(msg) ~= "table" then
        return clientIdx .. '|' .. json.encode({error = "invalid json"})
    end

    local cmd = msg.cmd
    local handler = commandHandlers[cmd]
    if not handler then
        return clientIdx .. '|' .. json.encode({error = "unknown command: " .. tostring(cmd), id = msg.id})
    end

    local success, result = pcall(handler, msg)
    if not success then
        return clientIdx .. '|' .. json.encode({error = tostring(result), id = msg.id})
    end

    result = result or {}
    result.id = msg.id
    return clientIdx .. '|' .. json.encode(result)
end

function agentbridge.update()
    if not thread or not thread:isRunning() then return end
    while true do
        local raw = recvChan:pop()
        if not raw then break end

        local sep = raw:find("|", 1, true)
        if sep then
            local clientIdx = raw:sub(1, sep - 1)
            local payload = raw:sub(sep + 1)
            local response = handleMessage(clientIdx, payload)
            if response then
                sendChan:push(response)
            end
        end
    end
end

-----------------------------------------------------------
-- Built-in commands
-----------------------------------------------------------

agentbridge.registerCommand("ping", function(msg)
    return {pong = true}
end)

agentbridge.registerCommand("get_scene", function(msg)
    local _, name = g.getCurrentScene()
    return {scene = name}
end)

agentbridge.registerCommand("get_state", function(msg)
    local scene, name = g.getCurrentScene()
    local result = {scene = name}
    if name == "battle_scene" and scene.ecs then
        local ents = {}
        for i = 1, #scene.ecs.entities do
            local e = scene.ecs.entities[i]
            ents[#ents + 1] = {
                id = e.id,
                type = e.type,
                x = e.x, y = e.y,
                health = e.health,
                maxHealth = e.maxHealth,
                team = e.team,
            }
        end
        result.entities = ents
    end
    if g.hasRun() then
        local run = g.getRun()
        result.health = run.health
        result.maxHealth = run.maxHealth
        result.money = run.money
        result.food = run.food
        result.day = run.day
    end
    return result
end)

agentbridge.registerCommand("spawn_entity", function(msg)
    assert(msg.entityId, "missing entityId")
    assert(msg.x and msg.y, "missing x/y")
    local ent = g.spawnEntity(msg.entityId, msg.x, msg.y)
    return {spawned = ent.id, type = ent.type}
end)

agentbridge.registerCommand("goto_scene", function(msg)
    assert(msg.scene, "missing scene")
    g.gotoScene(msg.scene)
    return {ok = true}
end)

agentbridge.registerCommand("keypressed", function(msg)
    assert(msg.key, "missing key")
    love.event.push("keypressed", msg.key, msg.key, false)
    return {ok = true}
end)

agentbridge.registerCommand("click", function(msg)
    assert(msg.x and msg.y, "missing x/y")
    local button = msg.button or 1
    love.event.push("mousepressed", msg.x, msg.y, button, false, 1)
    return {ok = true}
end)

---@param errorMsg string
function agentbridge.notifyCrash(errorMsg)
    if not thread or not thread:isRunning() then return end
    local ok, jsonLib = pcall(function() return json end)
    if not ok or not jsonLib then return end
    local ok2, payload = pcall(jsonLib.encode, {crash = tostring(errorMsg)})
    if ok2 then
        crashChan:push(payload)
    end
end

agentbridge.registerCommand("eval", function(msg)
    assert(msg.code, "missing code")
    local fn, err = loadstring(msg.code)
    if not fn then
        return {error = err}
    end
    local ok, result = pcall(fn)
    if not ok then
        return {error = tostring(result)}
    end
    if result == nil then
        return {ok = true}
    end
    return {result = result}
end)

return agentbridge
