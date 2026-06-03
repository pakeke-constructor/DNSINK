local socket = require("socket")

local CMD_CHAN, RECV_CHAN, SEND_CHAN, CRASH_CHAN, PORT = ...
---@cast CMD_CHAN love.Channel   -- main sends "quit" here
---@cast RECV_CHAN love.Channel  -- thread pushes received messages here
---@cast SEND_CHAN love.Channel  -- main pushes responses here
---@cast CRASH_CHAN love.Channel -- main pushes crash payload to broadcast

local server
for attempt = 1, 10 do
    local s, err = socket.bind("127.0.0.1", PORT)
    if s then server = s; break end
    socket.sleep(0.5)
end
if not server then error("agentbridge: could not bind port " .. PORT) end
server:settimeout(0)

local clients = {}

while true do
    -- check quit
    local cmd = CMD_CHAN:pop()
    if cmd == "quit" then
        for i = 1, #clients do clients[i]:close() end
        server:close()
        return
    end

    -- accept new connections
    local client = server:accept()
    if client then
        client:settimeout(0)
        clients[#clients + 1] = client
    end

    -- read from clients (line-delimited JSON)
    local i = 1
    while i <= #clients do
        local line, err = clients[i]:receive("*l")
        if line then
            RECV_CHAN:push(i .. "|" .. line)
        elseif err == "closed" then
            table.remove(clients, i)
            i = i - 1
        end
        i = i + 1
    end

    -- send responses back to clients
    while true do
        local resp = SEND_CHAN:pop()
        if not resp then break end
        local sep = resp:find("|", 1, true)
        if sep then
            local idx = tonumber(resp:sub(1, sep - 1))
            local payload = resp:sub(sep + 1)
            if idx and clients[idx] then
                clients[idx]:send(payload .. "\n")
            end
        end
    end

    -- broadcast crash to all clients
    local crash = CRASH_CHAN:pop()
    if crash then
        for j = 1, #clients do
            clients[j]:send(crash .. "\n")
        end
    end

    socket.sleep(0.001)
end
