--[[

PixelCanvas class:
Essentially is a big canvas that the user can render to to make their stuff pixelart.
It achieves this by creating a smaller canvas that is to be rendered to, and then
upscaling that canvas to fit the entire screen.

## USAGE:


function love.draw()
    pc = PixelCanvas.new(screenWidth, screenHeight)

    transform = camera:getTransform() or love.math.newTransform()

    pc:start(transform) -- applies transform, sets canvas.

    renderStuff(...)
    love.graphics.circle("fill",x,y, 5)

    pc:finish() -- renders canvas, pops transform, etc.
end


-- if start is called twice in a row (no finish) raise error.



## SPECIAL DETAILS:
PixelCanvas sounds simple, but there's actually a bit more going on.
Notably, pixelCanvas objects are meant to be the size of the screen.
they won't neccessarily render to the entire canvas; only renders to a portion.

then, when ps:finish() is called, the canvas portion is scaled such that it FITS the size of the screen.

The PS objects will also scale their pixels to be the size of scale of THE TRANSFORM.

]]

local lg = love.graphics


---@class PixelCanvas
---@field screenW number
---@field screenH number
---@field canvas love.Texture|nil
---@field active boolean
---@field scale number
local PixelCanvas = {}
PixelCanvas.__index = PixelCanvas

---@param screenW number
---@param screenH number
---@return PixelCanvas
function PixelCanvas.new(screenW, screenH)
    local self = setmetatable({
        screenW = screenW,
        screenH = screenH,
        canvas = lg.newCanvas(screenW, screenH),
        active = false,
        scale = 1,
    }, PixelCanvas)
    self.canvas:setFilter("nearest", "nearest")
    return self
end

---@param w number
---@param h number
function PixelCanvas:resize(w, h)
    self.screenW = w
    self.screenH = h
    if self.canvas and w <= self.canvas:getWidth() and h <= self.canvas:getHeight() then
        return
    end
    self.canvas = lg.newCanvas(w, h)
    self.canvas:setFilter("nearest", "nearest")
end

--- Extract uniform scale from a Love2D Transform
---@param transform love.Transform
local function getTransformScale(transform)
    local m11, m12, _, _, m21, m22 = transform:getMatrix()
    return math.sqrt(m11 * m11 + m21 * m21)
end

---@param transform love.Transform
function PixelCanvas:start(transform)
    assert(not self.active, "PixelCanvas:start called twice without finish")
    self.active = true

    local scale = getTransformScale(transform)
    -- round to nearest integer for clean pixels (min 1)
    local pixelScale = math.max(1, math.floor(scale + 0.5))
    self.scale = pixelScale

    lg.push("all")
    lg.setCanvas(self.canvas)
    lg.clear(0, 0, 0, 0)

    -- apply transform scaled down by pixelScale so content maps to smaller canvas
    local rescaled = love.math.newTransform()
    rescaled:scale(1 / pixelScale, 1 / pixelScale)
    rescaled:apply(transform)
    lg.replaceTransform(rescaled)
end

function PixelCanvas:finish()
    assert(self.active, "PixelCanvas:finish called without start")
    self.active = false

    lg.pop()

    -- draw canvas scaled up to fill screen
    lg.push()
    lg.origin()
    lg.setColor(1, 1, 1, 1)
    lg.draw(self.canvas, 0, 0, 0, self.scale, self.scale)
    lg.pop()
end

return PixelCanvas
