local BEEP_A0 = 1.04865151217746
local BEEP_A1 = 0.244017811416199
local BEEP_A2 = 1.76379778668885

local function despawnBomb()
    if GM.bomb.pickupId == 0 then
        return
    end

    if GM.bomb.player then
        pickupDetach(GM.bomb.pickupId)
        GM.bomb.player = nil
    end

    pickupDestroy(GM.bomb.pickupId)
    GM.bomb.pickupId = 0
    GM.bomb.plantTime = 0
    GM.bomb.pos = { 0.0, 0.0, 0.0 }
    GM.bomb.defuser = nil
    GM.bomb.timeToDefuse = 0
    GM.bomb.timeToPlant = 0
    GM.bomb.timeToTick = 0
end

local function dropBomb(player)
    if player.hasBomb then
        player.timeToPickupBomb = CurTime + Settings.WAIT_TIME.PICKUP_BOMB

        local pos = Helpers.addRandomVectorOffset(humanGetPos(player.id), {1.0, 0, 1.0}) -- IDEA don't use random, spawn it on a circle circumerence
        pickupDetach(GM.bomb.pickupId)
        pickupSetPos(GM.bomb.pickupId, pos)

        GM.bomb.player = nil
        player.hasBomb = false

        print(humanGetName(player.id) .. " dropped bomb")
    end
end

local function teamWin(team, bombPlanted, bombExploded)
    advance.round(team, function (team)
        local oppositeTeam = getOppositeTeam(team)

        local paymentInfo = Settings.ROUND_PAYMENT[team.shortName][team.winRow > 5 and 5 or team.winRow]
        local winMoney = paymentInfo.win + (bombPlanted and paymentInfo.bomb_plant or 0) + (bombExploded and paymentInfo.bomb_detonate or 0)
        paymentInfo = Settings.ROUND_PAYMENT[oppositeTeam.shortName][team.winRow > 5 and 5 or team.winRow] -- using team here intentionally to get correct loss
        local lossMoney = paymentInfo.loss + (bombPlanted and paymentInfo.bomb_plant or 0) + (bombExploded and paymentInfo.bomb_detonate or 0)

        return {
            win = winMoney,
            loss = lossMoney
        }
    end)
end

local function stopDefusing()
    if GM.bomb.defuser and GM.bomb.defuser.state == PlayerStates.IN_ROUND then
        humanLockControls(GM.bomb.defuser.id, false)
        -- IDEA maybe send message to team that bomb is not being defused?
    end

    GM.bomb.timeToDefuse = 0
    GM.bomb.defuser = nil
end

local function updateBomb()
    if GM.bomb.plantTime ~= 0 then -- I know that I'm not really using onPlayerInsidePickupRadius, because it's called only for the first player in the radius, and if there's more than one inside radius - it can break the intended logic
        if GM.bomb.defuser then
            local defuser = GM.bomb.defuser
            if (defuser.holdsDefusePlantKey and Helpers.distanceSquared(GM.bomb.pos, humanGetPos(GM.bomb.defuser.id)) <= Settings.DEFUSE_RANGE_SQUARED) then
                if CurTime >= GM.bomb.timeToDefuse then
                    humanLockControls(defuser.id, false)

                    local defuserPos = humanGetPos(defuser.id)
                    for _, player in pairs(Players) do
                        playSoundRanged(player, defuserPos, Settings.SOUNDS.BOMB_DEFUSED)
                    end

                    despawnBomb()

                    if GM.state == GameStates.ROUND then
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

        if not GM.bomb.defuser then
            for _, player in pairs(Teams.ct.players) do
                local dist = Helpers.distanceSquared(GM.bomb.pos, humanGetPos(player.id))
                if (dist <= Settings.DEFUSE_RANGE_SQUARED) then
                    if player.holdsDefusePlantKey then
                        local defusingTime = player.hasDefuseKit and Settings.WAIT_TIME.DEFUSING.KIT or Settings.WAIT_TIME.DEFUSING.NO_KIT
                        GM.bomb.timeToDefuse = CurTime + defusingTime
                        GM.bomb.defuser = player
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

        if GM.bomb.plantTime ~= 0 and CurTime - GM.bomb.plantTime > Settings.WAIT_TIME.BOMB then
            if GM.state == GameStates.ROUND then
                print("win cause of boom")
                teamWin(Teams.tt, true, true)
                sendClientMessageToAll("Bomb exploded, " .. Teams.tt:inTeamColor() .. " win!")
            else
                sendClientMessageToAll("Bomb exploded!")
            end

            createExplosion(GM.bomb.pos, 0, 0)

            for _, player in pairs(Players) do
                playSoundRanged(player, GM.bomb.pos, Settings.SOUNDS.EXPLOSION)

                if player.state == PlayerStates.IN_ROUND then
                    local distance = Helpers.distance(humanGetPos(player.id), GM.bomb.pos)
                    if distance < Settings.BOMB.BLAST_RADIUS then
                        local damage = Helpers.remapValue(distance, Settings.BOMB.BLAST_RADIUS, 0, 0, Settings.BOMB.BLAST_FORCE)
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
        if GM.state == GameStates.WAITING_FOR_PLAYERS then
            despawnBomb()
        end
        updateBomb()
    end,

    updateGameState = function(state)
        if state == GameStates.WAITING_FOR_PLAYERS then
            local bombPlayer = Helpers.randomTableElem(Teams.tt.players)
            GM.bomb.pickupId = pickupCreate(humanGetPos(bombPlayer.id), GM.bomb.model)
            GM.bomb.player = bombPlayer
            pickupAttachTo(GM.bomb.pickupId, bombPlayer.id, GM.bomb.offset)
            bombPlayer.hasBomb = true
        elseif state == GameStates.ROUND then
            local playTick = false
            if GM.bomb.plantTime ~= 0 and CurTime >= GM.bomb.timeToTick then
                local x = (CurTime - GM.bomb.plantTime) / Settings.WAIT_TIME.BOMB;
                local n = (BEEP_A1 * x) + (BEEP_A2 * x ^ 2);
                local bps = BEEP_A0 * math.exp(n);

                GM.bomb.timeToTick = CurTime + ((1000.0 / bps) / 1000.0);
                playTick = true
            end

            for _, player in pairs(Players) do
                if GM.bomb.plantTime ~= 0 then
                    if playTick then
                        playSoundRanged(player, GM.bomb.pos, Settings.SOUNDS.BOMB_TICK)
                    end

                    addHudAnnounceMessage(player, "Bomb is planted!")
                else
                    addHudAnnounceMessage(player, string.format("%.2fs", WaitTime - CurTime))
                end
            end

            if GM.bomb.plantTime == 0 and CurTime > WaitTime then
                print("win cause of game time ended")
                teamWin(Teams.ct, GM.bomb.plantTime ~= 0, false)
            end
        elseif state == GameStates.AFTER_ROUND then
            if WaitTime < CurTime then
                despawnBomb()
            end
        end

        return false
    end,

    updatePlayer = function (player)
        if player.hasBomb then
            if CurTime - player.timeIdleStart > Settings.WAIT_TIME.AFK_DROP_BOMB then
                dropBomb(player)
            else
                for _, cuboid in pairs(Settings.BOMBSITES) do
                    if player.state == PlayerStates.IN_ROUND and Helpers.isPointInCuboid(humanGetPos(player.id), cuboid) then
                        player.isInBombsite = true

                        if player.holdsDefusePlantKey then
                            if GM.bomb.timeToPlant == 0 then
                                GM.bomb.timeToPlant = CurTime + Settings.WAIT_TIME.PLANT_BOMB
                                humanLockControls(player.id, true)

                                local planterPos = humanGetPos(player.id)
                                for _, player2 in pairs(Players) do
                                    playSoundRanged(player2, planterPos, Settings.SOUNDS.START_PLANT)
                                end
                            elseif CurTime > GM.bomb.timeToPlant then
                                pickupDetach(GM.bomb.pickupId)

                                local pos = humanGetPos(player.id)
                                pos[2] = pos[2] + 0.5
                                pickupSetPos(GM.bomb.pickupId, pos)
                                GM.bomb.pos = pos

                                player.hasBomb = false
                                GM.bomb.timeToPlant = 0
                                GM.bomb.plantTime = CurTime
                                GM.bomb.player = nil

                                WaitTime = CurTime + Settings.WAIT_TIME.BOMB

                                sendClientMessageToAll("Bomb has been planted!")
                                humanLockControls(player.id, false)
                            else
                                addHudAnnounceMessage(player, "Planting!")
                            end
                        else
                            GM.bomb.timeToPlant = 0
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

    handleSpecialBuy = function (player, weapon)
        if weapon.special == "defuse" then
            if player.hasDefuseKit then
                hudAddMessage(player.id, "Couldn't buy this weapon!", Helpers.rgbToColor(255, 38, 38))
            else
                player.money = player.money - weapon.cost
                player.hasDefuseKit = true
                hudAddMessage(player.id, string.format("Bought %s for %d$, money left: %d$", weapon.name, weapon.cost, player.money), Helpers.rgbToColor(34, 207, 0))
                return true
            end
        end

        return false
    end,

    onPlayerInsidePickupRadius = function (playerId, pickupId)
        local player = Players[playerId]

        if pickupId == GM.bomb.pickupId then
            if player.state == PlayerStates.IN_ROUND
                and player.team == Teams.tt
                and not player.hasBomb
                and GM.bomb.plantTime == 0
                and (CurTime - player.timeIdleStart < Settings.WAIT_TIME.AFK_DROP_BOMB)
                and CurTime > player.timeToPickupBomb then

                print(humanGetName(player.id) .. " picked up bomb")
                pickupAttachTo(pickupId, playerId, GM.bomb.offset)
                GM.bomb.player = player
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
        if GM.bomb.defuser and GM.bomb.defuser.id == player.id then
            stopDefusing()
        end

        player.holdsDefusePlantKey = false

        dropBomb(player)

        if player.hasDefuseKit then
            player.hasDefuseKit = false
            local pos = Helpers.addRandomVectorOffset(humanGetPos(player.id), {0.5, 0, 0.5})
            local pickupId = pickupCreate(pos, Settings.DEFUSE_KIT_MODEL)
            table.insert(GM.weaponPickups, pickupId)
        end

        if GM.state == GameStates.ROUND then
            local deadPlayersCount = 0
            for _, player in pairs(player.team.players) do
                if player.state == PlayerStates.DEAD or player.state == PlayerStates.SPECTATING then
                    deadPlayersCount = deadPlayersCount + 1
                end
            end

            if deadPlayersCount == player.team.numPlayers then
                if player.team == Teams.tt and GM.bomb.plantTime ~= 0 then
                    --brain farted, dunno
                else
                    print("win cause of enemy team dead")
                    teamWin(player.team == Teams.ct and Teams.tt or Teams.ct, GM.bomb.plantTime ~= 0, false)
                end
            end
        end

        spectate(player, 1)
    end,

    showObjectives = function (player)
        addHudAnnounceMessage(player, "Objectives:")
        addHudAnnounceMessage(player, "As a gangster, you must place a bomb on a designated bomb site and defend it.")
        addHudAnnounceMessage(player, "As a cop, you must defuse the bomb and eliminate the opposing team.")
        addHudAnnounceMessage(player, string.format("Reach score of %d with your team to win the game!", Settings.MAX_TEAM_SCORE))
    end
}