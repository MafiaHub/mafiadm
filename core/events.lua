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

	InitMode(Settings.MODE)

    -- Set up models for non-team gamemodes
    if not Settings.TEAMS.NONE.MODELS then
        Settings.TEAMS.NONE.MODELS = Helpers.tableAssign(Settings.TEAMS.TT.MODELS, Settings.TEAMS.CT.MODELS)
        Teams.none.models = Settings.TEAMS.NONE.MODELS
    end

	EmptyGame = Helpers.deepCopy(Game)
	startGame()
	Game.init()
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

	local welcomeMessage = string.format('#FF0000[GM]#FFFFFF Player #00FF00**%s** #FFFFFFhas connected to the server :)', humanGetName(playerId))
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
		kills = 0,
		deadTime = 0.0
	}

	player = Helpers.tableAssign(player, Game.initPlayer())
	Players[playerId] = player
	Teams.none[playerId] = player

	sendClientMessage(playerId, "#FFFF00 Welcome to MafiaDM")

	if Settings.TEAMS.AUTOASSIGN == true then
		assignPlayerToTeam(player, Teams.none)
	else
		sendSelectTeamMessage(player)
	end

	zac.buildPlayer(playerId)

	if Settings.WELCOME_CAMERA then
    	cameraInterpolate(playerId, Settings.WELCOME_CAMERA.START.POS, Settings.WELCOME_CAMERA.START.ROT, Settings.WELCOME_CAMERA.STOP.POS, Settings.WELCOME_CAMERA.STOP.ROT, Settings.WELCOME_CAMERA.TIME)
	end

	if Game.state == GameStates.WAITING_FOR_PLAYERS then
		local numPlayers = Helpers.tableCountFields(Players)

		if numPlayers < Settings.MIN_PLAYER_AMOUNT_PER_TEAM*2 then
			sendClientMessageToAll(string.format('#FF0000[GM]#FFFFFF We need %d more players to start the round!', Settings.MIN_PLAYER_AMOUNT_PER_TEAM*2 - numPlayers))
		end
    elseif Settings.PLAYER_HOTJOIN then
        spawnPlayer(player)
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
