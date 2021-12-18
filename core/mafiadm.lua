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

Teams = {
	none = {
		name = Settings.TEAMS.NONE.NAME,
		shortName = "none",
		msgColor = Settings.TEAMS.NONE.COLOR,
		players = { },
		numPlayers = 0
	},
	tt = {
		name = Settings.TEAMS.TT.NAME,
		shortName = "tt",
		msgColor = Settings.TEAMS.TT.COLOR,
		models = Settings.TEAMS.TT.MODELS,
		score = 0,
		wonLast = false,
		winRow = 0,
		players = { },
		numPlayers = 0,
		spawnArea = Settings.TEAMS.TT.SPAWN_AREA,
		spawnDir = Settings.TEAMS.TT.SPAWN_DIR
	},
	ct = {
		name = Settings.TEAMS.CT.NAME,
		shortName = "ct",
		msgColor = Settings.TEAMS.CT.COLOR,
		models = Settings.TEAMS.CT.MODELS,
		score = 0,
		wonLast = false,
		winRow = 0,
		players = { },
		numPlayers = 0,
		spawnArea = Settings.TEAMS.CT.SPAWN_AREA,
		spawnDir = Settings.TEAMS.CT.SPAWN_DIR
	}
}

Game = {
	state = GameStates.WAITING_FOR_PLAYERS,
	roundTime = 0.0,
	weaponPickups = {},
	healthPickups = {},
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

    diePlayer = function (player)
    end
}

EmptyGame = nil

CurTime = 0.0
WaitTime = 0.0

Players = {}

---------------FUNCTIONS---------------

require("core/functions")

---------------COMMANDS---------------

require("core/commands")

---------------EVENTS---------------

require("core/events")