---@diagnostic disable: lowercase-global

function InitMode(mode)
    print("\nLoading mode: " .. mode)
    GM = Helpers.tableAssignDeep(GM, require("modes/" .. mode))
end

function inTeamColor(team, text)
    return team.msgColor .. (text or team.name) .. "#FFFFFF"
end

Teams.none.inTeamColor = inTeamColor
Teams.tt.inTeamColor = inTeamColor
Teams.ct.inTeamColor = inTeamColor

function compareTeams(t1, t2)
    return t1.shortName == t2.shortName
end

function sendSelectTeamMessage(player)
    if Settings.TEAMS.AUTOASSIGN == true then
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

function sendClientMessageToAllTeam(team, message)
    for _, player in pairs(Players) do
        if compareTeams(player.team, team) then
            sendClientMessage(player.id, string.format("#00FF00%s", message))
        else
            sendClientMessage(player.id, string.format("#FF0000%s", message))
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

--@diagnostic disable-next-line: lowercase-global
advance = {}

-- Only use in non-round based (TDM, CTF) gamemodes !!
function advance.simple(team)
    team.score = team.score + 1

    if team.score >= Settings.MAX_TEAM_SCORE then
        GM.state = GameStates.AFTER_GAME
        WaitTime = Settings.WAIT_TIME.END_GAME + CurTime

        sendClientMessageToAll(team:inTeamColor() .. " win!")
        sendClientMessageToAll(string.format("%s %d : %d %s", Teams.tt:inTeamColor(), Teams.tt.score, Teams.ct.score, Teams.ct:inTeamColor()))
    end
end

-- Only use in round based gamemodes !!
function advance.round(team, moneyProc)
    if team == Teams.none then
        sendClientMessageToAll("It's a draw!")
        sendClientMessageToAll(string.format("%s %d : %d %s", Teams.tt:inTeamColor(), Teams.tt.score, Teams.ct.score, Teams.ct:inTeamColor()))
        local ctPaymentInfo = Settings.ROUND_PAYMENT.ct[team.winRow > 5 and 5 or team.winRow]
        local ttPaymentInfo = Settings.ROUND_PAYMENT.tt[team.winRow > 5 and 5 or team.winRow]
        teamAddPlayerMoney(Teams.ct, ctPaymentInfo.loss, "You've got")
        teamAddPlayerMoney(Teams.tt, ttPaymentInfo.loss, "You've got")
        return
    end

    team.score = team.score + 1

    local oppositeTeam = getOppositeTeam(team)

    if not team.wonLast then
        team.wonLast = true
        team.winRow = 1
        oppositeTeam.wonLast = false
        oppositeTeam.winRow = 0
    else
        team.winRow = team.winRow + 1
    end

    local moneyInfo = moneyProc(team)
    local winMoney = moneyInfo.win
    local lossMoney = moneyInfo.loss

    sendClientMessageToAll(team:inTeamColor() .. " win!")
    sendClientMessageToAll(string.format("%s %d : %d %s", Teams.tt:inTeamColor(), Teams.tt.score, Teams.ct.score, Teams.ct:inTeamColor()))

    for _, player in pairs(team.players) do
        addPlayerMoney(player, winMoney, "You've won the round and got")
    end

    for _, player in pairs(oppositeTeam.players) do
        addPlayerMoney(player, lossMoney, "You've lost the round and got")
    end

    if team.score >= Settings.MAX_TEAM_SCORE then
        GM.state = GameStates.AFTER_GAME
        WaitTime = Settings.WAIT_TIME.END_GAME + CurTime
    else
        GM.state = GameStates.AFTER_ROUND
        WaitTime = Settings.WAIT_TIME.END_ROUND + CurTime
    end
end

function findPlayerWithUID(uid)
    for _, player in pairs(Players) do
        if player.uid == uid then
            return player.id
        end
    end

    return nil
end

function clearPlayersInventory()
    for _, player in pairs(Players) do
        inventoryTruncateWeapons(player.id)
    end
end

function addPlayerMoney(player, money, msg, color)
    if Settings.PLAYER_DISABLE_ECONOMY then
        return
    end
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

    if not Settings.TEAMS.ENABLED then
        team = Teams.none
    elseif Settings.TEAMS.AUTOASSIGN == true and team == Teams.none then
        team = Teams.ct.numPlayers < Teams.tt.numPlayers and Teams.ct or Teams.tt
    end

    team.numPlayers = team.numPlayers + 1
    team.players[player.id] = player
    player.team = team
    player.state = PlayerStates.WAITING_FOR_ROUND

    if Settings.TEAMS.ENABLED then
        sendClientMessage(player.id, "You are assigned to team " .. team:inTeamColor() .. "!")
    end

    if GM.state ~= GameStates.WAITING_FOR_PLAYERS and not Settings.PLAYER_HOTJOIN then
        spectate(player, 1)
    end
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
        if not Settings.PLAYER_USE_SPAWNPOINTS then
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
        else
            local spawnPoint = Helpers.randomTableElem(player.team.spawnPoints)
            spawnPos = spawnPoint[1]
            if not optionalSpawnDir then optionalSpawnDir = spawnPoint[2] end
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
            if Settings.SPAWN_WEAPONS then
                for _, weaponId in ipairs(Settings.SPAWN_WEAPONS) do
                    inventoryAddWeaponDefault(player.id, weaponId)
                end
            end
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

    GM.buyMenuPages = pages
end

function clearUpPickups()
    for _, pickupId in ipairs(GM.weaponPickups) do
        pickupDestroy(pickupId)
    end
    GM.weaponPickups = {}
end

function sendBuyMenuMessage(player)
    if not Settings.PLAYER_USE_SPAWNPOINTS and not Helpers.isPointInCuboid(humanGetPos(player.id), player.team.spawnAreaCheck) then
        return
    end
    local key = 1

    local playerPage = player.buyMenuPage
    player.buyMenuPage = {}

    -- IDEA clear chat?
    sendClientMessage(player.id, "\n\n")
    sendClientMessage(player.id, string.format("Your money: #00CE00%d$#FFFFFF", player.money))

    if player.isInMainBuyMenu then
        for _, pageName in ipairs(Settings.PAGES_ORDER) do
            sendClientMessage(player.id, string.format("%d: %s", key, pageName))
            player.buyMenuPage[key] = GM.buyMenuPages[pageName]
            key = key + 1
        end
    else
        sendClientMessage(player.id, "0: Go back")
        for _, item in ipairs(playerPage) do
            if (Helpers.tableHasValue(item.canBuy, player.team.shortName) or not Settings.TEAMS.ENABLED) and (item.gmOnly == nil or item.gmOnly == Settings.MODE) then
                sendClientMessage(player.id, string.format("%d: %s - %s%d$#FFFFFF", key, item.name, item.cost > player.money and "#FF0000" or "#FFFFFF", item.cost))
                player.buyMenuPage[key] = item
                key = key + 1
            end
        end
    end
end

function handleBuyMenuRequest(player, key, isDown)
    if Settings.PLAYER_USE_SPAWNPOINTS or Helpers.isPointInCuboid(humanGetPos(player.id), player.team.spawnAreaCheck) then
        if player.state == PlayerStates.IN_ROUND and isDown then
            if player.isInMainBuyMenu then
                local menu = player.buyMenuPage[key - VirtualKeys.N0]
                if menu then
                    player.buyMenuPage = menu
                    player.isInMainBuyMenu = false
                    sendBuyMenuMessage(player)
                end
            elseif player.buyMenuPage then
                if key == VirtualKeys.N0 then
                    player.isInMainBuyMenu = true
                    sendBuyMenuMessage(player)
                else
                    local weapon = player.buyMenuPage[key - VirtualKeys.N0]

                    if buyWeapon(player, weapon) then
                        sendBuyMenuMessage(player)
                    end
                end
            end
        end
    end
end

function prepareSpawnAreaCheck(team)
    if not team.spawnArea then
        team.spawnAreaCheck = {
            { 0.0, 0.0, 0.0 },
            { 0.0, 0.0, 0.0 }
        }
        return
    end
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
        if player and player.isSpawned and player.state == PlayerStates.IN_ROUND then
            local curPos = humanGetPos(player.id)
            local curDir = humanGetDir(player.id)

            if Helpers.compareVectors(player.lastPos, curPos) and Helpers.compareVectors(player.lastDir, curDir) then
                -- player hasn't moved
            else
                player.timeIdleStart = CurTime
            end

            player.lastPos = curPos
            player.lastDir = curDir

            if not player.overrideSpeed then
                local playerWeaponId = inventoryGetCurrentItem(player.id).weaponId
                if Helpers.tableHasValue(Settings.HEAVY_WEAPONS, playerWeaponId) then
                    humanSetSpeed(player.id, Settings.HEAVY_WEAPONS_RUN_SPEED * Settings.PLAYER_SPEED_MULT)
                elseif Helpers.tableHasValue(Settings.LIGHT_WEAPONS, playerWeaponId) then
                    humanSetSpeed(player.id, Settings.LIGHT_WEAPONS_RUN_SPEED * Settings.PLAYER_SPEED_MULT)
                else
                    humanSetSpeed(player.id, Settings.NORMAL_WEAPONS_RUN_SPEED * Settings.PLAYER_SPEED_MULT)
                end
            end
        end

        GM.updatePlayer(player)

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

function buyWeapon(player, weapon)
    if player and weapon then
        if player.money >= weapon.cost then
            local bought = false
            if weapon.special then
                bought = GM.handleSpecialBuy(player, weapon)
            else
                if inventoryAddWeaponDefault(player.id, weapon.weaponId) then
                    player.money = player.money - weapon.cost
                    bought = true
                    hudAddMessage(player.id, string.format("Bought %s for %d$, money left: %d$", weapon.name, weapon.cost, player.money), Helpers.rgbToColor(34, 207, 0))
                else
                    hudAddMessage(player.id, "Couldn't buy this weapon! Not enough space in inventory!", Helpers.rgbToColor(255, 38, 38))
                end
            end

            return bought
        else
            hudAddMessage(player.id, "Couldn't afford to buy this weapon!", Helpers.rgbToColor(255, 38, 38))
            return false
        end
    end
end

function startGame()
    if Settings.HEALTH_PICKUPS then
        for _, pickupPos in ipairs(Settings.HEALTH_PICKUPS) do
            local healthPickupId = pickupCreate(pickupPos, Settings.HEALTH_PICKUP.MODEL)
            table.insert(GM.healthPickups, {
                id = healthPickupId,
                pos = pickupPos,
                time = 0.0
            })
        end
    end

    if Settings.WEAPON_PICKUPS then
        for _, pickup in ipairs(Settings.WEAPON_PICKUPS) do
            local pickupId = weaponDropCreateDefault(pickup[2], pickup[1], Settings.WEAPON_PICKUP.RESPAWN_TIME)
            table.insert(GM.weaponPickups, pickupId)
        end
    end

    if Settings.BUY_WEAPON_PICKUPS then
        for _, pickup in ipairs(Settings.BUY_WEAPON_PICKUPS) do
            local pickupId = pickupCreate(pickup[1], findWeaponInfoInSettings(pickup[2]).model)
            table.insert(GM.buyWeaponPickups, {
                id = pickupId,
                wepId = pickup[2],
            })
        end
    end

    if not Settings.TEAMS.ENABLED then
        Settings.FRIENDLY_FIRE.ENABLED = true
        Settings.TEAMS.AUTOASSIGN = true
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

    GM.diePlayer(player, inflictor, damage, hitType, bodyPart, disconnected)

    if Settings.PLAYER_RESPAWN_AFTER_DEATH then
        player.deadTime = CurTime + Settings.WAIT_TIME.AFTER_DEATH_RESPAWN
    end

    for _, item in pairs(inventory) do
        local weaponId = item.weaponId
        if weaponId > 1 and inventoryRemoveWeapon(playerId, weaponId) then
            local pos = Helpers.addRandomVectorOffset(humanGetPos(player.id), {1.0, 0.0, 1.0})
            local pickupId = weaponDropCreate(weaponId, pos, 2147483647, item.ammoLoaded, item.ammoHidden)
            table.insert(GM.weaponPickups, pickupId)
        end
    end

    if not disconnected then
        sendClientMessageToAll(inflictor.team:inTeamColor(humanGetName(inflictor.id)) .. " killed " .. player.team:inTeamColor(humanGetName(player.id)))
    end
end

function spawnPlayer(player)
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
end

local function autobalancePlayers()
    if not Settings.TEAMS.AUTOBALANCE or not Settings.TEAMS.ENABLED then
        return
    end

    for _, player in pairs(Players) do
        if player.team == Teams.none then
            autoAssignPlayerToTeam(player)
        end
    end

    local ctNumPlayers = Teams.ct.numPlayers
    local ttNumPlayers = Teams.tt.numPlayers

    if ctNumPlayers == ttNumPlayers then
        return
    end

    if math.abs(ctNumPlayers-ttNumPlayers) < 2 then
        return
    end

    if ctNumPlayers > ttNumPlayers then
        local numToMove = (ctNumPlayers - ttNumPlayers) // 2
        for i=numToMove, 1, -1 do
            local player = Helpers.tableGetIndex(Teams.ct.players, Teams.ct.numPlayers)
            if player then
                assignPlayerToTeam(player, getOppositeTeam(player.team))
            end
        end
    else
        local numToMove = (ttNumPlayers - ctNumPlayers) // 2
        for i=numToMove, 1, -1 do
            local player = Helpers.tableGetIndex(Teams.tt.players, Teams.tt.numPlayers)
            if player then
                assignPlayerToTeam(player, getOppositeTeam(player.team))
            end
        end
    end

    sendClientMessageToAll("Teams have been rebalanced!")
end

function updateGame()
    if GM.state == GameStates.WAITING_FOR_PLAYERS then
        if (Teams.tt.numPlayers >= Settings.MIN_PLAYER_AMOUNT_PER_TEAM and Teams.ct.numPlayers >= Settings.MIN_PLAYER_AMOUNT_PER_TEAM)
            or GM.skipTeamReq then
            GM.skipTeamReq = false

            autobalancePlayers()

            for _, player in pairs(Players) do
                if player.team ~= Teams.none or not Settings.TEAMS.ENABLED then
                    spawnPlayer(player)

                    if not Settings.PLAYER_DISABLE_ECONOMY and not Settings.PLAYER_DISABLE_SHOP then
                        player.isInMainBuyMenu = true
                        sendBuyMenuMessage(player)
                    end
                end
            end

            if not GM.updateGameState(GM.state) then
                if Settings.PLAYER_DISABLE_ECONOMY or Settings.PLAYER_DISABLE_SHOP then
                    GM.state = GameStates.ROUND
                    WaitTime = Settings.WAIT_TIME.ROUND + CurTime
                    GM.roundBuyShopTime = CurTime + Settings.WAIT_TIME.SHOP_CLOSE
                else
                    GM.state = GameStates.BUY_TIME
                    WaitTime = Settings.WAIT_TIME.BUYING + CurTime
                end
            end
        else
            for _, player in pairs(Players) do
                local numPlayers = Helpers.tableCountFields(Players)

                if numPlayers < Settings.MIN_PLAYER_AMOUNT_PER_TEAM*2 then
                    addHudAnnounceMessage(player, string.format("Waiting for %d more players", Settings.MIN_PLAYER_AMOUNT_PER_TEAM*2 - numPlayers))
                end
            end
        end
    elseif GM.state == GameStates.BUY_TIME then
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

            if not GM.updateGameState(GM.state) then
                GM.state = GameStates.ROUND
                WaitTime = Settings.WAIT_TIME.ROUND + CurTime
                GM.roundBuyShopTime = CurTime + Settings.WAIT_TIME.SHOP_CLOSE
            end
        end
    elseif GM.state == GameStates.ROUND then
        for _, healthPickup in ipairs(GM.healthPickups) do
            if healthPickup.id == nil and healthPickup.time < CurTime then
                healthPickup.id = pickupCreate(healthPickup.pos, Settings.HEALTH_PICKUP.MODEL)
            end
        end

        GM.updateGameState(GM.state)

        if Settings.PLAYER_RESPAWN_AFTER_DEATH then
            for _, player in pairs(Players) do
                if player.state == PlayerStates.DEAD and player.deadTime < CurTime then
                    spawnPlayer(player)
                elseif player.state == PlayerStates.DEAD then
                    addHudAnnounceMessage(player, string.format("%.2fs left until respawn", player.deadTime - CurTime))
                end
            end
        end

        if (GM.roundBuyShopTime > CurTime or Settings.PLAYER_SHOP_IN_ROUND_NOLIMIT) and not Settings.PLAYER_USE_SPAWNPOINTS then
            for _, player in pairs(Players) do
                if player.state == PlayerStates.IN_ROUND then
                    if Helpers.isPointInCuboid(humanGetPos(player.id), player.team.spawnAreaCheck) then
                        if Settings.PLAYER_SHOP_IN_ROUND_NOLIMIT then
                            addHudAnnounceMessage(player, "Buy zone")
                        else
                            addHudAnnounceMessage(player, string.format("Buy zone - %.2fs", GM.roundBuyShopTime - CurTime))
                        end
                    end
                end
            end
        end

        if Settings.GAME_WIN_CONDITION_TIME then
            if CurTime > WaitTime then
                local ttScore = Teams.tt.score
                local ctScore = Teams.ct.score

                local team = nil
                if ttScore > ctScore then
                    team = Teams.tt
                elseif ctScore > ttScore then
                    team = Teams.ct
                end

                if team then
                    sendClientMessageToAll(team:inTeamColor() .. " win!")
                    sendClientMessageToAll(string.format("%s %d : %d %s", Teams.tt:inTeamColor(), Teams.tt.score, Teams.ct.score, Teams.ct:inTeamColor()))
                else
                    sendClientMessageToAll("It's a draw!")
                    sendClientMessageToAll(string.format("%s %d : %d %s", Teams.tt:inTeamColor(), Teams.tt.score, Teams.ct.score, Teams.ct:inTeamColor()))
                end

                GM.state = GameStates.AFTER_GAME
                WaitTime = Settings.WAIT_TIME.END_GAME + CurTime
            end
        end
    elseif GM.state == GameStates.AFTER_ROUND then
        if WaitTime > CurTime then
            for _, player in pairs(Players) do
                addHudAnnounceMessage(player, string.format("Next round in %.2fs!", WaitTime - CurTime))
            end
        else
            clearUpPickups()

            if not GM.updateGameState(GM.state) then
                GM.state = GameStates.WAITING_FOR_PLAYERS
                WaitTime = Settings.WAIT_TIME.BUYING + CurTime
            end
        end
    elseif GM.state == GameStates.AFTER_GAME then
        if WaitTime > CurTime then
            for _, player in pairs(Players) do
                if Teams.tt.score == Teams.ct.score then
                    addHudAnnounceMessage(player, string.format("It's a draw! Next game in %.2fs!", WaitTime - CurTime))
                else
                    addHudAnnounceMessage(player, string.format("%s win! Next game in %.2fs!", Teams.tt.score > Teams.ct.score and Teams.tt.name or Teams.ct.name, WaitTime - CurTime))
                end
            end
        else
            GM.updateGameState(GM.state)

            Teams.tt.score = 0
            Teams.tt.winRow = 0
            Teams.tt.wonLast = false

            Teams.ct.score = 0
            Teams.ct.winRow = 0
            Teams.ct.wonLast = false

            clearUpPickups()

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

            GM = Helpers.deepCopy(EmptyGM)
            GM.state = GameStates.WAITING_FOR_PLAYERS

            startGame()
        end
    end
end
