

## planning: frame management.


-- one world per game. this is a HARD limitation.
_World {
    entities = BufferedSet()
    grids = {...}
    -- world is an internal object; API surface doesn't see it, doesn't know about it
}



Entity {
    ent:frame() -> ReferenceFrame
    ent:supportingGrid() -> GridEnt

    Grid {
        -- if this is defined, ent represents a `grid`
        gridData: ...
    }
}


-- abstract representation of a reference-frame (useful for stuff like vehicles)
-- (these don't really do anything on their own)
RefFrame {
    x, y: number, number
    vx, vy = 0,
    rot: 0,
    avel: 0,

    parent?: RefFrame or nil
}


=============================


Best idea:
singular ECS, multiple frames.

How is physics done? How is it managed?
- answer: Via a singular system, that knows about reference-frames.
- for dnsink, there should be ONE physics-world. Do NOT overcomplicate with multiple.
- for dnsink, ALL grid-changes should be synced. Do NOT overcomplicate with chunking.

How is syncing done?
- All grids, synced to ALL clients. simple, effective
- All entity deltas, synced to ALL clients; simple.

Where are systems stored? How is stuff managed?
- Systems stored inside `dnsink/**`.
- OVERRIDES:
- `physicsOverride` system; ONE system can control velocity/physics/movement
- lobby system: ONE system can control player-spawning?


What about space-game?
- Worry about that later. once we have more experience.
- The goal for now -> get something working with the LEAST amount of code possible.



## Action-items:
- ~~Set proper love.conf flags (server has no window/input)~~
- ~~set up logging~~
- ~~set up mode-switching in main.lua (menu, client, server)~~
- ~~Set up packet schemas, packet-sending (+serverside validation)~~
- ~~Create Connection API: Get a luaEnet socket connection working~~
- Set up file loading structure for DNSINK
- umg.register infrastructure
- umg.defineEntityType infra
- umg.clientToServerRPC, umg.serverToClientRPC
- create ECS and replicated entity infra (DON'T replicate ent-data, just repl ids)
- setup grids and replicate grid-changes
- setup `ent:frame()` func, setup `ent:supportingGrid()` func
- clientside Input / Control system (KEEP IT SIMPLE; for now just expose love-events)
- [DEBUG-INFRA: allow placement of blocks, placement of entities]
- spawn players
- lerping for x,y / vx,vy syncing
- [[[ BASIC SYSTEMS COMPLETED ]]]

## For future:
- set up API creator w/ setfenv; in future, this does proper sandboxing
- set up "mod loading" (load systems in `dnsink`)


NORTH STAR CONSIDERATION:
How would DNSINK be "converted" to space-game if needed?
- Strip out `dnsink` and `dnsink_menu`. (Replace with `spacegame`)
- We would need to ensure that the core systems fit together nicely.

