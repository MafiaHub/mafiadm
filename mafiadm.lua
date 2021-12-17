-- MafiaDM gamemode
-- Originally written by NanobotZ
-- Thanks a lot to Asa for helping with sounds and models!

--[[
	How to set up:
	1. Update server.json to load mafiadm.lua
	2. Set mission name in server.json to "tutorial"
	3. Update mapload.lua file to specify which settings to load from cfg folder
--]]

-- Load helpers
local helpers = require("helpers")
local zac = require("anticheat")

-- Load global settings first
local Settings = require("settings")

-- Replace them with per-mission settings
Settings = helpers.tableAssign(Settings, require("mapload"))

---------------ENUMS---------------
local VirtualKeys = require("virtual_keys")
local Modes = require("modes")

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

local BEEP_A0 = 1.04865151217746
local BEEP_A1 = 0.244017811416199
local BEEP_A2 = 1.76379778668885

local teams = {
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

local game = {
	state = GameStates.WAITING_FOR_PLAYERS,
	roundTime = 0.0,
	weaponPickups = {},
	buyMenuPages = {},
	bomb = {
		pos = {0.0, 0.0, 0.0},
		offset = {0.0, 2.5, 0.0},
		pickupId = 0,
		player = nil,
		timeToPlant = 0.0,
		plantTime = 0.0,
		timeToDefuse = 0.0,
		timeToTick = 0.0,
		model = Settings.BOMB.MODEL,
		defuser = nil
	},
	skipTeamReq = false,
}

-- TODO better handle disconnects
-- TODO improve PlayerState setting/tracking
-- IDEA move all strings to Settings so server owners can translate

-- TODO anti-speedhack and anti-playersetpos?

local emptyGame = nil

local curTime = 0.0
local waitTime = 0.0

local players = {}

local cmds = {}


---------------FUNCTIONS---------------

local function inTeamColor(team, text)
	return team.msgColor .. (text or team.name) .. "#FFFFFF"
end
teams.none.inTeamColor = inTeamColor
teams.tt.inTeamColor = inTeamColor
teams.ct.inTeamColor = inTeamColor

local function sendSelectTeamMessage(player)
	if Settings.TEAMS.AUTOBALANCE == true then
		return
	end

	sendClientMessage(player.id, "Please press a corresponding number key to select an option:")
	sendClientMessage(player.id, "1 : Choose " .. teams.tt:inTeamColor() .. " team (" .. teams.tt.numPlayers .. " players).") -- IDEA refresh when numPlayers changes ?
	sendClientMessage(player.id, "2 : Choose " .. teams.ct:inTeamColor() .. " team (" .. teams.ct.numPlayers .. " players).") -- IDEA refresh when numPlayers changes ?
	sendClientMessage(player.id, "3 : Auto-assign team.")
end

local function spectate(player, order) -- TODO fix :)
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

		local playerToSpectate = players[plys[spectating]]

		if player.spectating ~= playerToSpectate then
			sendClientMessage(player.id, "Now spectating " .. playerToSpectate.team:inTeamColor(humanGetName(playerToSpectate.id)))
		end

		player.spectating = playerToSpectate
		player.state = PlayerStates.SPECTATING
		cameraFollow(player.id, playerToSpectate.id)

		return true
	end
end

local function sendClientMessageToAllWithStates(text, ...)
	for _, player in pairs(players) do
		if helpers.tableHasValue(arg, player.state) then
			sendClientMessage(player.id, text)
		end
	end
end

local function addHudAnnounceMessage(player, msg)
	if player.hudAnnounceMessage then
		player.hudAnnounceMessage = player.hudAnnounceMessage .. "~" .. msg
	else
		player.hudAnnounceMessage = msg
	end
end

local function getOppositeTeam(team)
	return team == teams.ct and teams.tt or teams.ct
end

local function addPlayerMoney(player, money, msg, color)
	player.money = player.money + money

	if player.money > Settings.PLAYER_MAX_MONEY then
		player.money = Settings.PLAYER_MAX_MONEY
	end

	hudAddMessage(player.id,
		string.format("%s %d$", (msg or "Awarded money:"), tostring(money)),
		color or helpers.rgbToColor(255, 255, 255))
end

local function teamAddPlayerMoney(team, money, text)
	for _, player in pairs(team.players) do
		addPlayerMoney(player, money, text)
	end
end

local function teamWin(team, bombPlanted, bombExploded)
	if team == teams.none then
		sendClientMessageToAll("It's a draw!")
		sendClientMessageToAll(string.format("%s %d : %d %s", teams.tt:inTeamColor(), teams.tt.score, teams.ct.score, teams.ct:inTeamColor()))
		local ctPaymentInfo = Settings.ROUND_PAYMENT.ct[team.winRow > 5 and 5 or team.winRow]
		local ttPaymentInfo = Settings.ROUND_PAYMENT.tt[team.winRow > 5 and 5 or team.winRow]
		teamAddPlayerMoney(teams.tt, ctPaymentInfo.loss, "You've got")
		teamAddPlayerMoney(teams.tt, ttPaymentInfo.loss, "You've got")
		return
	end
	team.score = team.score + 1

	sendClientMessageToAll(team:inTeamColor() .. " win!")
	sendClientMessageToAll(string.format("%s %d : %d %s", teams.tt:inTeamColor(), teams.tt.score, teams.ct.score, teams.ct:inTeamColor()))


	local oppositeTeam = getOppositeTeam(team)

	if not team.wonLast then
		team.wonLast = true
		team.winRow = 1
		oppositeTeam.wonLast = false
		oppositeTeam.winRow = 0
	else
		team.winRow = team.winRow + 1
	end

	local paymentInfo = Settings.ROUND_PAYMENT[team.shortName][team.winRow > 5 and 5 or team.winRow]
	local winMoney = paymentInfo.win + (bombPlanted and paymentInfo.bomb_plant or 0) + (bombExploded and paymentInfo.bomb_detonate or 0)
	for _, player in pairs(team.players) do
		addPlayerMoney(player, winMoney, "You've won the round and got")
	end

	paymentInfo = Settings.ROUND_PAYMENT[oppositeTeam.shortName][team.winRow > 5 and 5 or team.winRow] -- using team here intentionally to get correct loss
	local lossMoney = paymentInfo.loss + (bombPlanted and paymentInfo.bomb_plant or 0) + (bombExploded and paymentInfo.bomb_detonate or 0)
	for _, player in pairs(oppositeTeam.players) do
		addPlayerMoney(player, lossMoney, "You've lost the round and got")
	end


	if team.score >= Settings.MAX_TEAM_SCORE then
		game.state = GameStates.AFTER_GAME
		waitTime = Settings.WAIT_TIME.END_GAME + curTime
	else
		game.state = GameStates.AFTER_ROUND
		waitTime = Settings.WAIT_TIME.END_ROUND + curTime
	end
end

local function stopDefusing()
	if game.bomb.defuser and game.bomb.defuser.state == PlayerStates.IN_ROUND then
		humanLockControls(game.bomb.defuser.id, false)
		-- IDEA maybe send message to team that bomb is not being defused?
	end

	game.bomb.timeToDefuse = 0
	game.bomb.defuser = nil
end

local function removePlayerFromTeam(player)
	if not player.team then
		return
	end

	player.team.numPlayers = player.team.numPlayers - 1
	player.team.players[player.id] = nil
	player.team = nil
end

local function assignPlayerToTeam(player, team)
	removePlayerFromTeam(player)

	if Settings.TEAMS.AUTOBALANCE == true and team == teams.none then
		team = teams.ct.numPlayers < teams.tt.numPlayers and teams.ct or teams.tt
	end

	team.numPlayers = team.numPlayers + 1
	team.players[player.id] = player
	player.team = team
	player.state = PlayerStates.WAITING_FOR_ROUND

	sendClientMessage(player.id, "You are assigned to team " .. team:inTeamColor() .. "!")


	spectate(player, 1)
end

local function autoAssignPlayerToTeam(player)
	local team = teams.ct.numPlayers < teams.tt.numPlayers and teams.ct or teams.tt
	assignPlayerToTeam(player, team)
end

local function switchPlayerTeam(player)
	if player.team == teams.none then
		return
	end

	assignPlayerToTeam(player, getOppositeTeam(player.team))
end

local function spawnOrTeleportPlayer(player, optionalSpawnPos, optionalSpawnDir, optionalModel)
	local spawnPos = { 0.0, 0.0, 0.0 }

	if not optionalSpawnPos then
		local collides = true
		while collides do
			collides = false
			spawnPos = helpers.randomPointInCuboid(player.team.spawnArea)

			for _, player2 in pairs(player.team.players) do
				if player2.id ~= player.id and player2.state == PlayerStates.IN_ROUND then
					if helpers.distanceSquared(spawnPos, humanGetPos(player2.id)) < Settings.SPAWN_RANGE_SQUARED then
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
		humanSetModel(player.id, optionalModel or helpers.randomTableElem(player.team.models))
		humanSpawn(player.id)

		if not player.isSpawned or player.state == PlayerStates.DEAD then
			inventoryAddWeaponDefault(player.id, 6) -- Colt Detective Special -- IDEA add default weapons option to game_settings?
		end

		player.isSpawned = true
	elseif humanGetHealth(player.id) < 100.0 then
		humanSetHealth(player.id, 100.0)
	end
end

local function teamCountAlivePlayers(team)
	local count = 0

	for _, player in pairs(team.players) do
		if player.state == PlayerStates.IN_ROUND then
			count = count + 1
		end
	end

	return count
end

local function despawnBomb()
	if game.bomb.pickupId == 0 then
		return
	end

	if game.bomb.player then
		pickupDetach(game.bomb.pickupId)
		game.bomb.player = nil
	end

	pickupDestroy(game.bomb.pickupId)
	game.bomb.pickupId = 0
	game.bomb.plantTime = 0
	game.bomb.pos = { 0.0, 0.0, 0.0 }
	game.bomb.defuser = nil
	game.bomb.timeToDefuse = 0
	game.bomb.timeToPlant = 0
	game.bomb.timeToTick = 0
end

local function prepareBuyMenu()
	local pages = {}
	for _, item in pairs(Settings.WEAPONS) do
		if item.page then
			if not pages[item.page] then
				pages[item.page] = {}
			end

			table.insert(pages[item.page], item)
		end
	end

	game.buyMenuPages = pages
end

local function clearUpPickups()
	for _, pickupId in ipairs(game.weaponPickups) do
		pickupDestroy(pickupId)
	end
	game.weaponPickups = {}
end

local function sendBuyMenuMessage(player)
	local key = 1

	local playerPage = player.buyMenuPage
	player.buyMenuPage = {}

	-- IDEA clear chat?
	sendClientMessage(player.id, "\n\n")
	sendClientMessage(player.id, string.format("Your money: #00CE00%d$#FFFFFF", player.money))

	if player.isInMainBuyMenu then
		for _, pageName in ipairs(Settings.PAGES_ORDER) do
			sendClientMessage(player.id, string.format("%d: %s", key, pageName))
			player.buyMenuPage[key] = game.buyMenuPages[pageName]
			key = key + 1
		end
	else
		sendClientMessage(player.id, "0: Go back")
		for _, item in ipairs(playerPage) do
			if helpers.tableHasValue(item.canBuy, player.team.shortName) then
				sendClientMessage(player.id, string.format("%d: %s - %s%d$#FFFFFF", key, item.name, item.cost > player.money and "#FF0000" or "#FFFFFF", item.cost))
				player.buyMenuPage[key] = item
				key = key + 1
			end
		end
	end
end

local function prepareSpawnAreaCheck(team)
	team.spawnAreaCheck = {
		{ team.spawnArea[1][1], team.spawnArea[1][2] - 5, team.spawnArea[1][3] },
		{ team.spawnArea[2][1], team.spawnArea[2][2] + 5, team.spawnArea[2][3] }
	}
end

local function playSoundRanged(player, pos, soundSetting)
	local ppos = player.isSpawned and humanGetPos(player.id) or humanGetCameraPos(player.id)
	local volume = helpers.remapValue(helpers.distance(ppos, pos), soundSetting.RANGE, 0, 0, 1)
	if volume > 0.0 then
		playSound(player.id, soundSetting.FILE, pos, soundSetting.RANGE, volume, false)
	end
end

local function dropBomb(player)
	if player.hasBomb then
		player.timeToPickupBomb = curTime + Settings.WAIT_TIME.PICKUP_BOMB

		local pos = helpers.addRandomVectorOffset(humanGetPos(player.id), {1.0, 0, 1.0}) -- IDEA don't use random, spawn it on a circle circumerence
		pickupDetach(game.bomb.pickupId)
		pickupSetPos(game.bomb.pickupId, pos)

		game.bomb.player = nil
		player.hasBomb = false

		print(humanGetName(player.id) .. " dropped bomb")
	end
end

local function updateGame()
	if game.state == GameStates.WAITING_FOR_PLAYERS then
		despawnBomb()

		if (teams.tt.numPlayers >= Settings.MIN_PLAYER_AMOUNT_PER_TEAM and teams.ct.numPlayers >= Settings.MIN_PLAYER_AMOUNT_PER_TEAM) or game.skipTeamReq then
			game.skipTeamReq = false
			for _, player in pairs(players) do
				if player.team ~= teams.none then
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

			if Settings.MODE == Modes.BOMB then
				local bombPlayer = helpers.randomTableElem(teams.tt.players)
				game.bomb.pickupId = pickupCreate(humanGetPos(bombPlayer.id), game.bomb.model)
				game.bomb.player = bombPlayer
				pickupAttachTo(game.bomb.pickupId, bombPlayer.id, game.bomb.offset)
				bombPlayer.hasBomb = true
			end

			game.state = GameStates.BUY_TIME
			waitTime = Settings.WAIT_TIME.BUYING + curTime
		end
	elseif game.state == GameStates.BUY_TIME then
		for _, player in pairs(players) do
			addHudAnnounceMessage(player, string.format("Buy time - %.2fs", waitTime - curTime))

			if player.state == PlayerStates.IN_ROUND then
				if not helpers.isPointInCuboid(humanGetPos(player.id), player.team.spawnAreaCheck) then
					--sendClientMessage(player.id, "Don't leave the spawn area during buy time please :)")
					spawnOrTeleportPlayer(player)
				end
			end
		end

		if curTime > waitTime then
			for _, player in pairs(players) do
				player.buyMenuPage = nil
			end

			game.state = GameStates.ROUND
			waitTime = Settings.WAIT_TIME.ROUND + curTime
		end
	elseif game.state == GameStates.ROUND then
		local playTick = false
		if game.bomb.plantTime ~= 0 and curTime >= game.bomb.timeToTick then
			local x = (curTime - game.bomb.plantTime) / Settings.WAIT_TIME.BOMB;
			local n = (BEEP_A1 * x) + (BEEP_A2 * x ^ 2);
			local bps = BEEP_A0 * math.exp(n);

			game.bomb.timeToTick = curTime + ((1000.0 / bps) / 1000.0);
			playTick = true
		end

		for _, player in pairs(players) do
			if game.bomb.plantTime ~= 0 then
				if playTick then
					playSoundRanged(player, game.bomb.pos, Settings.SOUNDS.BOMB_TICK)
				end

				addHudAnnounceMessage(player, "Bomb is planted!")
			else
				addHudAnnounceMessage(player, string.format("%.2fs", waitTime - curTime))
			end
		end

		if game.bomb.plantTime == 0 and curTime > waitTime then
			print("win cause of game time ended")

			-- we decide on winner based on MODE
			if Settings.MODE == Modes.BOMB then
				teamWin(teams.ct, game.bomb.plantTime ~= 0, false)
			elseif Settings.MODE == Modes.TDM then
				local ttScore = teamCountAlivePlayers(teams.tt)
				local ctScore = teamCountAlivePlayers(teams.ct)

				if ttScore > ctScore then
					teamWin(teams.tt, false, false)
				elseif ctScore > ttScore then
					teamWin(teams.ct, false, false)
				else
					teamWin(teams.none, false, false)
				end
			end
		end
	elseif game.state == GameStates.AFTER_ROUND then
		if waitTime > curTime then
			for _, player in pairs(players) do
				addHudAnnounceMessage(player, string.format("Next round in %.2fs!", waitTime - curTime))
			end
		else
			clearUpPickups()

			despawnBomb()

			game.state = GameStates.WAITING_FOR_PLAYERS
			waitTime = Settings.WAIT_TIME.BUYING + curTime
		end
	elseif game.state == GameStates.AFTER_GAME then
		if waitTime > curTime then
			for _, player in pairs(players) do
				addHudAnnounceMessage(player, string.format("%s win! Next game in %.2fs!", teams.tt.score > teams.ct.score and teams.tt.name or teams.ct.name, waitTime - curTime))
			end
		else
			teams.tt.score = 0
			teams.tt.winRow = 0
			teams.tt.wonLast = false

			teams.ct.score = 0
			teams.ct.winRow = 0
			teams.ct.wonLast = false

			clearUpPickups()

			for _, player in pairs(players) do
				player.money = Settings.PLAYER_STARTING_MONEY
				if player.isSpawned then
					humanDespawn(player.id)
					player.isSpawned = false
				end
				assignPlayerToTeam(player, teams.none)
				player.state = PlayerStates.SELECTING_TEAM
				sendSelectTeamMessage(player)
			end

			game = helpers.deepCopy(emptyGame)
			game.state = GameStates.WAITING_FOR_PLAYERS
		end
	end
end

local function updateBomb()
	if game.bomb.plantTime ~= 0 then -- I know that I'm not really using onPlayerInsidePickupRadius, because it's called only for the first player in the radius, and if there's more than one inside radius - it can break the intended logic
		if game.bomb.defuser then
			local defuser = game.bomb.defuser
			if (defuser.holdsDefusePlantKey and helpers.distanceSquared(game.bomb.pos, humanGetPos(game.bomb.defuser.id)) <= Settings.DEFUSE_RANGE_SQUARED) then
				if curTime >= game.bomb.timeToDefuse then
					humanLockControls(defuser.id, false)

					local defuserPos = humanGetPos(defuser.id)
					for _, player in pairs(players) do
						playSoundRanged(player, defuserPos, Settings.SOUNDS.BOMB_DEFUSED)
					end

					despawnBomb()

					if game.state == GameStates.ROUND then
						print("win cause of defuse")
						teamWin(teams.ct, true, false)
						sendClientMessageToAll("Bomb defused, " .. teams.ct:inTeamColor() .. " win!")
					else
						sendClientMessageToAll("Bomb defused!")
					end
				else
					addHudAnnounceMessage(defuser, "Defusing!")
					--humanLockControls(defuser.id, true)
				end
			else
				stopDefusing()
			end
		end

		if not game.bomb.defuser then
			for _, player in pairs(teams.ct.players) do
				local dist = helpers.distanceSquared(game.bomb.pos, humanGetPos(player.id))
				if (dist <= Settings.DEFUSE_RANGE_SQUARED) then
					if player.holdsDefusePlantKey then
						local defusingTime = player.hasDefuseKit and Settings.WAIT_TIME.DEFUSING.KIT or Settings.WAIT_TIME.DEFUSING.NO_KIT
						game.bomb.timeToDefuse = curTime + defusingTime
						game.bomb.defuser = player
						humanLockControls(player.id, true)

						local defuserPos = humanGetPos(player.id)
						for _, player2 in pairs(players) do
							playSoundRanged(player2, defuserPos, Settings.SOUNDS.START_DEFUSE)
						end

						break
					else
						addHudAnnounceMessage(player, "Hold ALT key to start defusing!")
					end
				end
			end
		end

		if game.bomb.plantTime ~= 0 and curTime - game.bomb.plantTime > Settings.WAIT_TIME.BOMB then
			if game.state == GameStates.ROUND then
				print("win cause of boom")
				teamWin(teams.tt, true, true)
				sendClientMessageToAll("Bomb exploded, " .. teams.tt:inTeamColor() .. " win!")
			else
				sendClientMessageToAll("Bomb exploded!")
			end

			createExplosion(game.bomb.pos, 0, 0)

			for _, player in pairs(players) do
				playSoundRanged(player, game.bomb.pos, Settings.SOUNDS.EXPLOSION)

				if player.state == PlayerStates.IN_ROUND then
					local distance = helpers.distance(humanGetPos(player.id), game.bomb.pos)
					if distance < Settings.BOMB.BLAST_RADIUS then
						local damage = helpers.remapValue(distance, Settings.BOMB.BLAST_RADIUS, 0, 0, Settings.BOMB.BLAST_FORCE)
						local health = humanGetHealth(player.id)
						local newHealth = health - damage

						if newHealth < 0 then
							humanDie(player.id)
						else
							humanSetHealth(player.id, health - damage)
						end
					end
				end
			end

			despawnBomb()
		end
	end
end

local function updatePlayers()
	for _, player in pairs(players) do
		if player.isSpawned and player.state == PlayerStates.IN_ROUND then
			local curPos = humanGetPos(player.id)
			local curDir = humanGetDir(player.id)

			if helpers.compareVectors(player.lastPos, curPos) and helpers.compareVectors(player.lastDir, curDir) then
				-- player hasn't moved
			else
				player.timeIdleStart = curTime
			end

			player.lastPos = curPos
			player.lastDir = curDir

			local playerWeaponId = inventoryGetCurrentItem(player.id).weaponId
			if helpers.tableHasValue(Settings.HEAVY_WEAPONS, playerWeaponId) then
				humanSetSpeed(player.id, Settings.HEAVY_WEAPONS_RUN_SPEED)
			elseif helpers.tableHasValue(Settings.LIGHT_WEAPONS, playerWeaponId) then
				humanSetSpeed(player.id, Settings.LIGHT_WEAPONS_RUN_SPEED)
			else
				humanSetSpeed(player.id, Settings.NORMAL_WEAPONS_RUN_SPEED)
			end
		end

		if player.hasBomb then
			if curTime - player.timeIdleStart > Settings.WAIT_TIME.AFK_DROP_BOMB then
				dropBomb(player)
			else
				for _, cuboid in pairs(Settings.BOMBSITES) do
					if player.state == PlayerStates.IN_ROUND and helpers.isPointInCuboid(humanGetPos(player.id), cuboid) then
						player.isInBombsite = true

						if player.holdsDefusePlantKey then
							if game.bomb.timeToPlant == 0 then
								game.bomb.timeToPlant = curTime + Settings.WAIT_TIME.PLANT_BOMB
								humanLockControls(player.id, true)

								local planterPos = humanGetPos(player.id)
								for _, player2 in pairs(players) do
									playSoundRanged(player2, planterPos, Settings.SOUNDS.START_PLANT)
								end
							elseif curTime > game.bomb.timeToPlant then
								pickupDetach(game.bomb.pickupId)

								local pos = humanGetPos(player.id)
								pos[2] = pos[2] + 0.5
								pickupSetPos(game.bomb.pickupId, pos)
								game.bomb.pos = pos

								player.hasBomb = false
								game.bomb.timeToPlant = 0
								game.bomb.plantTime = curTime
								game.bomb.player = nil

								waitTime = curTime + Settings.WAIT_TIME.BOMB

								sendClientMessageToAll("Bomb has been planted!")
								humanLockControls(player.id, false)
							else
								addHudAnnounceMessage(player, "Planting!")
							end
						else
							game.bomb.timeToPlant = 0
							humanLockControls(player.id, false)
							addHudAnnounceMessage(player, "Hold ALT key to plant the bomb!")
						end

						break
					else
						player.isInBombsite = false
					end
				end
			end
		end

		if player.hudAnnounceMessage then
			hudAnnounce(player.id, player.hudAnnounceMessage, 1)
			player.hudAnnounceMessage = nil
		end
	end
end

local function findWeaponInfoInSettings(weaponId)
	for _, info in pairs(Settings.WEAPONS) do
		if info.weaponId and info.weaponId == weaponId then
			return info
		end
	end

	return nil
end

local function handleDyingOrDisconnect(playerId, inflictorId, damage, hitType, bodyPart, disconnected)
	local player = players[playerId]
	local inflictor = players[inflictorId]

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

	if game.bomb.defuser and game.bomb.defuser.id == player.id then
		stopDefusing()
	end

	player.holdsDefusePlantKey = false

	dropBomb(player)

	if player.hasDefuseKit then
		player.hasDefuseKit = false
		local pos = helpers.addRandomVectorOffset(humanGetPos(player.id), {0.5, 0, 0.5})
		local pickupId = pickupCreate(pos, Settings.DEFUSE_KIT_MODEL)
		table.insert(game.weaponPickups, pickupId)
	end

	for _, item in pairs(inventory) do
		local weaponId = item.weaponId
		if weaponId > 1 and inventoryRemoveWeapon(playerId, weaponId) then
			local pos = helpers.addRandomVectorOffset(humanGetPos(player.id), {1.0, 0.0, 1.0})
			local pickupId = weaponDropCreate(weaponId, pos, 2147483647, item.ammoLoaded, item.ammoHidden)
			table.insert(game.weaponPickups, pickupId)
		end
	end

	if not disconnected then
		sendClientMessageToAll(inflictor.team:inTeamColor(humanGetName(inflictor.id)) .. " killed " .. player.team:inTeamColor(humanGetName(player.id)))
	end

	if game.state == GameStates.ROUND then
		local deadPlayersCount = 0
		for _, player in pairs(player.team.players) do
			if player.state == PlayerStates.DEAD or player.state == PlayerStates.SPECTATING then
				deadPlayersCount = deadPlayersCount + 1
			end
		end

		if deadPlayersCount == player.team.numPlayers then
			if player.team == teams.tt and game.bomb.plantTime ~= 0 then
				--brain farted, dunno
			else
				print("win cause of enemy team dead")
				teamWin(player.team == teams.ct and teams.tt or teams.ct, game.bomb.plantTime ~= 0, false)
			end
		end
	end
end

---------------COMMANDS---------------

function cmds.pos(player, ...)
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

function cmds.liskip(player, ...)
	waitTime = curTime
end

function cmds.ligo(player, ...)
	game.skipTeamReq = true
end

function cmds.moolah(player, ...)
	arg = {...}
	if #arg > 0 then
		local money = tonumber(arg[1])
		if money and money > 0 then
			addPlayerMoney(player, money, "You cheeky wanker, you got", helpers.rgbToColor(255, 0, 255))
		end
	end
end

function cmds.dropbomb(player, ...)
	dropBomb(player)
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
    curTime = getTime() * 0.001

	updateGame()
	updateBomb()
	updatePlayers()
	zac.validateStats()
end

---@diagnostic disable-next-line: lowercase-global
function onScriptStart()
	changeMission(Settings.MISSION)
	prepareBuyMenu()
	prepareSpawnAreaCheck(teams.tt)
	prepareSpawnAreaCheck(teams.ct)

	emptyGame = helpers.deepCopy(game)
	print("MafiaDM was initialised!\n")
end

---@diagnostic disable-next-line: lowercase-global
function onPlayerWeaponDrop(playerId, pickupId)
	table.insert(game.weaponPickups, pickupId)
	return true
end

---@diagnostic disable-next-line: lowercase-global
function onPlayerConnected(playerId)
	local welcomeMessage = string.format('#FF0000[GM]#FFFFFF player #00FF00**%s** #FFFFFFhas connected to the server :)', humanGetName(playerId))
	--sendClientMessageToAllWithStates(welcomeMessage, PlayerStates.SELECTING_TEAM, PlayerStates.DEAD, PlayerStates.WAITING_FOR_ROUND, PlayerStates.SPECTATING)
	sendClientMessageToAll(welcomeMessage)

	local player = {
		id = playerId,
		state = PlayerStates.SELECTING_TEAM,
		team = teams.none,
		money = Settings.PLAYER_STARTING_MONEY,
		isSpawned = false,
		hasDefuseKit = false,
		holdsDefusePlantKey = false,
		hasBomb = false,
		isInBombsite = false,
		cancelDespawn = false,
		buyMenuPage = nil,
		spectating = nil,
		lastPos = nil,
		lastDir = nil,
		timeIdleStart = nil,
		timeToPickupBomb = 0,
		hudAnnounceMessage = nil,
		kills = 0
	}
	players[playerId] = player
	teams.none[playerId] = player

	sendClientMessage(playerId, "#FFFF00 Welcome to MafiaDM")

	if Settings.TEAMS.AUTOBALANCE == true then
		assignPlayerToTeam(player, teams.none)
	else
		sendSelectTeamMessage(player)
	end

	zac.buildPlayer(playerId)
    cameraInterpolate(playerId, Settings.WELCOME_CAMERA.START.POS, Settings.WELCOME_CAMERA.START.ROT, Settings.WELCOME_CAMERA.STOP.POS, Settings.WELCOME_CAMERA.STOP.ROT, Settings.WELCOME_CAMERA.TIME)
end

---@diagnostic disable-next-line: lowercase-global
function onPlayerDisconnected(playerId)
	sendClientMessageToAll("Player " .. players[playerId].team:inTeamColor(humanGetName(playerId)) .. " has disconnected.")

	handleDyingOrDisconnect(playerId, nil, nil, nil, nil, true)
	onPlayerDie(playerId)

	zac.clearPlayer(playerId)
	removePlayerFromTeam(players[playerId])
	players[playerId] = nil
end

---@diagnostic disable-next-line: lowercase-global
function onPlayerHit(playerId, inflictorId, damage, hitType, bodyPart)
	print("damage " .. tostring(damage))

	if game.state == GameStates.BUY_TIME then
		return 0
	end

    if players[playerId].team == players[inflictorId].team then
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
	local player = players[playerId]

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
	local player = players[playerId]

	if pickupId == game.bomb.pickupId then
		if player.state == PlayerStates.IN_ROUND
			and player.team == teams.tt
			and not player.hasBomb
			and game.bomb.plantTime == 0
			and (curTime - player.timeIdleStart < Settings.WAIT_TIME.AFK_DROP_BOMB)
			and curTime > player.timeToPickupBomb then

			print(humanGetName(player.id) .. " picked up bomb")
			pickupAttachTo(pickupId, playerId, game.bomb.offset)
			game.bomb.player = player
			player.hasBomb = true
		end
	elseif player.state == PlayerStates.IN_ROUND and player.team == teams.ct and not player.hasDefuseKit then
		player.hasDefuseKit = true
		pickupDestroy(pickupId)
	end
end

---@diagnostic disable-next-line: lowercase-global
function onPlayerKeyPress(playerId, isDown, key)
	local player = players[playerId]

	--print(string.format("player %d state %d key %d isDown %s", player.id, player.state, key, tostring(isDown)))

	player.timeIdleStart = curTime

	if player.state == PlayerStates.SELECTING_TEAM then
		if isDown then
			if key == VirtualKeys.N1 then
				assignPlayerToTeam(player, teams.tt)
			elseif key == VirtualKeys.N2 then
				assignPlayerToTeam(player, teams.ct)
			elseif key == VirtualKeys.N3 then
				autoAssignPlayerToTeam(player)
			end
		end
	elseif game.state == GameStates.BUY_TIME then
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
								if weapon.special == "defuse" then
									if player.hasDefuseKit then
										hudAddMessage(player.id, "Couldn't buy this weapon!", helpers.rgbToColor(255, 38, 38))
									else
										player.money = player.money - weapon.cost
										bought = true
										player.hasDefuseKit = true
										hudAddMessage(player.id, string.format("Bought %s for %d$, money left: %d$", weapon.name, weapon.cost, player.money), helpers.rgbToColor(34, 207, 0))
									end
								end
							else
								if inventoryAddWeaponDefault(player.id, weapon.weaponId) then
									player.money = player.money - weapon.cost
									bought = true
									hudAddMessage(player.id, string.format("Bought %s for %d$, money left: %d$", weapon.name, weapon.cost, player.money), helpers.rgbToColor(34, 207, 0))
								else
									hudAddMessage(player.id, "Couldn't buy this weapon!", helpers.rgbToColor(255, 38, 38))
								end
							end

							if bought then
								sendBuyMenuMessage(player)
							end
						else
							hudAddMessage(player.id, string.format("Not enough money to buy this weapon, weapon: %d$, you: %d$!", weapon.cost, player.money), helpers.rgbToColor(255, 38, 38))
						end
					end
				end
			end
		end
	elseif player.state == PlayerStates.IN_ROUND then
		if (key == VirtualKeys.Menu) then
			--print(string.format("player %d  team %s  key %d  isDown %s", player.id, player.team.name, key, tostring(isDown)))
			player.holdsDefusePlantKey = isDown
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
end

---@diagnostic disable-next-line: lowercase-global
function onPlayerChat(playerId, message)
	if #message > 0 and helpers.stringCharAt(message, 1) == "/" then
		message = message:sub(2)
		local splits = helpers.stringSplit(message)
		local cmd = cmds[splits[1]]

		if cmd then
			local player = players[playerId]
			cmd(player, table.unpack(helpers.tableSlice(splits, 2)))
		end
	else
		local player = players[playerId]
		sendClientMessageToAll(player.state == PlayerStates.DEAD and "DEAD " or "" .. player.team:inTeamColor(humanGetName(player.id)) .. ": " .. message)
	end

	return true
end