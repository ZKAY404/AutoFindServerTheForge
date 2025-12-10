local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local SEARCH_PLACE = getgenv().SEARCH_PLACE
local TARGET_PLACE = getgenv().TARGET_PLACE
local MAX_PING = 60

-- SAVE CURSOR BETWEEN TELEPORTS
getgenv().GLOBAL_CURSOR = ""


print("[AFTER TELEPORT] Running freeze script...")
queue_on_teleport([[
wait(2)
game:GetService("RunService").RenderStepped:Connect(function()
    while true do end
end)
]])


-- FIND SERVER – CONTINUE FROM LAST CURSOR
local function findServer()
    local cursor = getgenv().GLOBAL_CURSOR  -- <-- USE GLOBAL CURSOR

    while true do
        local success, result = pcall(function()
            local url = "https://games.roblox.com/v1/games/"..SEARCH_PLACE.."/servers/Public?sortOrder=Asc&limit=100&cursor="..cursor
            return game:HttpGet(url)
        end)

        if not success then
            print("Request failed, retrying...")
            task.wait(1)
            continue
        end

        local data = HttpService:JSONDecode(result)

        for _, s in ipairs(data.data) do
            print("Checking server:", s.id, "Players:", s.playing, "Ping:", s.ping)

            if s.playing <= 2 and s.ping and s.ping <= MAX_PING then
                print("Valid server found:", s.id)

                -- SAVE NEXT CURSOR
                getgenv().GLOBAL_CURSOR = data.nextPageCursor or ""

                return s.id
            end
        end

        cursor = data.nextPageCursor
        getgenv().GLOBAL_CURSOR = cursor  -- <-- SAVE PROGRESS

        if not cursor then
            print("Reached end of server list. Restarting from beginning.")
            getgenv().GLOBAL_CURSOR = ""   -- <-- RESET LIST
            return nil
        end

        task.wait(0.35)
    end
end


-- TELEPORT LOOP (NO MORE EXTRA HTTP LOAD)
local function teleportToServer(serverId)
    while true do
        print("Attempt teleport:", serverId)

        local success = pcall(function()
            TeleportService:TeleportToPlaceInstance(TARGET_PLACE, serverId, Players.LocalPlayer)
        end)

        -- Teleport failed → continue loop → after teleport failure, serverId stays same
        task.wait(1)

        print("Teleport failed; finding next server after previous cursor...")

        local nextServer = findServer()
        if nextServer then
            serverId = nextServer
        end
    end
end


-- MAIN
local serverId = findServer()
if serverId then
    teleportToServer(serverId)
else
    warn("No valid server found.")
end
