BAD — building a config object to describe behavior:
```lua
handler = EventHandler:new({
    event = "on_click",
    target = button,
    action = "toggle_visibility",
    args = {panel},
})
handler:register()
```

GOOD — just pass a function:
```lua
on("click", button, function()
    panel.visible = not panel.visible
end)
```
Why: no config tables, no string lookups, no args gymnastics. The caller passes the behavior directly, which is a lot more flexible. The function IS the config.

Other examples where this could be useful include fields on objects / entity definitions.
```lua
defineEntity(name {
    getDamageMultiplier = func -- func returns 0 when entity is in "defensive mode".
    -- Much simpler than writing a complex system for damage propagation.
})
```