
--[[

modloading infrastructure:


Explanation for how this works:
- `src/umg/**` is "core engine" stuff
- everything in `src/dnsink/**` is gameplay stuff, treat it as a big list of "mods"

We need to do a few things:
- load the mods (by walking over directory)
- pass the mods by walking over directory

]]


---@class umg.modloading
local modloading = {}



---@param modlist table
function modloading.loadMods(modlist)
    --[[
    HACK: for now, we literally just load everything in `dnsink/`.
    and nothing else.
    ]]
    umg.requireFolder("src/dnsink")
end


local function makeEnvSandbox()
    local env = {}
    -- NOTE: this isn't sandboxed properly right now; and it isnt trying to be.
    -- its mainly for future.

    -- TODO: in future, do defensive copies. For now, just expose everything.
    env.math = math
    env.love = love
end


return modloading

