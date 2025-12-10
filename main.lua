local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local SEARCH_PLACE = getgenv().SEARCH_PLACE -- World 1: 76558904092080 World 2: 129009554587176
local TARGET_PLACE = getgenv().TARGET_PLACE
local MAX_PING = 60

local function findServer()
    local cursor = ""

    while true do
        -- Safe request (avoid 429)
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

        task.wait(0.3) -- avoid rate-limit 429
    end
end

local serverId = findServer()

if serverId then
    print("Teleporting to:", serverId)
    TeleportService:TeleportToPlaceInstance(TARGET_PLACE, serverId, Players.LocalPlayer)
else
    warn("No valid server found.")
end
