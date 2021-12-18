-- TODO
local playerStats = {}

-- List of persistent bans
local bannedPlayers = require("config/bans")

-- List of admins
local admins = require("config/admins")

local function isAdmin(uid)
    return Helpers.tableHasValue(admins, uid)
end

local function buildPlayer(playerId)
    local uid = humanGetUID(playerId)
    playerStats[playerId] = {
        uid = uid,
        pos = humanGetPos(playerId),
        admin = isAdmin(uid),
        last = getTime()
    }

    if playerStats[playerId].admin then
        sendClientMessage(playerId, "Signed in as Admin!")
    end
end

local function clearPlayer(playerId)
    playerStats[playerId] = nil
end

local function setPlayerPos(playerId, pos)
    -- TODO
    humanSetPos(playerId, pos)
end

local function validateStats()
    -- TODO
    for playerId, stats in pairs(playerStats) do
        
    end
end

local function banPlayer(uid)
    table.insert(bannedPlayers, uid)
end

local function isPlayerBanned(uid)
    return Helpers.tableHasValue(bannedPlayers, uid)
end

local function reloadLists()
    admins = Helpers.tableAssign(admins, require("admins"))
    bannedPlayers = Helpers.tableAssign(bannedPlayers, require("bans"))
end

local function showPlayerData()
    for playerId, stats in pairs(playerStats) do
        print("Name: " .. humanGetName(playerId))
        print("ID: " .. tostring(playerId))
        print("UserID: " .. tostring(stats.uid))
        print("Pos: " .. stats.pos[1] .. ", " .. stats.pos[2] .. ", " .. stats.pos[3])
        print("Admin: " .. tostring(stats.admin))
        print("Last: " .. stats.last)
        print("\n")
    end
end

return {
    buildPlayer = buildPlayer,
    clearPlayer = clearPlayer,
    setPlayerPos = setPlayerPos,
    validateStats = validateStats,
    banPlayer = banPlayer,
    isPlayerBanned = isPlayerBanned,
    isAdmin = isAdmin,
    reloadLists = reloadLists,
    showPlayerData = showPlayerData
}
