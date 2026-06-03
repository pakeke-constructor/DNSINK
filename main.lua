
local love = require("love")
--io.stdout:setvbuf("line")

_G.lg = love.graphics
_G.table.clear = require("table.clear")


lg.setDefaultFilter("nearest", "nearest")
lg.setLineStyle("rough")



-- relative-require
do
local stack = {""}
local oldRequire = require
local function stackRequire(path)
    table.insert(stack, path)
    local result = oldRequire(path)
    table.remove(stack)
    return result
end


--[[
we *MUST* overwrite `require` here,
or else the stack will become malformed.
]]
function _G.require(path)
    if (path:sub(1,1) == ".") then
        -- its a relative-require!
        local lastPath = stack[#stack]
        if lastPath:find("%.") then -- then its a valid path1
            local subpath = lastPath:gsub('%.[^%.]+$', '')
            return stackRequire(subpath .. path)
        else
            -- we are in root-folder; remove the dot and require
            return stackRequire(path:sub(2))
        end
    else
        return stackRequire(path)
    end
end

end



local _loadtime = true
function _G.isLoadTime()
    return _loadtime
end



_G.lg = love.graphics

_G.utf8 = require("utf8")
_G.json = require("lib.json")


---@type g.consts
_G.consts = require("src.umg.consts")

_G.settings = require("src.umg.settings")
_G.log = require("src.umg.modules.log")
_G.typecheck = require("src.umg.modules.typecheck.typecheck")
_G.objects = require("src.umg.modules.objects.objects")
_G.helper = require("src.umg.modules.helper.helper")
_G.richtext = require("src.umg.modules.richtext.exports")
_G.localization = require("src.umg.modules.localization")
_G.gsman = require("src.umg.modules.gsman.gsman")
_G.loc = _G.localization.localize
_G.interp = _G.localization.newInterpolator
_G.iml = require("lib.iml.iml")
_G.Kirigami = require("lib.kirigami")
_G.ui = require("src.umg.client.ui.ui")

_G.devcmd = require("src.umg.devcmd")

_G.analytics = require("src.umg.modules.analytics.analytics")
_G.vignette = require("src.umg.modules.vignette.vignette")


_G.textPopupService = require("src.umg.modules.textPopupService")


_G.g = require("src.umg.g")


if consts.TEST then
    require("src.ecs.ecs_tests")
end

local subpixel = require("src.umg.modules.subpixel.init")



local perSecondUpdateTimer = 0
local secondCount = 0


local function assertValid()
    for _, id in ipairs(g.getEntityList()) do
        local def = g.getEntityDef(id)
        if def.image ~= nil then
            assert(g.isImage(def.image), "Invalid entity image: " .. tostring(def.image) .. " for " .. tostring(id))
        end
    end
end



function love.load()
    assert(love.filesystem.createDirectory("saves"))
    vignette.setStrength(0.8)
    analytics.init(nil)
    if consts.DEV_MODE then
        love.keyboard.setTextInput(true)
    end
    g.loadImagesFrom("assets")
    g.loadImagesFrom("src/content")
    g.requireFolder("src/entities")
    g.requireFolder("src/content")
    assertValid()
    love.window.setFullscreen(settings.isFullscreen())
    g._runPostLoad()
    _loadtime = false
end


function love.update(dt)
    g.pollHandlers()
    iml.setPointer(love.mouse.getPosition())
    textPopupService.update(dt)

    perSecondUpdateTimer = perSecondUpdateTimer + dt
    while perSecondUpdateTimer >= 1 do
        perSecondUpdateTimer = perSecondUpdateTimer - 1
        secondCount = secondCount + 1
        
        g.call("perSecondUpdate", secondCount)
    end
end

function love.quit()
    settings.save()
    g.saveAndInvalidateRun()
end

function love.draw()
    if settings.isFullscreen() ~= love.window.getFullscreen() then
        love.window.setFullscreen(settings.isFullscreen(), "desktop")
    end
    lg.setShader(subpixel.shader)
    local CLIENT = true
    if CLIENT then
        iml.beginFrame()
        iml.endFrame()
        textPopupService.draw(ui.getUIScalingTransform())
        vignette.draw()
    end
    devcmd.draw()
    if CLIENT and consts.DEV_MODE then
        local fps = love.timer.getFPS()
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.push()
        love.graphics.scale(2)
        love.graphics.printf("  FPS: " .. fps, 0, 2, love.graphics.getWidth() / 2 - 4, "right")
        love.graphics.pop()
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function love.mousepressed(mx, my, button, istouch, presses)
    iml.mousepressed(mx, my, button, istouch, presses)
end

function love.mousereleased(mx, my, button, istouch)
    iml.mousereleased(mx, my, button, istouch)
end

function love.mousemoved(mx, my, dx, dy, istouch)
end

function love.keypressed(key, scancode, isrep)
    if devcmd.keypressed(key) then return end
    if scancode == "[" then
        consts.SHOW_DEV_STUFF = consts.DEV_MODE and (not consts.SHOW_DEV_STUFF)
    elseif scancode == "return" and love.keyboard.isDown("lalt", "ralt") then
        settings.setFullscreen(not settings.isFullscreen())
    end
    iml.keypressed(key, scancode, isrep)
end

function love.keyreleased(key, scancode)
    iml.keyreleased(key, scancode)
end

function love.textinput(text)
    if devcmd.textinput(text) then return end
    iml.textinput(text)
end

function love.wheelmoved(dx, dy)
    iml.wheelmoved(dx, dy)
end

function love.resize(w, h)
    vignette.resize()
end

function love.directorydropped(fullpath)
end

function love.filedropped(file)
end
