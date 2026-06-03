Task: "Smoothly animate a value from A to B, and support changing the target mid-animation"

BAD — model builds an animation system:
```lua
function anim_new(start, target, duration)
    -- return {start, target, duration, elapsed}
end
function anim_retarget(anim, new_target)
    -- snapshot current value as new start, reset elapsed
end
function anim_update(anim, dt)
    -- increment elapsed, clamp, interpolate start→target
end
```

GOOD — model stops to think first:
```
What does "smoothly animate toward a target" actually mean?
- A value should move toward a goal over time.
- If the goal changes, it should redirect smoothly.
- WAIT — I'm framing this as an event (start→end).
  But it's actually a continuous process: "chase the target."
  Exponential approach does that in one line.
```
Then implements:
```lua
e.x = e.x + (e.target_x - e.x) * 10 * dt
```
Change `target_x` anytime. The value always chases smoothly. No start value, no elapsed time, no retarget logic. The reframe — from "animation event" to "chase target" — eliminated the entire system.