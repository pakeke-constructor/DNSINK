---
name: ui
description: Use when creating UI, layouts, panels, input handling, hover tooltips, or scaling
---

## IML (Immediate-Mode Input Layer)

Global `iml`. `iml.beginFrame()`/`iml.endFrame()` called each frame in `love.draw`.

### Panels

`iml.panel(x,y,w,h, key?)` registers a hit-test region (draws nothing). Last-declared panel under mouse wins hover. Key defaults to `hash(x,y,w,h)`; provide explicit key for stable identity (drags, duplicate rects).

Most query functions call `iml.panel` internally, so only call it directly to block click propagation.

### Queries

All take `(x,y,w,h, [button], [key])`. `button` defaults to 1. Must be called within beginFrame/endFrame.

- `iml.isHovered(x,y,w,h, key?)` — true while hovered and topmost.
- `iml.wasJustHovered(x,y,w,h, key?)` — true single frame hover started.
- `iml.isClicked(x,y,w,h, btn?, key?)` — true each frame mouse held (click, not drag).
- `iml.wasJustClicked(x,y,w,h, btn?, key?)` — true once on release if click. **Main "button pressed" check.**
- `iml.wasJustPressed(x,y,w,h, btn?, key?)` — true once on mouse-down.
- `iml.wasJustReleased(x,y,w,h, btn?, key?)` — true once on release (click or drag).
- `iml.isSelected(x,y,w,h, key?)` — true if last left-clicked panel. For text focus.

### Drags

`iml.consumeDrag(key, x,y,w,h, button)` — returns `iml.Drag?`; non-nil = being dragged. Key must be explicit non-number.

### Transforms

IML tracks a transform stack mapping screen-space mouse to local coords. Critical for UI scaling.
`iml.pushTransform(t)`, `iml.popTransform()`, `iml.resetTransforms()`, `iml.getTransformedPointer()`.

### Text Input

`iml.consumeText()` — returns and consumes text typed this frame, or nil.


## Kirigami (Layout Regions)

Global `Kirigami(x,y,w,h)` creates a `kirigami.Region` for splitting/padding layouts.

### Splitting

```lua
local top, bot = region:splitVertical(1, 3)           -- by ratio (25%/75%)
local header, body = region:splitVerticalExact(40, 0)  -- by px (0 = remaining)
local cells = region:grid(3, 2)                        -- 3 cols x 2 rows
```
Also: `splitHorizontal(...)`, `splitHorizontalExact(...)`, `rows(n)`, `columns(n)`.

### Padding

```lua
region:padUnit(10)              -- 10px all sides
region:padUnit(left, top, bot, right)
region:padRatio(0.1)            -- 10% all sides
```

### Positioning & Sizing

`center(other)`, `centerX(other)`, `centerY(other)`, `moveUnit(dx,dy)`, `moveRatio(rx,ry)`.
`shrinkTo(w,h)`, `shrinkToAspectRatio(rw,rh)`, `scale(s)`, `scaleToFit(w,h)`.
`attachToTopOf(r)`, `attachToBottomOf(r)`, `attachToLeftOf(r)`, `attachToRightOf(r)`.
`intersection(other)`, `union(other)`, `clampInside(other)`.

### Accessors

`region:get()` → x,y,w,h. `region:getCenter()` → cx,cy. `region:size()` → w,h. `region:exists()`. `region:containsCoords(px,py)`.


## UI Scaling

Auto-scales UI to `UI_HEIGHT = 360` virtual pixels based on window height.

All UI drawing must be between `ui.startUI()` / `ui.endUI()` — pushes scale transform to both Love2D graphics and iml.

```lua
ui.startUI()
    local screen = ui.getScreenRegion()  -- root kirigami region (safe area, virtual coords)
    -- all UI drawing here
ui.endUI()
```

Key functions:
- `ui.getScreenRegion()` — root layout region. Use this for all layout.
- `ui.getFullScreenRegion()` — ignores safe area.
- `ui.getScaledUIDimensions()` — virtual (w, h), always ~360 tall.
- `ui.getMouse()` — mouse in virtual coords. Use instead of `love.mouse.getPosition()`.
- `ui.getUIScaling()` — scale factor.
- `ui.assertUIStarted()` — guard for widget functions.


## Drawing Helpers

### 9-Slice Panels

```lua
ui.drawPanel(x, y, w, h)            -- light border
ui.drawDarkPanel(x, y, w, h)        -- dark border
ui.drawSingleColorPanel(x, y, w, h) -- flat, tinted by current setColor
```

### Gradients

```lua
helper.gradientRect("vertical", col1, col2, x, y, w, h)
helper.gradientRect("horizontal", col1, col2, x, y, w, h)
helper.gradientOutlineRect(dir, col1, col2, x, y, w, h, lineWidth?)
helper.gradientRectStencil(dir, col1, col2, x, y, w, h, drawFunc) -- masked gradient
```

### Images

- `g.drawImage(name, x, y)` — centered, no scaling. Prefer for pixel-art icons.
- `g.drawImageContained(name, x, y, w, h)` — scales to fit, preserves aspect.
- Avoid scaling images when possible.


## ui.Box

`ui.Box(args, drawBg?)` — vertical stack layout for text + custom elements.

```lua
local box = ui.Box({maxWidth = 200, padding = 8, spacing = 4}, function(x, y, w, h)
    helper.gradientRect("vertical", col1, col2, x, y, w, h)
    ui.drawPanel(x, y, w, h)
end)
box:addText("Some {c r=1 g=0 b=0}rich text", font)
box:addSpacing(4)
box:add({
    getHeight = function(innerW) return 20 end,
    draw = function(x, y, w, h) ... end,
})
local totalW, totalH = box:render(x, y)  -- or box:measure() for size only
```

Used heavily for cards (squad_card, blessing_card) and hover tooltips.


## ui.HBox
`ui.HBox(args, drawBg?)` — horizontal layout for text + custom elements.

```lua
local hbox = ui.HBox({padding = 4, spacing = 6}, function(x, y, w, h)
    ui.drawPanel(x, y, w, h)
end)
hbox:addText("Label", font)
hbox:addSpacing(8)
hbox:add({
    getWidth = function() return 20 end,
    getHeight = function() return 20 end,  -- optional
    draw = function(x, y, w, h) ... end,
})
local totalW, totalH = hbox:render(x, y)  -- or hbox:measure() for size only
```

Same as `ui.Box` but left-to-right. Height determined by tallest entry.


## Built-in Widgets

```lua
if ui.DefaultButton(richText, region) then ... end         -- standard button
if ui.Button(richText, col1, col2, region) then ... end    -- colored button
if ui.CustomButton(drawFunc, col1, col2, region) then ... end
local seg = ui.Slider(key, "horizontal", color, cur, max, size, region)
checked = ui.Checkbox(color, region, checked)
local tb = ui.newTextBox(); tb:draw(region)  -- tb.txt, tb.isFocused
```

Buttons handle hover/click sounds, gradient fill, iml registration. Must be inside startUI/endUI.


## hoverService

`require("src.hud.hoverService")`. One tooltip at a time, stateless (disappears if not requested).

```lua
if iml.isHovered(x, y, w, h, myKey) then
    hoverService.requestHover(function(box, fonts)
        box:addText("{c r=0.9 g=0.85 b=0.7}Title", fonts.title)
        box:addText("{c r=0.7 g=0.7 b=0.75}Description.", fonts.body)
    end)
end
```

`builder` receives a `ui.Box` (maxWidth=180) and `{title=bigFont16, body=smallFont16}`. Optional `col1, col2` gradient args. Auto-positions near mouse, clamps to screen. `hoverService.draw()` called by HUD automatically.


## Conventions

- `hud.lua` contains a lot of the UI - Look there if you are unsure.
- Always use richtext for rendering text. Ensure text is localized with `loc()`.
- Avoid scaling images. Use `g.drawImage` for native-size icons.
- Use `ui.drawPanel` / `ui.drawDarkPanel` for borders (9-slice). Don't roll your own.
- Use `helper.gradientRect` for background fills and visual polish.
- Use `ui.Box` for anything that stacks text/content vertically (tooltips, cards, lists).
- Use `hoverService` for mouse-hover explanations. Don't roll your own tooltip system.
- All UI code must be inside `ui.startUI()` / `ui.endUI()`.
- Use `ui.getScreenRegion()` as the root kirigami region for layout.
- Use `ui.getMouse()` (not `love.mouse.getPosition()`) for mouse coords in UI space.

