BAD — storing random visual offsets per-entity:
```lua
function Entity:init()
    self.wobble_offset = math.random() * math.pi * 2
end
```

GOOD — derive from a deterministic hash of identity:
```lua
function Entity:draw()
    local h = self.x * 287333 + self.y * 173291
    local wobble = (h % 1000) / 1000 * math.pi * 2
end
```
Why: zero stored state, fully deterministic, survives serialization, no init required. Works for anything that has a stable identity (position, id, index, etc).