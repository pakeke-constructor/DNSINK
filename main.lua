
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



local loadTime = true
function _G.isLoadTime()
    return loadTime
end


_G.utf8 = require("utf8")
_G.json = require("lib.json")


---@type g.consts
_G.consts = require("src.umg.consts")

_G.settings = require("src.umg.settings")
_G.log = require("src.modules.log")
_G.typecheck = require("src.modules.typecheck.typecheck")
_G.objects = require("src.modules.objects.objects")



--[[
this table serves as a description for what launchArgs SHOULD LOOK LIKE.
(NOT ACTUAL VALUES!!!)
]]
local LAUNCH_ARGS = {
    mode = "server" or "client" or "menu",
    -- modlist = {"mod", "list", "goes", "here"},

    localClient = true or false, -- <<<< override ipport with localhost:port
    clientIpPort = "ip:port" or nil,
    -- if this ^^^^ is given; client is connecting to online server

    localServer = true or false,
    -- if this ^^^ is true, server will open a local ENet connection
    serverIpPort = "ip:port" or nil, -- 
    -- if this ^^^^ is given; server is hosting an online server
}



---@param args any
---@return {mode:"server"|"client"|"menu", modlist:string[], localClient?:boolean, clientIpPort:string, localServer?:boolean, serverIpPort:string}
local function parseLaunchArgs(args)
    if not args then
        log.error("Game MUST be booted with launchJson args.")
        args = {'{"mode":"menu"}'}
    end
    local jsonStr = {}
    for i, arg in ipairs(args) do
        table.insert(jsonStr, arg)
    end

    local launchArgs = json.decode(table.concat(jsonStr))

    for k, v in pairs(LAUNCH_ARGS) do
        if not launchArgs[k] then
            -- if a defined key doesn't exist; set it to false.
            -- This way we avoid __index errors
            launchArgs[k] = false
        end
    end

    -- defensive __index, ensures we dont access undefined args
    setmetatable(launchArgs, {
        __index = function(_t, k)
            error("Undefined launch-arg: " .. tostring(k))
        end
    })
    return launchArgs
end




local function load(args)
    rawset(_G, "launchArgs", parseLaunchArgs(args))

    rawset(_G, "CLIENT", false)
    rawset(_G, "MENU", false)
    rawset(_G, "SERVER", false)

    if launchArgs.mode == "server" then
        rawset(_G, "SERVER", true)

    elseif launchArgs.mode == "menu" then
        rawset(_G, "MENU", true)
        love.window = require("love.window")
        love.window.setMode(800, 600)

    else assert(launchArgs.mode == "client")
        assert(launchArgs.localClient or launchArgs.clientIpPort)
        rawset(_G, "CLIENT", true)
        love.window = require("love.window")
        love.window.setMode(800, 600)
    end

   --=============================

    local ffi = require("ffi")
    assert(ffi.abi("le"), "Bad endianness. This game will not run on your computer.")

    -- local modloader = require("src.shared.modloader.modloader")
    -- modloader.loadMods({"oli:test_mod_2"})

    print((SERVER and "Server booted") or "Client loaded")
end





-- local subpixel = require("src.modules.subpixel.init")





function love.load(args)
    load(args)

    if CLIENT then
        _G.lg = love.graphics
    end

    _G.helper = require("src.modules.helper.helper")
    _G.richtext = require("src.modules.richtext.exports")
    _G.localization = require("src.modules.localization")
    _G.gsman = require("src.modules.gsman.gsman")
    _G.loc = _G.localization.localize
    _G.interp = _G.localization.newInterpolator
    _G.iml = require("lib.iml.iml")
    _G.Kirigami = require("lib.kirigami")
    _G.ui = require("src.umg.client.ui.ui")

    _G.devcmd = require("src.umg.devcmd")

    _G.analytics = require("src.modules.analytics.analytics")
    if CLIENT then
        _G.vignette = require("src.modules.vignette.vignette")
    end

    _G.g = require("src.umg.g")

    if SERVER then
        require("src.umg.server.server_main")
    elseif CLIENT then
        require("src.umg.client.client_main")
    else
        require("src.umg.client.client_main")
    end

    loadTime = false
end

