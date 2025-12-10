local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local SEARCH_PLACE = getgenv().SEARCH_PLACE
local TARGET_PLACE = getgenv().TARGET_PLACE
local MAX_PING = 60

print("[AFTER TELEPORT] Running freeze script...")
queue_on_teleport([[
game:GetService("RunService").RenderStepped:Connect(function()
    while true do end
end)
]])

local function findServer()
    local cursor = ""

    while true do
        local success, result = pcall(function()
            local url = "https://games.roblox.com/v1/games/"..SEARCH_PLACE.."/servers/Public?sortOrder=Asc&limit=100&cursor="..cursor
            return game:HttpGet(url)
        end)

        if not success then
            print("Request failed... retrying")
            task.wait(1)
            continue
        end

        local data = HttpService:JSONDecode(result)

        for _, s in ipairs(data.data) do
            print("Checking server:", s.id, "Players:", s.playing, "Ping:", s.ping)

            if s.playing == 1 and s.ping and s.ping <= MAX_PING then
                print("Valid server found:", s.id)
                return s.id
            end
        end

        cursor = data.nextPageCursor
        if not cursor or cursor == "null" then
            return nil
        end

        task.wait(0.3)
    end
end

local function teleportToServer(serverId)
    print("Attempting teleport:", serverId)

    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(TARGET_PLACE, serverId, Players.LocalPlayer)
    end)

    if not success then
        warn("Teleport failed:", err)
        print("Retrying search...")
        task.wait(1)
        local newServer = findServer()
        if newServer then
            teleportToServer(newServer)
        else
            warn("No server found on retry.")
        end
    end
end

-- MAIN:
local serverId = findServer()

if serverId then
    teleportToServer(serverId)
else
    warn("No valid server found.")
end
