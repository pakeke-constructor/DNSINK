

# DO-NOT-SINK:
"DO NOT SINK", or "DNSINK" is a pirate-themed multiplayer party-game built in love2d, with lua.
(Think like terraria-sandbox-style, but you are on a self-contained pirate-ship with friends.)

## Game loop:
- join game with friends (p2p udp holepunch)
- build a pirate ship together in sandbox/god mode
- sail eastwards, try not to sink, encounter storms, other enemy ships, sea-serpents.
- (gamble coins, buy stupid things, mess around with the ship, etc)

It's essentially a friendslop-bet, but 2d-platformer-like, and with terraria-like scale.

## Tech stack:
- love2d + luajit for overall project.
- lua-ENet for networking
- luaJIT string buffers for netcode serialization
- love2d love.physics for physics
- uses UDP holepunching for p2p networking. No servers required.

## Project architecture:
The project-entrypoint is main.lua. 
The project start in one of 3 modes:
- "server_mode", for server-side,
- "client_mode", for client-side, e.g. actual gameplay,
- and "menu_mode", for the UI/menu + joining/creating servers. (default mode)



