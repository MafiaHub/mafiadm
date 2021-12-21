-- TODO
local playerStats = {}

-- List of persistent bans
local bannedPlayers = require("config/bans")

-- List of admins
local admins = require("config/admins")

local ALLOWED_DIST = 6.0
local NEXT_CHECK = 1.0
local WARN_RESET = 80.0
local MAX_WARNS = 10
local lastCheck = 0.0

local function isAdmin(uid)
    return Helpers.tableHasValue(admins, uid)
end

local function buildPlayer(playerId)
    local uid = humanGetUID(playerId)
    playerStats[playerId] = {
        uid = uid,
        pos = humanGetPos(playerId),
        admin = isAdmin(uid),
        last = CurTime,
        warnPoints = 0,
        warnCleanup = 0,
    }

    if playerStats[playerId].admin then
        sendClientMessage(playerId, "Signed in as Admin!")
    end
end

local function clearPlayer(playerId)
    playerStats[playerId] = nil
end

local function setPlayerPos(playerId, pos)
    playerStats[playerId].pos = pos
    humanSetPos(playerId, pos)
end

local function banPlayer(uid)
    table.insert(bannedPlayers, uid)
end

local function isPlayerBanned(uid)
    return Helpers.tableHasValue(bannedPlayers, uid)
end

local function validateStats()
    if lastCheck < CurTime then
        for playerId, stats in pairs(playerStats) do
            if humanIsSpawned(playerId) then
                local curPos = humanGetPos(playerId)
                local lastPos = stats.pos
                local dist = Helpers.distance(curPos, lastPos)
                if dist > ALLOWED_DIST*humanGetSpeed(playerId) then
                    local uid = stats.uid
                    local name = humanGetName(playerId)
                    local last = stats.last
                    local now = CurTime
                    local diff = now - last
                    local msg = string.format("#FF0000%s (%s) moved %.2f meters in %.2f seconds !", name, uid, dist, diff)
                    sendClientMessageToAll(msg)
                    setPlayerPos(playerId, lastPos)

                    stats.warnPoints = stats.warnPoints + 1

                    if stats.warnPoints > MAX_WARNS then
                        local msg = string.format("#FF0000%s (%s) has been banned due to suspicious behavior!", name, uid)
                        sendClientMessageToAll(msg)
                        clearPlayer(playerId)
                        humanKick(playerId)
                        banPlayer(uid)
                    end

                    stats.warnCleanup = CurTime + WARN_RESET
                else
                    stats.pos = curPos

                    if stats.warnCleanup < CurTime then
                        stats.warnPoints = 0
                    end
                end

                stats.last = CurTime
            end
        end

        lastCheck = CurTime + NEXT_CHECK
    end
end

local function reloadLists()
    admins = Helpers.tableAssign(admins, require("config/admins"))
    bannedPlayers = Helpers.tableAssign(bannedPlayers, require("config/bans"))
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
