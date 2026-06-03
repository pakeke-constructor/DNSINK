

# DO-NOT-SINK:
"DO NOT SINK", or "DNSINK" is a pirate-themed multiplayer party-game built in love2d, with lua.
(Think like terraria-sandbox-style, but you are on a self-contained pirate-ship with friends.)

The game is built using an engine called "UMG".
"umg" is a specialized, opinionated multiplayer game framework built by the company.

## Game loop:
- join game with friends (p2p udp holepunch)
- build a pirate ship together in sandbox/god mode
- sail eastwards, try not to sink, encounter storms, other enemy ships, sea-serpents.
- (gamble coins, buy stupid things, mess around with the ship, etc)

It's essentially a friendslop-bet, but 2d-platformer-like, and with terraria-like scale.

## Tech stack:
- love2d + luajit for full project.
- lua-ENet for networking
- luaJIT string buffers for netcode serialization
- love2d love.physics for physics
- uses UDP holepunching for p2p networking. No servers required.

# Project Architecture:
## Entrypoint and modes:
The project-entrypoint is main.lua. 
The project start in one of 3 modes:
- "server_mode", for server-side,
- "client_mode", for client-side, e.g. actual gameplay,
- and "menu_mode", for the UI/menu + joining/creating servers. (default mode)

IMPORTANT NOTE: The engine CANNOT change between modes during runtime. Instead, game MUST be restarted.
This is quite elegant, since it means we can dump any data we want in the lua runtime, and have it exist as part of the "game-world". No managing "world" objects. No cleaning up state; just restart the game.


## 3 "parts" to the codebase:
umg-core: provides UMG api. No content, images, or assets here.
content: provides game content, hooks onto callbacks, images, etc.
ui-content: provides a UI client for standalone games.


## High-level architecture:
(NOT IMPLEMENTED YET.)

server/
    lobby: tracks players + auth

client/
    images, auto-atlas
    sfx
    particles
    ui, iml

shared/ (available on both client/server)
    ECSFrame: represents a "world reference frame." entities live here.
    Entity: a ECS entity. Contained inside an ECSFrame.
    serialization: packet-schema + packet ser/deser, strong-typing + validation of client-packets
    connection: Handles everything relating to enet connection + RPC API
    grid: handles the world-grid. (See note below)
    replication: tracks entity ids, replicate ent components across network

## Game details:



