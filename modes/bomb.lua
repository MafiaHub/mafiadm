-- Load helpers
local helpers = require("helpers")

local BEEP_A0 = 1.04865151217746
local BEEP_A1 = 0.244017811416199
local BEEP_A2 = 1.76379778668885

local function despawnBomb()
	if Game.bomb.pickupId == 0 then
		return
	end

	if Game.bomb.player then
		pickupDetach(Game.bomb.pickupId)
		Game.bomb.player = nil
	end

	pickupDestroy(Game.bomb.pickupId)
	Game.bomb.pickupId = 0
	Game.bomb.plantTime = 0
	Game.bomb.pos = { 0.0, 0.0, 0.0 }
	Game.bomb.defuser = nil
	Game.bomb.timeToDefuse = 0
	Game.bomb.timeToPlant = 0
	Game.bomb.timeToTick = 0
end

local function dropBomb(player)
	if player.hasBomb then
		player.timeToPickupBomb = CurTime + Settings.WAIT_TIME.PICKUP_BOMB

		local pos = helpers.addRandomVectorOffset(humanGetPos(player.id), {1.0, 0, 1.0}) -- IDEA don't use random, spawn it on a circle circumerence
		pickupDetach(Game.bomb.pickupId)
		pickupSetPos(Game.bomb.pickupId, pos)

		Game.bomb.player = nil
		player.hasBomb = false

		print(humanGetName(player.id) .. " dropped bomb")
	end
end

local function teamWin(team, bombPlanted, bombExploded)
	team.score = team.score + 1

	sendClientMessageToAll(team:inTeamColor() .. " win!")
	sendClientMessageToAll(string.format("%s %d : %d %s", Teams.tt:inTeamColor(), Teams.tt.score, Teams.ct.score, Teams.ct:inTeamColor()))

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
		Game.state = GameStates.AFTER_GAME
		WaitTime = Settings.WAIT_TIME.END_GAME + CurTime
	else
		Game.state = GameStates.AFTER_ROUND
		WaitTime = Settings.WAIT_TIME.END_ROUND + CurTime
	end
end

local function stopDefusing()
	if Game.bomb.defuser and Game.bomb.defuser.state == PlayerStates.IN_ROUND then
		humanLockControls(Game.bomb.defuser.id, false)
		-- IDEA maybe send message to team that bomb is not being defused?
	end

	Game.bomb.timeToDefuse = 0
	Game.bomb.defuser = nil
end

local function updateBomb()
	if Game.bomb.plantTime ~= 0 then -- I know that I'm not really using onPlayerInsidePickupRadius, because it's called only for the first player in the radius, and if there's more than one inside radius - it can break the intended logic
		if Game.bomb.defuser then
			local defuser = Game.bomb.defuser
			if (defuser.holdsDefusePlantKey and helpers.distanceSquared(Game.bomb.pos, humanGetPos(Game.bomb.defuser.id)) <= Settings.DEFUSE_RANGE_SQUARED) then
				if CurTime >= Game.bomb.timeToDefuse then
					humanLockControls(defuser.id, false)

					local defuserPos = humanGetPos(defuser.id)
					for _, player in pairs(Players) do
						playSoundRanged(player, defuserPos, Settings.SOUNDS.BOMB_DEFUSED)
					end

					despawnBomb()

					if Game.state == GameStates.ROUND then
						print("win cause of defuse")
						teamWin(Teams.ct, true, false)
						sendClientMessageToAll("Bomb defused, " .. Teams.ct:inTeamColor() .. " win!")
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

		if not Game.bomb.defuser then
			for _, player in pairs(Teams.ct.players) do
				local dist = helpers.distanceSquared(Game.bomb.pos, humanGetPos(player.id))
				if (dist <= Settings.DEFUSE_RANGE_SQUARED) then
					if player.holdsDefusePlantKey then
						local defusingTime = player.hasDefuseKit and Settings.WAIT_TIME.DEFUSING.KIT or Settings.WAIT_TIME.DEFUSING.NO_KIT
						Game.bomb.timeToDefuse = CurTime + defusingTime
						Game.bomb.defuser = player
						humanLockControls(player.id, true)

						local defuserPos = humanGetPos(player.id)
						for _, player2 in pairs(Players) do
							playSoundRanged(player2, defuserPos, Settings.SOUNDS.START_DEFUSE)
						end

						break
					else
						addHudAnnounceMessage(player, "Hold ALT key to start defusing!")
					end
				end
			end
		end

		if Game.bomb.plantTime ~= 0 and CurTime - Game.bomb.plantTime > Settings.WAIT_TIME.BOMB then
			if Game.state == GameStates.ROUND then
				print("win cause of boom")
				teamWin(Teams.tt, true, true)
				sendClientMessageToAll("Bomb exploded, " .. Teams.tt:inTeamColor() .. " win!")
			else
				sendClientMessageToAll("Bomb exploded!")
			end

			createExplosion(Game.bomb.pos, 0, 0)

			for _, player in pairs(Players) do
				playSoundRanged(player, Game.bomb.pos, Settings.SOUNDS.EXPLOSION)

				if player.state == PlayerStates.IN_ROUND then
					local distance = helpers.distance(humanGetPos(player.id), Game.bomb.pos)
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

return (function ()
    return {
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

        update = function ()
            if Game.state == GameStates.WAITING_FOR_PLAYERS then
                despawnBomb()
            end
            updateBomb()
        end,

		updateGameState = function(state)
			if state == GameStates.WAITING_FOR_PLAYERS then
                local bombPlayer = helpers.randomTableElem(Teams.tt.players)
                Game.bomb.pickupId = pickupCreate(humanGetPos(bombPlayer.id), Game.bomb.model)
                Game.bomb.player = bombPlayer
                pickupAttachTo(Game.bomb.pickupId, bombPlayer.id, Game.bomb.offset)
                bombPlayer.hasBomb = true
			elseif state == GameStates.ROUND then
				local playTick = false
				if Game.bomb.plantTime ~= 0 and CurTime >= Game.bomb.timeToTick then
					local x = (CurTime - Game.bomb.plantTime) / Settings.WAIT_TIME.BOMB;
					local n = (BEEP_A1 * x) + (BEEP_A2 * x ^ 2);
					local bps = BEEP_A0 * math.exp(n);

					Game.bomb.timeToTick = CurTime + ((1000.0 / bps) / 1000.0);
					playTick = true
				end

				for _, player in pairs(Players) do
					if Game.bomb.plantTime ~= 0 then
						if playTick then
							playSoundRanged(player, Game.bomb.pos, Settings.SOUNDS.BOMB_TICK)
						end

						addHudAnnounceMessage(player, "Bomb is planted!")
					else
						addHudAnnounceMessage(player, string.format("%.2fs", WaitTime - CurTime))
					end
				end

				if Game.bomb.plantTime == 0 and CurTime > WaitTime then
					print("win cause of game time ended")
					teamWin(Teams.ct, Game.bomb.plantTime ~= 0, false)
				end
			elseif state == GameStates.AFTER_ROUND then
				if WaitTime < CurTime then
					despawnBomb()
				end
			end
		end,

        updatePlayer = function (player)
            if player.hasBomb then
                if CurTime - player.timeIdleStart > Settings.WAIT_TIME.AFK_DROP_BOMB then
                    dropBomb(player)
                else
                    for _, cuboid in pairs(Settings.BOMBSITES) do
                        if player.state == PlayerStates.IN_ROUND and helpers.isPointInCuboid(humanGetPos(player.id), cuboid) then
                            player.isInBombsite = true

                            if player.holdsDefusePlantKey then
                                if Game.bomb.timeToPlant == 0 then
                                    Game.bomb.timeToPlant = CurTime + Settings.WAIT_TIME.PLANT_BOMB
                                    humanLockControls(player.id, true)

                                    local planterPos = humanGetPos(player.id)
                                    for _, player2 in pairs(Players) do
                                        playSoundRanged(player2, planterPos, Settings.SOUNDS.START_PLANT)
                                    end
                                elseif CurTime > Game.bomb.timeToPlant then
                                    pickupDetach(Game.bomb.pickupId)

                                    local pos = humanGetPos(player.id)
                                    pos[2] = pos[2] + 0.5
                                    pickupSetPos(Game.bomb.pickupId, pos)
                                    Game.bomb.pos = pos

                                    player.hasBomb = false
                                    Game.bomb.timeToPlant = 0
                                    Game.bomb.plantTime = CurTime
                                    Game.bomb.player = nil

                                    WaitTime = CurTime + Settings.WAIT_TIME.BOMB

                                    sendClientMessageToAll("Bomb has been planted!")
                                    humanLockControls(player.id, false)
                                else
                                    addHudAnnounceMessage(player, "Planting!")
                                end
                            else
                                Game.bomb.timeToPlant = 0
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
        end,

        initPlayer = function ()
            return {
		        timeToPickupBomb = 0,
                hasDefuseKit = false,
                holdsDefusePlantKey = false,
                hasBomb = false,
                isInBombsite = false,
            }
        end,

        onPlayerInsidePickupRadius = function (playerId, pickupId)
            local player = Players[playerId]

            if pickupId == Game.bomb.pickupId then
                if player.state == PlayerStates.IN_ROUND
                    and player.team == Teams.tt
                    and not player.hasBomb
                    and Game.bomb.plantTime == 0
                    and (CurTime - player.timeIdleStart < Settings.WAIT_TIME.AFK_DROP_BOMB)
                    and CurTime > player.timeToPickupBomb then

                    print(humanGetName(player.id) .. " picked up bomb")
                    pickupAttachTo(pickupId, playerId, Game.bomb.offset)
                    Game.bomb.player = player
                    player.hasBomb = true
                end
            elseif player.state == PlayerStates.IN_ROUND and player.team == Teams.ct and not player.hasDefuseKit then
                player.hasDefuseKit = true
                pickupDestroy(pickupId)
            end
        end,

        onPlayerKeyPress = function (player, isDown, key)
            if player.state == PlayerStates.IN_ROUND then
                if (key == VirtualKeys.Menu) then
                    --print(string.format("player %d  team %s  key %d  isDown %s", player.id, player.team.name, key, tostring(isDown)))
                    player.holdsDefusePlantKey = isDown
                end
            end
        end,

        diePlayer = function (player)
            if Game.bomb.defuser and Game.bomb.defuser.id == player.id then
                stopDefusing()
            end

            player.holdsDefusePlantKey = false

            dropBomb(player)

            if player.hasDefuseKit then
                player.hasDefuseKit = false
                local pos = helpers.addRandomVectorOffset(humanGetPos(player.id), {0.5, 0, 0.5})
                local pickupId = pickupCreate(pos, Settings.DEFUSE_KIT_MODEL)
                table.insert(Game.weaponPickups, pickupId)
            end

            if Game.state == GameStates.ROUND then
                local deadPlayersCount = 0
                for _, player in pairs(player.team.players) do
                    if player.state == PlayerStates.DEAD or player.state == PlayerStates.SPECTATING then
                        deadPlayersCount = deadPlayersCount + 1
                    end
                end

                if deadPlayersCount == player.team.numPlayers then
                    if player.team == Teams.tt and Game.bomb.plantTime ~= 0 then
                        --brain farted, dunno
                    else
                        print("win cause of enemy team dead")
                        teamWin(player.team == Teams.ct and Teams.tt or Teams.ct, Game.bomb.plantTime ~= 0, false)
                    end
                end
            end
        end
    }
end)()