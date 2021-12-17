-- MafiaDM gamemode
-- Originally written by NanobotZ
-- Thanks a lot to Asa for helping with sounds and models!

--[[
	How to set up:
	1. Update server.json to load mafiadm.lua
	2. Set mission name in server.json to "tutorial"
	3. Update mapload.lua file to specify which settings to load from maps folder
--]]

-- Load helpers
Helpers = require("helpers")
local zac = require("anticheat")

---------------ENUMS---------------
VirtualKeys = require("virtual_keys")
Modes = require("modes")

-- Load global settings first
Settings = require("settings")

-- Replace them with per-mission settings
Settings = Helpers.tableAssign(Settings, require("mapload"))

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
}

EmptyGame = nil

CurTime = 0.0
WaitTime = 0.0

Players = {}

---@diagnostic disable-next-line: lowercase-global
cmds = {}

---------------FUNCTIONS---------------
---@diagnostic disable: lowercase-global

function InitMode(mode)
	local modeInfo = nil
	if mode == Modes.BOMB then
		modeInfo = require("modes/bomb")
	elseif mode == Modes.TDM then
		modeInfo = require("modes/tdm")
	end

	Game = Helpers.tableAssign(Game, modeInfo)
end

function inTeamColor(team, text)
	return team.msgColor .. (text or team.name) .. "#FFFFFF"
end

Teams.none.inTeamColor = inTeamColor
Teams.tt.inTeamColor = inTeamColor
Teams.ct.inTeamColor = inTeamColor

function sendSelectTeamMessage(player)
	if Settings.TEAMS.AUTOBALANCE == true then
		return
	end

	sendClientMessage(player.id, "Please press a corresponding number key to select an option:")
	sendClientMessage(player.id, "1 : Choose " .. Teams.tt:inTeamColor() .. " team (" .. Teams.tt.numPlayers .. " Players).") -- IDEA refresh when numPlayers changes ?
	sendClientMessage(player.id, "2 : Choose " .. Teams.ct:inTeamColor() .. " team (" .. Teams.ct.numPlayers .. " Players).") -- IDEA refresh when numPlayers changes ?
	sendClientMessage(player.id, "3 : Auto-assign team.")
end

function spectate(player, order) -- TODO fix :)
	if order then
		local plys = {}
		for _, player2 in pairs(player.team.players) do
			if player2.state == PlayerStates.IN_ROUND then
				table.insert(plys, player2.id)
			end
		end

		if #plys == 0 then
			return false
		end

		table.sort(plys, function (a, b)
				return a < b
			end
		)

		local spectating = nil
		if player.spectating then
			for index, value in ipairs(plys) do
				if value == player.spectating.id then
					spectating = index
				end
			end
		else
			spectating = 1
		end

		if not spectating then
			return false
		end

		spectating = spectating + order
		if spectating < 1 then
			spectating = #plys
		elseif spectating > #plys then
			spectating = 1
		end

		local playerToSpectate = Players[plys[spectating]]

		if player.spectating ~= playerToSpectate then
			sendClientMessage(player.id, "Now spectating " .. playerToSpectate.team:inTeamColor(humanGetName(playerToSpectate.id)))
		end

		player.spectating = playerToSpectate
		player.state = PlayerStates.SPECTATING
		cameraFollow(player.id, playerToSpectate.id)

		return true
	end
end

function sendClientMessageToAllWithStates(text, ...)
	for _, player in pairs(Players) do
		if Helpers.tableHasValue(arg, player.state) then
			sendClientMessage(player.id, text)
		end
	end
end

function addHudAnnounceMessage(player, msg)
	if player.hudAnnounceMessage then
		player.hudAnnounceMessage = player.hudAnnounceMessage .. "~" .. msg
	else
		player.hudAnnounceMessage = msg
	end
end

function getOppositeTeam(team)
	return team == Teams.ct and Teams.tt or Teams.ct
end

function findPlayerWithUID(uid)
	for _, player in pairs(Players) do
		if player.uid == uid then
			return player.id
		end
	end

	return nil
end

function addPlayerMoney(player, money, msg, color)
	player.money = player.money + money

	if player.money > Settings.PLAYER_MAX_MONEY then
		player.money = Settings.PLAYER_MAX_MONEY
	end

	hudAddMessage(player.id,
		string.format("%s %d$", (msg or "Awarded money:"), tostring(money)),
		color or Helpers.rgbToColor(255, 255, 255))
end

function teamAddPlayerMoney(team, money, text)
	for _, player in pairs(team.players) do
		addPlayerMoney(player, money, text)
	end
end

function removePlayerFromTeam(player)
	if not player.team then
		return
	end

	player.team.numPlayers = player.team.numPlayers - 1
	player.team.players[player.id] = nil
	player.team = nil
end

function assignPlayerToTeam(player, team)
	removePlayerFromTeam(player)

	if Settings.TEAMS.AUTOBALANCE == true and team == Teams.none then
		team = Teams.ct.numPlayers < Teams.tt.numPlayers and Teams.ct or Teams.tt
	end

	team.numPlayers = team.numPlayers + 1
	team.players[player.id] = player
	player.team = team
	player.state = PlayerStates.WAITING_FOR_ROUND

	sendClientMessage(player.id, "You are assigned to team " .. team:inTeamColor() .. "!")
	spectate(player, 1)
end

function autoAssignPlayerToTeam(player)
	local team = Teams.ct.numPlayers < Teams.tt.numPlayers and Teams.ct or Teams.tt
	assignPlayerToTeam(player, team)
end

function switchPlayerTeam(player)
	if player.team == Teams.none then
		return
	end

	assignPlayerToTeam(player, getOppositeTeam(player.team))
end

function spawnOrTeleportPlayer(player, optionalSpawnPos, optionalSpawnDir, optionalModel)
	local spawnPos = { 0.0, 0.0, 0.0 }

	if not optionalSpawnPos then
		local collides = true
		while collides do
			collides = false
			spawnPos = Helpers.randomPointInCuboid(player.team.spawnArea)

			for _, player2 in pairs(player.team.players) do
				if player2.id ~= player.id and player2.state == PlayerStates.IN_ROUND then
					if Helpers.distanceSquared(spawnPos, humanGetPos(player2.id)) < Settings.SPAWN_RANGE_SQUARED then
						collides = true
						break
					end
				end
			end
		end
	end

	player.lastPos = optionalSpawnPos or spawnPos
	player.lastDir = optionalSpawnDir or player.team.spawnDir
	zac.setPlayerPos(player.id, optionalSpawnPos or spawnPos)
	humanSetDir(player.id, optionalSpawnDir or player.team.spawnDir)

	if not player.isSpawned then
		humanDespawn(player.id)
		humanSetModel(player.id, optionalModel or Helpers.randomTableElem(player.team.models))
		humanSpawn(player.id)

		if not player.isSpawned or player.state == PlayerStates.DEAD then
			inventoryAddWeaponDefault(player.id, 6) -- Colt Detective Special -- IDEA add default weapons option to game_settings?
		end

		player.isSpawned = true
	elseif humanGetHealth(player.id) < 100.0 then
		humanSetHealth(player.id, 100.0)
	end
end

function teamCountAlivePlayers(team)
	local count = 0

	for _, player in pairs(team.players) do
		if player.state == PlayerStates.IN_ROUND then
			count = count + 1
		end
	end

	return count
end

function prepareBuyMenu()
	local pages = {}
	for _, item in pairs(Settings.WEAPONS) do
		if item.page then
			if not pages[item.page] then
				pages[item.page] = {}
			end

			table.insert(pages[item.page], item)
		end
	end

	Game.buyMenuPages = pages
end

function clearUpPickups()
	for _, pickupId in ipairs(Game.weaponPickups) do
		pickupDestroy(pickupId)
	end
	Game.weaponPickups = {}
end

function sendBuyMenuMessage(player)
	local key = 1

	local playerPage = player.buyMenuPage
	player.buyMenuPage = {}

	-- IDEA clear chat?
	sendClientMessage(player.id, "\n\n")
	sendClientMessage(player.id, string.format("Your money: #00CE00%d$#FFFFFF", player.money))

	if player.isInMainBuyMenu then
		for _, pageName in ipairs(Settings.PAGES_ORDER) do
			sendClientMessage(player.id, string.format("%d: %s", key, pageName))
			player.buyMenuPage[key] = Game.buyMenuPages[pageName]
			key = key + 1
		end
	else
		sendClientMessage(player.id, "0: Go back")
		for _, item in ipairs(playerPage) do
			if Helpers.tableHasValue(item.canBuy, player.team.shortName) and (item.gmOnly == nil or item.gmOnly == Settings.MODE) then
				sendClientMessage(player.id, string.format("%d: %s - %s%d$#FFFFFF", key, item.name, item.cost > player.money and "#FF0000" or "#FFFFFF", item.cost))
				player.buyMenuPage[key] = item
				key = key + 1
			end
		end
	end
end

function prepareSpawnAreaCheck(team)
	team.spawnAreaCheck = {
		{ team.spawnArea[1][1], team.spawnArea[1][2] - 5, team.spawnArea[1][3] },
		{ team.spawnArea[2][1], team.spawnArea[2][2] + 5, team.spawnArea[2][3] }
	}
end

function playSoundRanged(player, pos, soundSetting)
	local ppos = player.isSpawned and humanGetPos(player.id) or humanGetCameraPos(player.id)
	local volume = Helpers.remapValue(Helpers.distance(ppos, pos), soundSetting.RANGE, 0, 0, 1)
	if volume > 0.0 then
		playSound(player.id, soundSetting.FILE, pos, soundSetting.RANGE, volume, false)
	end
end

function updatePlayers()
	for _, player in pairs(Players) do
		if player.isSpawned and player.state == PlayerStates.IN_ROUND then
			local curPos = humanGetPos(player.id)
			local curDir = humanGetDir(player.id)

			if Helpers.compareVectors(player.lastPos, curPos) and Helpers.compareVectors(player.lastDir, curDir) then
				-- player hasn't moved
			else
				player.timeIdleStart = CurTime
			end

			player.lastPos = curPos
			player.lastDir = curDir

			local playerWeaponId = inventoryGetCurrentItem(player.id).weaponId
			if Helpers.tableHasValue(Settings.HEAVY_WEAPONS, playerWeaponId) then
				humanSetSpeed(player.id, Settings.HEAVY_WEAPONS_RUN_SPEED)
			elseif Helpers.tableHasValue(Settings.LIGHT_WEAPONS, playerWeaponId) then
				humanSetSpeed(player.id, Settings.LIGHT_WEAPONS_RUN_SPEED)
			else
				humanSetSpeed(player.id, Settings.NORMAL_WEAPONS_RUN_SPEED)
			end
		end

		Game.updatePlayer(player)

		if player.hudAnnounceMessage then
			hudAnnounce(player.id, player.hudAnnounceMessage, 1)
			player.hudAnnounceMessage = nil
		end
	end
end

function findWeaponInfoInSettings(weaponId)
	for _, info in pairs(Settings.WEAPONS) do
		if info.weaponId and info.weaponId == weaponId then
			return info
		end
	end

	return nil
end

function startGame()
	if Settings.HEALTH_PICKUPS then
		for _, pickupPos in ipairs(Settings.HEALTH_PICKUPS) do
			local healthPickupId = pickupCreate(pickupPos, Settings.HEALTH_PICKUP.MODEL)
			table.insert(Game.healthPickups, {
				id = healthPickupId,
				pos = pickupPos,
				time = 0.0
			})
		end
	end
end

function handleDyingOrDisconnect(playerId, inflictorId, damage, hitType, bodyPart, disconnected)
	local player = Players[playerId]
	local inflictor = Players[inflictorId]

	local inventory = inventoryGetItems(player.id)

	player.state = PlayerStates.DEAD

	if inflictor and player.id ~= inflictor.id and player.team ~= inflictor.team then
		local reward = 0
		local killType = ""
		print(hitType)
		if hitType == 2 then -- Explosion
			reward = findWeaponInfoInSettings(15).killReward -- 15 = Grenade
			killType = "Grenade"
		elseif hitType == 3 then -- Burn
			reward = findWeaponInfoInSettings(5).killReward -- 5 = Molotov
			killType = "Molotov"
		else
			local heldWeaponInfo = findWeaponInfoInSettings(inventoryGetCurrentItem(inflictor.id).weaponId)
			if heldWeaponInfo then
				reward = heldWeaponInfo.killReward
				killType = heldWeaponInfo.name
			end
		end

		if reward == 0 then
			print(humanGetName(inflictor.id) .. " killed " .. humanGetName(player.id) .. " mysteriously...")
		else
			inflictor.kills = inflictor.kills + 1
			addPlayerMoney(inflictor, reward, "Killing with " .. killType .. " got you")
			print(humanGetName(inflictor.id) .. " killed " .. humanGetName(player.id) .. " using " .. killType .. " and earned " .. tostring(reward) .. "$")
		end
	end

	Game.diePlayer(player)

	for _, item in pairs(inventory) do
		local weaponId = item.weaponId
		if weaponId > 1 and inventoryRemoveWeapon(playerId, weaponId) then
			local pos = Helpers.addRandomVectorOffset(humanGetPos(player.id), {1.0, 0.0, 1.0})
			local pickupId = weaponDropCreate(weaponId, pos, 2147483647, item.ammoLoaded, item.ammoHidden)
			table.insert(Game.weaponPickups, pickupId)
		end
	end

	if not disconnected then
		sendClientMessageToAll(inflictor.team:inTeamColor(humanGetName(inflictor.id)) .. " killed " .. player.team:inTeamColor(humanGetName(player.id)))
	end
end

local function updateGame()
	if Game.state == GameStates.WAITING_FOR_PLAYERS then
		if (Teams.tt.numPlayers >= Settings.MIN_PLAYER_AMOUNT_PER_TEAM and Teams.ct.numPlayers >= Settings.MIN_PLAYER_AMOUNT_PER_TEAM) or Game.skipTeamReq then
			Game.skipTeamReq = false
			for _, player in pairs(Players) do
				if player.team ~= Teams.none then
					if player.isSpawned and player.state == PlayerStates.DEAD then
						humanDespawn(player.id)
						player.cancelDespawn = true
						player.isSpawned = false
					end

					local items = nil
					if player.state ~= PlayerStates.DEAD then
						items = inventoryGetItems(player.id)
					end

					spawnOrTeleportPlayer(player)

					if items then
						for _, item in pairs(items) do
							if item.weaponId > 1 then
								inventoryRemoveWeapon(player.id, item.weaponId)
								inventoryAddWeaponDefault(player.id, item.weaponId)
							end
						end
					end

					player.state = PlayerStates.IN_ROUND

					player.isInMainBuyMenu = true
					sendBuyMenuMessage(player)
				end
			end

			Game.updateGameState(Game.state)
			Game.state = GameStates.BUY_TIME
			WaitTime = Settings.WAIT_TIME.BUYING + CurTime
		end
	elseif Game.state == GameStates.ROUND then
		for _, healthPickup in ipairs(Game.healthPickups) do
			if healthPickup.id == nil and healthPickup.time < CurTime then
				healthPickup.id = pickupCreate(healthPickup.pos, Settings.HEALTH_PICKUP.MODEL)
			end
		end

		Game.updateGameState(Game.state)
	elseif Game.state == GameStates.BUY_TIME then
		for _, player in pairs(Players) do
			addHudAnnounceMessage(player, string.format("Buy time - %.2fs", WaitTime - CurTime))

			if player.state == PlayerStates.IN_ROUND then
				if not Helpers.isPointInCuboid(humanGetPos(player.id), player.team.spawnAreaCheck) then
					--sendClientMessage(player.id, "Don't leave the spawn area during buy time please :)")
					spawnOrTeleportPlayer(player)
				end
			end
		end

		if CurTime > WaitTime then
			for _, player in pairs(Players) do
				player.buyMenuPage = nil
			end

			Game.updateGameState(Game.state)
			Game.state = GameStates.ROUND
			WaitTime = Settings.WAIT_TIME.ROUND + CurTime
		end

	elseif Game.state == GameStates.AFTER_ROUND then
		if WaitTime > CurTime then
			for _, player in pairs(Players) do
				addHudAnnounceMessage(player, string.format("Next round in %.2fs!", WaitTime - CurTime))
			end
		else
			clearUpPickups()

			Game.updateGameState(Game.state)
			Game.state = GameStates.WAITING_FOR_PLAYERS
			WaitTime = Settings.WAIT_TIME.BUYING + CurTime
		end
	elseif Game.state == GameStates.AFTER_GAME then
		if WaitTime > CurTime then
			for _, player in pairs(Players) do
				addHudAnnounceMessage(player, string.format("%s win! Next game in %.2fs!", Teams.tt.score > Teams.ct.score and Teams.tt.name or Teams.ct.name, WaitTime - CurTime))
			end
		else
			Teams.tt.score = 0
			Teams.tt.winRow = 0
			Teams.tt.wonLast = false

			Teams.ct.score = 0
			Teams.ct.winRow = 0
			Teams.ct.wonLast = false

			clearUpPickups()
			Game.updateGameState(Game.state)

			for _, player in pairs(Players) do
				player.money = Settings.PLAYER_STARTING_MONEY
				if player.isSpawned then
					humanDespawn(player.id)
					player.isSpawned = false
				end
				assignPlayerToTeam(player, Teams.none)
				player.state = PlayerStates.SELECTING_TEAM
				sendSelectTeamMessage(player)
			end

			Game = Helpers.deepCopy(EmptyGame)
			Game.state = GameStates.WAITING_FOR_PLAYERS

			startGame()
		end
	end
end

---------------COMMANDS---------------

function cmds.pos(player, ...)
	if zac.isAdmin(player.uid) then
		if player.isSpawned then
			local pos = humanGetPos(player.id)
			local dir = humanGetDir(player.id)
			local msg = "{ " .. tostring(pos[1]) .. " " .. tostring(pos[2]) .. " " .. tostring(pos[3] .. " }, ")
			msg = msg .. "{ " .. tostring(dir[1]) .. " " .. tostring(dir[2]) .. " " .. tostring(dir[3] .. " }")
			print(msg)
			sendClientMessage(player.id, msg)
		else
			sendClientMessage(player.id, "You are not spawned.")
		end
	end
end

function cmds.tskip(player, ...)
	if zac.isAdmin(player.uid) then
		WaitTime = CurTime
	end
end

function cmds.skip(player, ...)
	if zac.isAdmin(player.uid) then
		Game.skipTeamReq = true
	end
end

function cmds.moolah(player, ...)
	if zac.isAdmin(player.uid) then
		arg = {...}
		if #arg > 0 then
			local money = tonumber(arg[1])
			if money and money > 0 then
				addPlayerMoney(player, money, "You cheeky wanker, you got", Helpers.rgbToColor(255, 0, 255))
			end
		end
	end
end

function cmds.kickme(player)
	humanKick(player.id, "Self-Kick!!")
end

function cmds.acreload(player)
	if zac.isAdmin(player.uid) then
		zac.reloadLists()
	end
end

function cmds.whois(player)
	if zac.isAdmin(player.uid) then
		zac.showPlayerData()
	end
end

function cmds.p(player)
	if zac.isAdmin(player.uid) then
		Game.pauseGame = not Game.pauseGame
	end
end

function cmds.ban(player, ...)
	if zac.isAdmin(player.uid) then
		local arg = {...}
		if #arg > 0 then
			local playerId = tonumber(arg[1])
			if playerId then
				zac.banPlayer(humanGetUID(playerId))
				humanKick(playerId, "You have been banned from the server.")
			end
		end
	end
end

function cmds.banid(player, ...)
	if zac.isAdmin(player.uid) then
		local arg = {...}
		if #arg > 0 then
			local uid = tonumber(arg[1])
			if uid then
				zac.banPlayer(uid)

				local playerId = findPlayerWithUID(uid)
				if playerId then
					humanKick(playerId, "You have been banned from the server.")
				end
			end
		end
	end
end

-- function cmds.setSpeed(player, ...)
-- 	if player.isSpawned then
-- 		local speed = tonumber(arg[1])
-- 		humanSetSpeed(player.id, speed)
-- 	else
-- 		sendClientMessage(player.id, "You are not spawned :)")
-- 	end
-- end

---------------EVENTS---------------

---@diagnostic disable-next-line: lowercase-global
function onTick()
	if not Game.pauseGame then
		CurTime = getTime() * 0.001
		updateGame()
		Game.update()
		updatePlayers()
		zac.validateStats()
	end
end

---@diagnostic disable-next-line: lowercase-global
function onScriptStart()
	changeMission(Settings.MISSION)
	prepareBuyMenu()
	prepareSpawnAreaCheck(Teams.tt)
	prepareSpawnAreaCheck(Teams.ct)

	EmptyGame = Helpers.deepCopy(InitMode(Settings.MODE))
	startGame()
	print("MafiaDM was initialised!\n")
end

---@diagnostic disable-next-line: lowercase-global
function onPlayerWeaponDrop(playerId, pickupId)
	table.insert(Game.weaponPickups, pickupId)
	return true
end

---@diagnostic disable-next-line: lowercase-global
function onPlayerConnected(playerId)
	if zac.isPlayerBanned(humanGetUID(playerId)) then
		humanKick(playerId, "You are banned on this server!")
		return
	end

	local welcomeMessage = string.format('#FF0000[GM]#FFFFFF player #00FF00**%s** #FFFFFFhas connected to the server :)', humanGetName(playerId))
	--sendClientMessageToAllWithStates(welcomeMessage, PlayerStates.SELECTING_TEAM, PlayerStates.DEAD, PlayerStates.WAITING_FOR_ROUND, PlayerStates.SPECTATING)
	sendClientMessageToAll(welcomeMessage)

	local player = {
		id = playerId,
		uid = humanGetUID(playerId),
		state = PlayerStates.SELECTING_TEAM,
		team = Teams.none,
		money = Settings.PLAYER_STARTING_MONEY,
		isSpawned = false,
		cancelDespawn = false,
		buyMenuPage = nil,
		spectating = nil,
		lastPos = nil,
		lastDir = nil,
		timeIdleStart = nil,
		hudAnnounceMessage = nil,
		kills = 0
	}

	player = Helpers.tableAssign(player, Game.initPlayer())
	Players[playerId] = player
	Teams.none[playerId] = player

	sendClientMessage(playerId, "#FFFF00 Welcome to MafiaDM")

	if Settings.TEAMS.AUTOBALANCE == true then
		assignPlayerToTeam(player, Teams.none)
	else
		sendSelectTeamMessage(player)
	end

	zac.buildPlayer(playerId)

	if Settings.WELCOME_CAMERA then
    	cameraInterpolate(playerId, Settings.WELCOME_CAMERA.START.POS, Settings.WELCOME_CAMERA.START.ROT, Settings.WELCOME_CAMERA.STOP.POS, Settings.WELCOME_CAMERA.STOP.ROT, Settings.WELCOME_CAMERA.TIME)
	end
end

---@diagnostic disable-next-line: lowercase-global
function onPlayerDisconnected(playerId)
	if Players[playerId] == nil then
		return
	end
	sendClientMessageToAll("Player " .. Players[playerId].team:inTeamColor(humanGetName(playerId)) .. " has disconnected.")

	handleDyingOrDisconnect(playerId, nil, nil, nil, nil, true)
	onPlayerDie(playerId)

	zac.clearPlayer(playerId)
	removePlayerFromTeam(Players[playerId])
	Players[playerId] = nil
end

---@diagnostic disable-next-line: lowercase-global
function onPlayerHit(playerId, inflictorId, damage, hitType, bodyPart)
	print("damage " .. tostring(damage))

	if Game.state == GameStates.BUY_TIME then
		return 0
	end

    if Players[playerId].team == Players[inflictorId].team then
		if not Settings.FRIENDLY_FIRE.ENABLED then
			return 0
		else
			return damage * Settings.FRIENDLY_FIRE.DAMAGE_MULTIPLIER
		end
    else
        return damage
    end
end

---@diagnostic disable-next-line: lowercase-global
function onPlayerDying(playerId, inflictorId, damage, hitType, bodyPart)
	handleDyingOrDisconnect(playerId, inflictorId, damage, hitType, bodyPart, false)
end

---@diagnostic disable-next-line: lowercase-global
function onPlayerDie(playerId, inflictorId, damage, hitType, bodyPart)
	local player = Players[playerId]

	if not player then
		humanDespawn(playerId)
		return
	end

	if player.cancelDespawn then
		print("canceled despawn")
		player.cancelDespawn = false
	else
		humanDespawn(player.id)
		player.isSpawned = false

		spectate(player, 1)
	end
end

---@diagnostic disable-next-line: lowercase-global
function onPlayerInsidePickupRadius(playerId, pickupId)
	for _, healthPickup in ipairs(Game.healthPickups) do
		if healthPickup.id == pickupId then
			local player = Players[playerId]

			if humanGetHealth(playerId) < 100.0 then
				humanSetHealth(playerId, Helpers.min(100.0, humanGetHealth(player.id) + Settings.HEALTH_PICKUP.HEALTH))
				sendClientMessage(playerId, "#20E7E4You have used a health pickup!")

				pickupDestroy(pickupId)
				healthPickup.id = nil
				healthPickup.time = CurTime + Settings.HEALTH_PICKUP.RESPAWN_TIME
			end
		end
	end

	Game.onPlayerInsidePickupRadius(playerId, pickupId)
end

---@diagnostic disable-next-line: lowercase-global
function onPlayerKeyPress(playerId, isDown, key)
	local player = Players[playerId]

	--print(string.format("player %d state %d key %d isDown %s", player.id, player.state, key, tostring(isDown)))

	player.timeIdleStart = CurTime

	if player.state == PlayerStates.SELECTING_TEAM then
		if isDown then
			if key == VirtualKeys.N1 then
				assignPlayerToTeam(player, Teams.tt)
			elseif key == VirtualKeys.N2 then
				assignPlayerToTeam(player, Teams.ct)
			elseif key == VirtualKeys.N3 then
				autoAssignPlayerToTeam(player)
			end
		end
	elseif Game.state == GameStates.BUY_TIME then
		if player.state == PlayerStates.IN_ROUND and isDown then
			if player.isInMainBuyMenu then
				local menu = player.buyMenuPage[key - VirtualKeys.N0]
				if menu then
					player.buyMenuPage = menu
					player.isInMainBuyMenu = false
					sendBuyMenuMessage(player)
				end
			else
				if key == VirtualKeys.N0 then
					player.isInMainBuyMenu = true
					sendBuyMenuMessage(player)
				else
					local weapon = player.buyMenuPage[key - VirtualKeys.N0]
					if weapon then
						if player.money >= weapon.cost then
							local bought = false
							if weapon.special then
								bought = Game.handleSpecialBuy(player, weapon)
							else
								if inventoryAddWeaponDefault(player.id, weapon.weaponId) then
									player.money = player.money - weapon.cost
									bought = true
									hudAddMessage(player.id, string.format("Bought %s for %d$, money left: %d$", weapon.name, weapon.cost, player.money), Helpers.rgbToColor(34, 207, 0))
								else
									hudAddMessage(player.id, "Couldn't buy this weapon!", Helpers.rgbToColor(255, 38, 38))
								end
							end

							if bought then
								sendBuyMenuMessage(player)
							end
						else
							hudAddMessage(player.id, string.format("Not enough money to buy this weapon, weapon: %d$, you: %d$!", weapon.cost, player.money), Helpers.rgbToColor(255, 38, 38))
						end
					end
				end
			end
		end
	elseif player.state == PlayerStates.SPECTATING or player.state == PlayerStates.WAITING_FOR_ROUND then
		if isDown then
			local order = nil
			if key == VirtualKeys.Left or key == VirtualKeys.A then
				order = -1
			elseif key == VirtualKeys.Right or key == VirtualKeys.D then
				order = 1
			end

			spectate(player, order)
		end
	end

	Game.onPlayerKeyPress(player, isDown, key)
end

---@diagnostic disable-next-line: lowercase-global
function onPlayerChat(playerId, message)
	if #message > 0 and Helpers.stringCharAt(message, 1) == "/" then
		message = message:sub(2)
		local splits = Helpers.stringSplit(message)
		local cmd = cmds[splits[1]]

		if cmd then
			local player = Players[playerId]
			cmd(player, table.unpack(Helpers.tableSlice(splits, 2)))
		end
	else
		local player = Players[playerId]
		sendClientMessageToAll(player.state == PlayerStates.DEAD and "DEAD " or "" .. player.team:inTeamColor(humanGetName(player.id)) .. ": " .. message)
	end

	return true
end