-- TODO
local helpers = require("helpers")

local playerStats = {}

-- List of persistent bans
local bannedPlayers = require("bans")

-- List of admins
local admins = require("admins")

local function isAdmin(uid)
    return helpers.tableHasValue(admins, uid)
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
    bannedPlayers = table.insert(bannedPlayers, uid)
end

local function isPlayerBanned(uid)
    return helpers.tableHasValue(bannedPlayers, uid)
end

local function reloadLists()
    admins = helpers.tableAssign(admins, require("admins"))
    bannedPlayers = helpers.tableAssign(bannedPlayers, require("bans"))
end

return {
    buildPlayer = buildPlayer,
    clearPlayer = clearPlayer,
    setPlayerPos = setPlayerPos,
    validateStats = validateStats,
    banPlayer = banPlayer,
    isPlayerBanned = isPlayerBanned,
    isAdmin = isAdmin,
    reloadLists = reloadLists
}
