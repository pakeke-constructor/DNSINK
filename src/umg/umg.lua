

---@class umg
local umg = {}


local AutoAtlas, atlas
if CLIENT then
    AutoAtlas = require("lib.AutoAtlas.AutoAtlas")
    atlas = AutoAtlas(2048, 2048)
end

local nameToQuad = {}




local bgm = require("src.umg.client.sound.bgm")
local sfx = require("src.umg.client.sound.sfx")



local postLoadCallbacks = {}

function umg.postLoad(func)
    table.insert(postLoadCallbacks, func)
end

function umg._runPostLoad()
    for _, func in ipairs(postLoadCallbacks) do
        func()
    end
    postLoadCallbacks = {}
end







---@return love.Texture
function umg.getAtlas()
    return atlas:getTexture()
end

---@param imageName string
function umg.getImageQuad(imageName)
    local quad = nameToQuad[imageName]
    if not quad then
        error("Invalid quad: " .. tostring(imageName))
    end
    return quad
end


---@param imageName string
---@return number w
---@return number h
function umg.getImageSize(imageName)
    local quad = umg.getImageQuad(imageName)
    local _, _, w, h = quad:getViewport()
    return w, h
end

---@param imageName any
---@return boolean
function umg.isImage(imageName)
    return (nameToQuad[imageName] and true) or false
end

---@param imageName string|love.Quad
---@param x number
---@param y number
---@param r number?
---@param sx number?
---@param sy number?
---@param kx number?
---@param ky number?
function umg.drawImage(imageName, x, y, r, sx, sy, kx, ky)
    return umg.drawImageOffset(imageName, x, y, r, sx, sy, 0.5, 0.5, kx, ky)
end


---@param imageName string|love.Quad
---@param x number
---@param y number
---@param r number?
---@param sx number?
---@param sy number?
---@param ox number?
---@param oy number?
---@param kx number?
---@param ky number?
function umg.drawImageOffset(imageName, x, y, r, sx, sy, ox, oy, kx, ky)
    local quad
    if type(imageName) == "string" then
        quad = umg.getImageQuad(imageName)
    else
        if not (imageName.typeOf and imageName:typeOf("Quad")) then
            error("Expected quad, got: " .. type(imageName) .. " " .. tostring(imageName))
        end
        quad = imageName
    end
    local _,_,w,h = quad:getViewport()
    atlas:draw(quad, x, y, r, sx, sy, (ox or 0.5) * w, (oy or 0.5) * h, kx, ky)
end

---@param imageName string
---@param x number
---@param y number
---@param w number
---@param h number
---@param rot number?
function umg.drawImageContained(imageName, x, y, w, h, rot)
    local quad = umg.getImageQuad(imageName)
    local _,_,qw,qh = quad:getViewport()
    local scaleX = w / qw
    local scaleY = h / qh
    local scale = math.min(scaleX, scaleY)
    local scaledW = qw * scale
    local scaledH = qh * scale
    local centerX = x + (w - scaledW) / 2
    local centerY = y + (h - scaledH) / 2
    atlas:draw(quad, centerX + scaledW/2, centerY + scaledH/2, rot or 0, scale, scale, qw/2, qh/2)
end





---@param path string
---@param func fun(path: string)
function umg.walkDirectory(path, func)
    local info = love.filesystem.getInfo(path)
    if not info then return end

    if info.type == "file" then
        func(path)
    elseif info.type == "directory" then
        local dirItems = love.filesystem.getDirectoryItems(path)
        for _, pth in ipairs(dirItems) do
            umg.walkDirectory(path .. "/" .. pth, func)
        end
    end
end

local validImgExtensions = {
    [".png"] = true,
    [".jpg"] = true,
}

local function loadImage(path)
    local ext = path:sub(-4):lower()
    if validImgExtensions[ext] then
        local name = path:match("([^/]+)%.%w+$")
        local quad = atlas:add(love.image.newImageData(path))
        if nameToQuad[name] then
            error("Duplicate image: " .. name)
        end
        nameToQuad[name] = quad
        if richtext and richtext.defineImage then
            pcall(richtext.defineImage, name, atlas:getTexture(), quad)
        end
    end
end

function umg.loadImagesFrom(path)
    umg.walkDirectory(path, loadImage)
end


-- Define 1x1 white image
if CLIENT then
    -- Add padding around to prevent bleeding
    local id = love.image.newImageData(3, 3, "rgba8")
    id:mapPixel(function() return 1, 1, 1, 0 end) -- fill transparent white
    id:setPixel(1, 1, 1, 1, 1, 1) -- set middle pixel
    local q = assert(atlas:add(id))
    local x, y = q:getViewport()
    -- Now define it to be 1x1 instead of 3x3
    q:setViewport(x + 1, y + 1, 1, 1, umg.getAtlas():getDimensions())
    nameToQuad["1x1"] = q
end




-- g.playWorldSound
-- g.playUISound
do

----------
-- SFXs --
----------

---@param soundname string
---@param pitch number? (defaults to 1)
---@param volume number? (defaults to 1)
---@param pitchVar number? (pitch variance, default 0)
---@param volumeVar number? (volume variance, default 0)
function umg.playWorldSound(soundname, pitch, volume, pitchVar, volumeVar)
    if love.audio.getActiveSourceCount() > consts.MAX_PLAYING_SOURCES then
        return false
    end
    do
    return sfx.play(soundname, pitch, volume, pitchVar, volumeVar)
    end
    return false
end


---@param soundname string
---@param pitch number? (defaults to 1)
---@param volume number? (defaults to 1)
---@param pitchVar number? (pitch variance, default 0)
---@param volumeVar number? (volume variance, default 0)
function umg.playUISound(soundname, pitch, volume, pitchVar, volumeVar)
    return sfx.play(soundname, pitch, volume, pitchVar, volumeVar)
end


local validExtensions = {
    wav = true,
    mp3 = true,
    ogg = true,
    flac = true
}

---@param path string
local function loadSound(path)
    local pathrev = path:reverse()
    local ext = pathrev:sub(1, (pathrev:find(".", 1, true) or 1) - 1):reverse():lower()

    if validExtensions[ext] then
        local basename = pathrev:sub(1, pathrev:find("/", 1, true)-1):reverse()

        if #basename > 0 then
            local name = basename:sub(1, -#ext - 2)
            if name:sub(1,1) ~= "_" then
                sfx.defineSound(name, path)
            end
        end
    end
end

umg.walkDirectory("assets/sfx", loadSound)


----------
-- BGMs --
----------

-- Higher number means higher priority.
umg.BGMID = {
    TITLE = 999, -- Title and settings
    MAP = 1, -- Map scene
    AMBIENT = 2, -- Harvest scene / Upgrade scene
    CUSTOMIZATION = 3, -- Customization scene
    BOSS = 100, -- Boss theme
}


---@param path string
---@param prio integer
---@param isAmbient boolean?
local function registerBGMFromDirectories(path, prio, isAmbient)
    ---@type string[]
    local files = {}

    umg.walkDirectory(path, function(filename)
        local pathrev = filename:reverse()
        local ext = pathrev:sub(1, (pathrev:find(".", 1, true) or 1) - 1):reverse():lower()

        if validExtensions[ext] then
            local basename = pathrev:sub(1, pathrev:find("/", 1, true)-1):reverse()

            if #basename > 0 then
                local name = basename:sub(1, -#ext - 2)
                if name:sub(1,1) ~= "_" then
                    files[#files+1] = filename
                end
            end
        end
    end)

    if #files == 0 then
        error("no bgm files in "..path)
    end

    return bgm.register(prio, files, isAmbient)
end

-- We cannot use g.walkDirectory because we need all the files first then register
-- the BGM in one go using `bgm.register`.
--[[
registerBGMFromDirectories("assets/bgm/boss", g.BGMID.BOSS, false)
registerBGMFromDirectories("assets/bgm/customization", g.BGMID.CUSTOMIZATION, true)
registerBGMFromDirectories("assets/bgm/ambient", g.BGMID.AMBIENT, true)
registerBGMFromDirectories("assets/bgm/map", g.BGMID.MAP, true)
registerBGMFromDirectories("assets/bgm/ambient", g.BGMID.TITLE, true)
]]


---Request playing specific BGM ID
---@param id integer BGM ID. Use `g.BGMID` for the fixed constants.
function umg.requestBGM(id)
    return bgm.request(id)
end


end





local suffixes = {
    {1e12, "t"},
    {1e9,  "b"},
    {1e6,  "m"},
    {1e3,  "k"},
}

local bigCache = {}
local smolCache = {}
local fbCache = {}

local function getFallbackFonts(size)
    if not fbCache[size] then
        fbCache[size] = love.graphics.newFont("assets/fonts/unifont-17.0.03.otf", size, "mono", size / 16)
    end
    return fbCache[size]
end

---@param size number
function umg.getBigFont(size)
    assert(size % 16 == 0, "Size must by divisible by 16")
    if not bigCache[size] then
        local f = love.graphics.newFont("assets/fonts/Smart 9h.ttf", size, "mono", 1)
        f:setFallbacks(getFallbackFonts(size))
        bigCache[size] = f
    end
    return bigCache[size]
end

---@param size number
function umg.getSmallFont(size)
    assert(size % 16 == 0, "Size must by divisible by 16")
    if not smolCache[size] then
        local f = love.graphics.newFont("assets/fonts/Match 7h.ttf", size, "mono", 1)
        f:setFallbacks(getFallbackFonts(size))
        smolCache[size] = f
    end
    return smolCache[size]
end

---@param path string
function umg.requireFolder(path)
    local results = {}
    umg.walkDirectory(path:gsub("%.", "/"), function(pth)
        if pth:sub(-4, -1) == ".lua" then
            pth = pth:sub(1, -5)
            results[pth] = require(pth:gsub("%/", "."))
        end
    end)
    return results
end

---@param num number
function umg.formatNumber(num)
    local isNegative = num < 0
    num = math.abs(num)
    local prefix = (isNegative and "-" or "")

    if num < 1000 then
        if num == math.floor(num) then
            return prefix .. ("%d"):format(num)
        elseif num < 1 then
            return prefix .. ("%.2f"):format(num)
        elseif num < 3 then
            return prefix .. ("%.1f"):format(num)
        end
        return prefix .. tostring(math.floor(num))
    end

    for _, suffix in ipairs(suffixes) do
        if num >= suffix[1] then
            local scaled = num / suffix[1]
            local formatted
            if scaled >= 100 then
                formatted = string.format("%.0f", math.floor(scaled))
            elseif scaled >= 10 then
                formatted = string.format("%.14g", math.floor(scaled * 10) / 10)
            else
                formatted = string.format("%.14g", math.floor(scaled * 100) / 100)
            end
            return prefix .. formatted .. suffix[2]
        end
    end
    return prefix .. tostring(num)
end


function umg.screenToWorld(x, y)
    error("NOT YET IMPLEMENTED.")
    if scene.camera then
        return scene.camera:toWorld(x, y)
    end
    return x, y
end

function umg.worldToScreen(x, y)
    error("NOT YET IMPLEMENTED.")
    if scene.camera then
        return scene.camera:toScreen(x, y)
    end
    return x, y
end


function umg.getWorldTime()
    -- todo: add a proper counter here; allows for faster game-speed
    return love.timer.getTime()
end


--- @param particleName string
--- @param x number
--- @param y number
--- @param amount integer?
function umg.spawnParticle(particleName, x, y, amount)
    particles:spawnParticles(particleName, x, y, amount)
end


--- @param x number
--- @param y number
--- @param richtxt any
--- @param args textPopupService.args?
function umg.addWorldTextPopup(x, y, richtxt, args)
    local sx, sy = umg.worldToScreen(x, y)
    local t = ui.getUIScalingTransform()
    local ux, uy = t:inverseTransformPoint(sx, sy)
    textPopupService.addPopup(ux, uy, richtxt, args)
end

--- @param x number
--- @param y number
--- @param richtxt any
--- @param args textPopupService.args?
function umg.addUITextPopup(x, y, richtxt, args)
    textPopupService.addPopup(x, y, richtxt, args)
end




-- Event Bus / Question Bus
local reducers = require("src.modules.reducers")

local definedEvents = {}
local questions = {}

-- global handler caches: name -> {func1, func2, ...}
-- Rebuilt atomically each frame by g.pollHandlers.
local table_clear = require("table.clear")
local handlerCache = {} -- [eventOrQuestionName] -> {func, func, ...}

function umg.defineEvent(ev, isGlobalEvent)
    assert(not definedEvents[ev], "Event already defined: " .. ev)
    definedEvents[ev] = true
    handlerCache[ev] = {}
end

function umg.isEvent(ev)
    return definedEvents[ev] == true
end

function umg.defineQuestion(question, reducer, defaultValue)
    assert(not questions[question], "Question already defined: " .. question)
    questions[question] = {
        reducer = reducer,
        defaultValue = defaultValue,
    }
    handlerCache[question] = {}
end

function umg.getQuestionInfo(q)
    return questions[q]
end



local MAX_EVENT_CALLS_PER_FRAME = consts.MAX_EVENT_CALLS_PER_FRAME -- max 20 events of a single type per frame
local EVENT_COUNTS = {--[[
    [event] -> integer
]]}

local function _resetCallEventCounts()
    for k,_ in pairs(EVENT_COUNTS) do
        EVENT_COUNTS[k] = 0
    end
end

-- Fire an event. No return value.
-- Order: global handlers, then ent[ev], then ent.scope
function umg.call(ev, arg1, ...)
    local ct = EVENT_COUNTS[ev] or 0
    if ct >= MAX_EVENT_CALLS_PER_FRAME then
        return
    end
    ct = ct + 1; EVENT_COUNTS[ev] = ct

    -- 1. global handlers (via g.addHandler)
    local list = handlerCache[ev]
    for i = 1, #list do
        list[i](arg1, ...)
    end

    if type(arg1) ~= "table" then return end

    -- 2. direct entity handler
    if arg1[ev] then
        arg1[ev](arg1, ...)
    end

    -- 3. entity scope (perks, buffs, squad scope via parent chain)
    if arg1.scope then
        arg1.scope:call(ev, arg1, ...)
    end
end

-- Ask a question. Returns reduced value.
-- Order: global handlers, then ent[q], then ent.scope
function umg.ask(q, arg1, ...)
    local t = questions[q]
    if not t then
        error("Invalid question: " .. tostring(q))
    end
    local reducer, val = t.reducer, t.defaultValue

    -- 1. global handlers (via g.addHandler)
    local list = handlerCache[q]
    for i = 1, #list do
        val = reducer(val, list[i](arg1, ...))
    end

    if type(arg1) == "table" then
        -- 2. direct entity handler
        if arg1[q] then
            val = reducer(val, arg1[q](arg1, ...))
        end

        -- 3. entity scope (perks, buffs, squad scope via parent chain)
        if arg1.scope then
            val = reducer(val, arg1.scope:ask(q, arg1, ...))
        end
    end

    return val
end





return umg

