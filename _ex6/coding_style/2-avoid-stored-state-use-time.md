BAD — storing a timer variable, updating it, checking it:
```lua
function Obj:init()
    self.flash_timer = 0
end
function Obj:hit()
    self.flash_timer = 0.2
end
function Obj:update(dt)
    -- decrement timer
end
function Obj:draw()
    -- check timer > 0, set color
end
```

GOOD — derive it from the moment it happened:
```lua
function Obj:hit()
    self.hit_time = love.timer.getTime()
end
function Obj:draw()
    -- check (now - hit_time) < 0.2, set color
end
```
Why: no update step, no timer state to manage, no desync bugs. One field instead of one field + update logic.