-- TODO
local helpers = require("helpers")

local playerStats = {}
local bannedPlayers = {}

local function buildPlayer(playerId)
    playerStats[playerId] = {
        uid = humanGetUID(playerId),
        pos = humanGetPos(playerId),
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
    isPlayerBanned = isPlayerBanned
}
