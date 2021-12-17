-- TODO
local helpers = require("helpers")

local playerStats = {}

-- List of persistent bans
local bannedPlayers = {119528313747144705}

-- List of admins
local admins = {
    119528313747144705 -- zak
}

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

return {
    buildPlayer = buildPlayer,
    clearPlayer = clearPlayer,
    setPlayerPos = setPlayerPos,
    validateStats = validateStats,
    banPlayer = banPlayer,
    isPlayerBanned = isPlayerBanned,
    isAdmin = isAdmin
}
