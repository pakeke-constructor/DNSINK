

---@class g
local g = {}


local AutoAtlas, atlas
if CLIENT then
    AutoAtlas = require("lib.AutoAtlas.AutoAtlas")
    atlas = AutoAtlas(2048, 2048)
end

local nameToQuad = {}




local bgm = require("src.umg.client.sound.bgm")
local sfx = require("src.umg.client.sound.sfx")



local postLoadCallbacks = {}

function g.postLoad(func)
    table.insert(postLoadCallbacks, func)
end

function g._runPostLoad()
    for _, func in ipairs(postLoadCallbacks) do
        func()
    end
    postLoadCallbacks = {}
end





-- TODO; this is incorrect palette, from kapathia.
local PALETTE = {
    {197, 48, 61},
    {89, 71, 29},
    {79, 45, 93},
    {54, 199, 222},
    {200, 82, 164},
    {29, 58, 81},
    {17, 18, 17},
    {99, 99, 99},
    {46, 68, 209},
    {166, 84, 27},
    {95, 57, 39},
    {29, 27, 14},
    {205, 133, 59},
    {8, 8, 8},
    {255, 255, 255},
    {54, 30, 25},
    {20, 14, 18},
    {39, 39, 71},
    {39, 55, 24},
    {188, 227, 233},
    {72, 72, 72},
    {0, 0, 0},
    {53, 125, 210},
    {35, 100, 73},
    {241, 241, 30},
    {124, 200, 42},
    {100, 106, 53},
    {77, 140, 33},
    {44, 44, 44},
    {140, 159, 169},
    {124, 34, 34},
    {225, 185, 123}
}
for i, c in ipairs(PALETTE) do
    PALETTE[i] = objects.Color.fromByteRGBA(c[1], c[2], c[3])
end

---Snap a color to the nearest palette entry.
---Uses 4th-power channel distance to deeply penalize large per-channel differences.
---Preserves the input alpha.
---@param r number|objects.Color red [0..1], or a Color/table
---@param gg number? green [0..1]
---@param b number? blue [0..1]
---@param a number? alpha [0..1] (default 1)
---@return objects.Color
function g.snapToPalette(r, gg, b, a)
    if type(r) == "table" then
        r, gg, b, a = r[1], r[2], r[3], r[4]
    end
    a = a or 1
    local best, bestDist = nil, math.huge
    for _, c in ipairs(PALETTE) do
        local rbar = (r + c.r) * 0.5
        local dr, dg, db = r - c.r, gg - c.g, b - c.b
        -- redmean: cheap perceptual RGB distance
        local dist = (2 + rbar)*dr*dr + 4*dg*dg + (3 - rbar)*db*db
        if dist < bestDist then
            bestDist = dist
            best = c
        end
    end
    assert(best, "?")
    return best:clone():setRGBA(nil, nil, nil, a)
end




---@return love.Texture
function g.getAtlas()
    return atlas:getTexture()
end

---@param imageName string
function g.getImageQuad(imageName)
    local quad = nameToQuad[imageName]
    if not quad then
        error("Invalid quad: " .. tostring(imageName))
    end
    return quad
end


---@param imageName string
---@return number w
---@return number h
function g.getImageSize(imageName)
    local quad = g.getImageQuad(imageName)
    local _, _, w, h = quad:getViewport()
    return w, h
end

---@param imageName any
---@return boolean
function g.isImage(imageName)
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
function g.drawImage(imageName, x, y, r, sx, sy, kx, ky)
    return g.drawImageOffset(imageName, x, y, r, sx, sy, 0.5, 0.5, kx, ky)
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
function g.drawImageOffset(imageName, x, y, r, sx, sy, ox, oy, kx, ky)
    local quad
    if type(imageName) == "string" then
        quad = g.getImageQuad(imageName)
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
function g.drawImageContained(imageName, x, y, w, h, rot)
    local quad = g.getImageQuad(imageName)
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
function g.walkDirectory(path, func)
    local info = love.filesystem.getInfo(path)
    if not info then return end

    if info.type == "file" then
        func(path)
    elseif info.type == "directory" then
        local dirItems = love.filesystem.getDirectoryItems(path)
        for _, pth in ipairs(dirItems) do
            g.walkDirectory(path .. "/" .. pth, func)
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

function g.loadImagesFrom(path)
    g.walkDirectory(path, loadImage)
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
    q:setViewport(x + 1, y + 1, 1, 1, g.getAtlas():getDimensions())
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
function g.playWorldSound(soundname, pitch, volume, pitchVar, volumeVar)
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
function g.playUISound(soundname, pitch, volume, pitchVar, volumeVar)
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

g.walkDirectory("assets/sfx", loadSound)


----------
-- BGMs --
----------

-- Higher number means higher priority.
g.BGMID = {
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

    g.walkDirectory(path, function(filename)
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
function g.requestBGM(id)
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
function g.getBigFont(size)
    assert(size % 16 == 0, "Size must by divisible by 16")
    if not bigCache[size] then
        local f = love.graphics.newFont("assets/fonts/Smart 9h.ttf", size, "mono", 1)
        f:setFallbacks(getFallbackFonts(size))
        bigCache[size] = f
    end
    return bigCache[size]
end

---@param size number
function g.getSmallFont(size)
    assert(size % 16 == 0, "Size must by divisible by 16")
    if not smolCache[size] then
        local f = love.graphics.newFont("assets/fonts/Match 7h.ttf", size, "mono", 1)
        f:setFallbacks(getFallbackFonts(size))
        smolCache[size] = f
    end
    return smolCache[size]
end

---@param path string
function g.requireFolder(path)
    local results = {}
    g.walkDirectory(path:gsub("%.", "/"), function(pth)
        if pth:sub(-4, -1) == ".lua" then
            pth = pth:sub(1, -5)
            results[pth] = require(pth:gsub("%/", "."))
        end
    end)
    return results
end

---@param num number
function g.formatNumber(num)
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


function g.screenToWorld(x, y)
    error("NOT YET IMPLEMENTED.")
    if scene.camera then
        return scene.camera:toWorld(x, y)
    end
    return x, y
end

function g.worldToScreen(x, y)
    error("NOT YET IMPLEMENTED.")
    if scene.camera then
        return scene.camera:toScreen(x, y)
    end
    return x, y
end


function g.getWorldTime()
    -- todo: add a proper counter here; allows for faster game-speed
    return love.timer.getTime()
end


--- @param particleName string
--- @param x number
--- @param y number
--- @param amount integer?
function g.spawnParticle(particleName, x, y, amount)
    particles:spawnParticles(particleName, x, y, amount)
end


--- @param x number
--- @param y number
--- @param richtxt any
--- @param args textPopupService.args?
function g.addWorldTextPopup(x, y, richtxt, args)
    local sx, sy = g.worldToScreen(x, y)
    local t = ui.getUIScalingTransform()
    local ux, uy = t:inverseTransformPoint(sx, sy)
    textPopupService.addPopup(ux, uy, richtxt, args)
end

--- @param x number
--- @param y number
--- @param richtxt any
--- @param args textPopupService.args?
function g.addUITextPopup(x, y, richtxt, args)
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

function g.defineEvent(ev, isGlobalEvent)
    assert(not definedEvents[ev], "Event already defined: " .. ev)
    definedEvents[ev] = true
    handlerCache[ev] = {}
end

function g.isEvent(ev)
    return definedEvents[ev] == true
end

function g.defineQuestion(question, reducer, defaultValue)
    assert(not questions[question], "Question already defined: " .. question)
    questions[question] = {
        reducer = reducer,
        defaultValue = defaultValue,
    }
    handlerCache[question] = {}
end

function g.getQuestionInfo(q)
    return questions[q]
end


-- Scopes: handler containers on entities for events/questions.
-- (Each scope is a collection of handlers; each Handler is a table containing events/question funcs)
-- Support parent chaining.
-- Squad entities share one scope (shared=true) to avoid duplication.
-- When a buff for a single ent is added, we create a "personal" scope for that entity, 
-- that "inherits" it's old shared scope.
---@class g.Scope: objects.Class
local Scope = objects.Class("g:Scope")

function Scope:init(parent)
    self.parent = parent or nil
    self.shared = false
    self.handlers = {}
    self.expiry = {} -- [handler] -> expire time
    self.tags = {} -- [tag] -> handler
    self.cache = {} -- [eventOrQuestionName] -> {func, func, ...}
    self.lastPrune = 0
end

function Scope:_rebuild()
    local cache = self.cache
    for k in pairs(cache) do
        table_clear(cache[k])
    end
    local now = love.timer.getTime()
    local expiry = self.expiry
    for _, handler in ipairs(self.handlers) do
        if not expiry[handler] or expiry[handler] > now then
            for key, func in pairs(handler) do
                if definedEvents[key] or questions[key] then
                    if not cache[key] then cache[key] = {} end
                    local list = cache[key]
                    list[#list + 1] = func
                end
            end
        end
    end
end

function Scope:_pruneIfNeeded()
    local now = love.timer.getTime()
    if now - self.lastPrune < 0.2 then return end
    self.lastPrune = now
    local dirty = false
    local expiry = self.expiry
    for i = #self.handlers, 1, -1 do
        local h = self.handlers[i]
        if expiry[h] and expiry[h] <= now then
            table.remove(self.handlers, i)
            expiry[h] = nil
            dirty = true
        end
    end
    if dirty then self:_rebuild() end
end

function Scope:addHandler(handler, duration, tag)
    for key in pairs(handler) do
        assert(definedEvents[key] or questions[key], "Unknown event/question: " .. tostring(key))
    end
    if tag then
        local old = self.tags[tag]
        if old then self:removeHandler(old) end
        self.tags[tag] = handler
    end
    if duration then
        self.expiry[handler] = love.timer.getTime() + duration
    end
    self.handlers[#self.handlers + 1] = handler
    self:_rebuild()
end

function Scope:removeHandler(handler)
    for i = #self.handlers, 1, -1 do
        if self.handlers[i] == handler then
            table.remove(self.handlers, i)
            self.expiry[handler] = nil
            self:_rebuild()
            return true
        end
    end
    return false
end

function Scope:call(event, ...)
    self:_pruneIfNeeded()
    local list = self.cache[event]
    if list then
        for i = 1, #list do
            list[i](...)
        end
    end
    if self.parent then
        self.parent:call(event, ...)
    end
end

function Scope:ask(question, ...)
    self:_pruneIfNeeded()
    local t = questions[question]
    if not t then
        error("Invalid question: " .. tostring(question))
    end
    local reducer, val = t.reducer, t.defaultValue
    local list = self.cache[question]
    if list then
        for i = 1, #list do
            val = reducer(val, list[i](...))
        end
    end
    if self.parent then
        val = reducer(val, self.parent:ask(question, ...))
    end
    return val
end


---@return g.Scope
function g.newScope(parent)
    return Scope(parent)
end



local MAX_EVENT_CALLS_PER_FRAME = consts.MAX_EVENT_CALLS_PER_FRAME -- max 20 events of a single type per frame
local EVENT_COUNTS = {--[[
    [event] -> integer
]]}

function _resetCallEventCounts()
    for k,_ in pairs(EVENT_COUNTS) do
        EVENT_COUNTS[k] = 0
    end
end

-- Fire an event. No return value.
-- Order: global handlers, then ent[ev], then ent.scope
function g.call(ev, arg1, ...)
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
function g.ask(q, arg1, ...)
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



---@class g.Rarity
---@field id string
---@field name string
---@field color objects.Color
---@field lightTextEffect string
---@field darkTextEffect string
---@field lightColor objects.Color
---@field darkColor objects.Color
local Rarity

local function darkenColor(col, val)
    local a = select(4, col:getRGBA())
    local h, s, v = col:getHSV()
    local nr, ng, nb = objects.Color.HSVtoRGB(h, s, v * val)
    return objects.Color(nr, ng, nb, a)
end

local function lightenColor(col, val)
    local a = select(4, col:getRGBA())
    local h, s, v = col:getHSV()
    local nr, ng, nb = objects.Color.HSVtoRGB(h, math.max(0, s - val), math.min(1, v + val))
    return objects.Color(nr, ng, nb, a)
end

---@param id string
---@param name string
---@param color objects.Color
---@return g.Rarity
local function newRarity(id, name, color)
    local lightTextEffect = id .. "_COLOR_LIGHT"
    local darkTextEffect = id .. "_COLOR_DARK"
    richtext.defineEffect(lightTextEffect, function (args, x, y, context, next)
        local r, gg, b, a = love.graphics.getColor()
        love.graphics.setColor(color.r or 1, color.g or 1, color.b or 1, (color.a or 1) * a)
        next(context.textOrDrawable, x, y)
        love.graphics.setColor(r, gg, b, a)
    end)

    richtext.defineEffect(darkTextEffect, function (args, x, y, context, next)
        local r, gg, b, a = love.graphics.getColor()
        love.graphics.setColor(color.r or 1, color.g or 1, color.b or 1, (color.a or 1) * a)
        next(context.textOrDrawable, x, y)
        love.graphics.setColor(r, gg, b, a)
    end)

    local rar = {
        id = id,
        lightTextEffect = "{" .. lightTextEffect .. "}",
        darkTextEffect = "{" .. darkTextEffect .. "}",
        name = loc(name, {}, {
            context = "Represents a rarity with roman numerals, as in `UNCOMMON (II)` or `RARE (III)`."
        }),
        color = color,
        darkColor = darkenColor(color, 0.45),
        lightColor = lightenColor(color, 0.3)
    }

    return rar
end


---@class _g._rarities
g.RARITIES = {
    COMMON = newRarity("COMMON", "COMMON (I)", objects.Color.fromByteRGBA(99,99,99)),
    UNCOMMON = newRarity("UNCOMMON", "UNCOMMON (II)", objects.Color.fromByteRGBA(43,105,180)),
    RARE = newRarity("RARE", "RARE (III)", objects.Color.fromByteRGBA(160,62,144)),
    LEGENDARY = newRarity("LEGENDARY", "LEGENDARY (IV)", objects.Color.fromByteRGBA(150,100,25)),

    UNIQUE = newRarity("UNIQUE", "UNIQUE", objects.Color.GRAY),
}

g.COLORS = {
    --[[
    
    todo: figure out what do put here:
    
    ]]
    UPGRADE = objects.Color("FFF7D172"),

    DAMAGE = objects.Color("ffd53341"),
    HEAL = objects.Color("ffc852a4"),

    BURN = objects.Color("FFE17313"),
    POISON = objects.Color("FF530C63"),
    HEALTH = objects.Color("FF397634"),
    ATTACK = objects.Color("FFA2741E"),
    MAP_EDGE = objects.Color(0.16, 0.28, 0.18, 0.65),
    MAP_EDGE_HIGHLIGHT = objects.Color("67396938"),

    MAP_GROUND_COLOR = objects.Color("FF0B0C0B"),
    BATTLE_GROUND_COLOR = objects.Color("FF2C2929"),

    GOLD = objects.Color("FFD8B01F"),
    XP = objects.Color("FF2BC66E"),
    DARK_UI = objects.Color("FF0c0c19"),
}

for k,v in pairs(g.COLORS) do
    richtext.defineEffect(k .. "_COLOR", function (args, x, y, context, next)
        local r, gg, b, a = love.graphics.getColor()
        love.graphics.setColor(v)
        next(context.textOrDrawable, x, y)
        love.graphics.setColor(r, gg, b, a)
    end)
end





return g

