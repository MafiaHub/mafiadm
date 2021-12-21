-- MafiaDM gamemode
-- Based on Mafia CS:GO gamemode originally written by NanobotZ
-- Thanks a lot to Asa for helping with sounds and models!

-- Load helpers
Helpers = require("utils/helpers")

---@diagnostic disable-next-line: lowercase-global
zac = require("core/anticheat")

---------------ENUMS---------------
VirtualKeys = require("utils/virtual_keys")
Modes = require("config/modes")

-- Load global settings first
Settings = require("config/settings")

-- Replace them with per-mission settings
Settings = Helpers.tableAssignDeep(Settings, require("maps/" .. MAPNAME))

PlayerStates = {
    SELECTING_TEAM = 1,
    WAITING_FOR_ROUND = 2,
    IN_ROUND = 3,
    DEAD = 4,
    SPECTATING = 5
}

GameStates = {
    WAITING_FOR_PLAYERS = 1,
    BUY_TIME = 2,
    ROUND = 3,
    AFTER_ROUND = 4,
    AFTER_GAME = 5
}

---------------VARIABLES---------------

Teams = {}

local function setupTeam(team, name)
    return {
        name = team.NAME,
        shortName = name,
        msgColor = team.COLOR,
        models = team.MODELS,
        score = 0,
        wonLast = false,
        winRow = 0,
        players = { },
        numPlayers = 0,
        spawnPoints = team.SPAWN_POINTS,
        spawnArea = team.SPAWN_AREA,
        spawnDir = team.SPAWN_DIR
    }
end

Teams.none = setupTeam(Settings.TEAMS.NONE, "none")
Teams.tt = setupTeam(Settings.TEAMS.TT, "tt")
Teams.ct = setupTeam(Settings.TEAMS.CT, "ct")

GM = {
    state = GameStates.WAITING_FOR_PLAYERS,
    roundTime = 0.0,
    roundBuyShopTime = 0.0,
    weaponPickups = {},
    healthPickups = {},
    buyWeaponPickups = {},
    buyMenuPages = {},
    skipTeamReq = false,
    pauseGame = false,

    -- stubs
    init = function ()
    end,

    update = function ()
    end,

    updateGameState = function (state)
        return false
    end,

    updatePlayer = function (player)
    end,

    handleSpecialBuy = function (player, weapon)
        return false
    end,

    initPlayer = function ()
        return {}
    end,

    onPlayerInsidePickupRadius = function (playerId, pickupId)
    end,

    onPlayerKeyPress = function (player, isDown, key)
    end,

    diePlayer = function (player, inflictor, damage, hitType, bodyPart, disconnected)
    end
}

EmptyGM = nil

CurTime = 0.0
WaitTime = 0.0

Players = {}

---------------FUNCTIONS---------------

require("core/functions")

---------------COMMANDS---------------

require("core/commands")

---------------EVENTS---------------

require("core/events")