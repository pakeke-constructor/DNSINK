BAD — diving straight into implementation:
```lua
function buildNavMesh(world)
    local cells = {}
    for x = 0, world.w - 1 do
        for y = 0, world.h - 1 do
            -- 80 lines of code that evolved without a plan
        end
    end
end
```

GOOD — pseudocode skeleton first, then fill in:
```lua
function buildNavMesh(world)
    -- 1. grid the world into walkable cells
    -- 2. flood-fill to find connected regions
    -- 3. merge adjacent cells into convex polygons
    -- 4. build adjacency graph between polygons
    -- 5. return { polygons, adjacency }
end
```
Then implement each step with another edit-file call.
The shape is locked in before any real code is written.
It's OKAY to do it in 2 passes; the human wants simplicity and correctness.