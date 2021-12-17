-- TODO

local playerStats = {}

local function buildPlayer(playerId)
    -- TODO
end

local function clearPlayer(playerId)
    -- TODO
end

local function setPlayerPos(playerId, pos)
    -- TODO
    humanSetPos(playerId, pos)
end

local function validateStats()
    -- TODO
end

return {
    buildPlayer = buildPlayer,
    clearPlayer = clearPlayer,
    setPlayerPos = setPlayerPos,
    validateStats = validateStats
}