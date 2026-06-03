
BAD — string allocation and table allocation every frame:
```lua
function Obj:update()
    assert(bool, "Error in parsing " .. self.txt)
    callFunc("foo", {constant = 3})
end
```

GOOD — avoid per-frame allocations in tight loops if it's easy:
```lua
local ARGS = {constant = 3}

function Obj:update()
    if not bool then
        error("Error in parsing " .. self.txt)
    end
    callFunc("foo", ARGS)
end
```
