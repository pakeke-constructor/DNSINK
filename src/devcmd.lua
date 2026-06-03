
local devcmd = {}

local cmdBuf = ""
local active = false
local LOG = {}
local logTime = 0
local FADE_AFTER = 3
local FADE_DUR = 1

local function addLog(msg)
    LOG[#LOG + 1] = msg
    if #LOG > 10 then table.remove(LOG, 1) end
    logTime = love.timer.getTime()
end

local COMMANDS = {}

COMMANDS.help = function()
    addLog("todo, list commands here")
end


local function execCmd(line)
    local parts = {}
    for w in line:gmatch("%S+") do parts[#parts + 1] = w end
    local name = parts[1]
    if not name then return end
    local cmd = COMMANDS[name]
    if not cmd then return addLog("unknown command: " .. name) end
    table.remove(parts, 1)
    local ok, err = pcall(cmd, parts)
    if not ok then addLog("ERROR: " .. tostring(err)) end
end

function devcmd.keypressed(key)
    if not consts.DEV_MODE then return end
    if key == "/" and not active then
        active = true
        cmdBuf = ""
        return true
    end
    if not active then return false end
    if key == "escape" then
        active = false
        cmdBuf = ""
        return true
    end
    if key == "return" then
        active = false
        execCmd(cmdBuf)
        cmdBuf = ""
        return true
    end
    if key == "backspace" then
        cmdBuf = cmdBuf:sub(1, -2)
        return true
    end
    return true
end

function devcmd.textinput(text)
    if not active then return false end
    if text == "/" then return true end
    cmdBuf = cmdBuf .. text
    return true
end

function devcmd.draw()
    if not consts.DEV_MODE then return end
    love.graphics.push()
    love.graphics.scale(2, 2)
    local font = love.graphics.getFont()
    local W = love.graphics.getWidth() / 2
    local y = love.graphics.getHeight() / 2 - 24
    if active then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, y, W, 24)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("/" .. cmdBuf .. "_", 4, y + 4)
    end
    -- draw log with fade
    local elapsed = love.timer.getTime() - logTime
    local alpha = 1
    if not active and elapsed > FADE_AFTER then
        alpha = 1 - math.min((elapsed - FADE_AFTER) / FADE_DUR, 1)
    end
    if alpha > 0 and #LOG > 0 then
        local logY = y - #LOG * 18
        for i, msg in ipairs(LOG) do
            love.graphics.setColor(0, 0, 0, 0.5 * alpha)
            love.graphics.rectangle("fill", 0, logY + (i - 1) * 18, font:getWidth(msg) + 8, 18)
            love.graphics.setColor(1, 1, 0.5, alpha)
            love.graphics.print(msg, 4, logY + (i - 1) * 18)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

return devcmd
