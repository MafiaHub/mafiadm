local function despawnFlag(flag)
	if flag.id == 0 then
		return
	end

	if flag.player then
		pickupDetach(flag.id)
        flag.player.flag = nil
        flag.player.hasFlag = false
		flag.player = nil
	end

	pickupDestroy(flag.id)
	flag.id = 0
    flag.isTaken = false
end

local function getFlagByID(pickupId)
    if pickupId == GM.ctf.flags.red.id then
        return GM.ctf.flags.red
    elseif pickupId == GM.ctf.flags.blue.id then
        return GM.ctf.flags.blue
    else
        return {
            id = 0,
        }
    end
end

local function resetFlag(flag)
    local flagPos = compareTeams(flag.team, Teams.tt) and Settings.FLAGS.RED or Settings.FLAGS.BLUE
    local flagModel = compareTeams(flag.team, Teams.tt) and Settings.FLAG.MODELS.RED or Settings.FLAG.MODELS.BLUE
    despawnFlag(flag)

    flag.id = pickupCreateStatic(flagPos, flagModel)
    flag.nextInteractionTime = CurTime + Settings.WAIT_TIME.INTERACT_FLAG
end

local function dropFlag(player)
	if player.hasFlag then
		player.timeToPickupFlag = CurTime + Settings.WAIT_TIME.PICKUP_FLAG

		local pos = Helpers.addRandomVectorOffset(humanGetPos(player.id), {1.0, 0, 1.0})
		pickupDetach(player.flag.id)
		pickupSetPos(player.flag.id, pos)
        pickupSetStatic(player.flag.id, false)
        player.flag.nextInteractionTime = CurTime + Settings.WAIT_TIME.INTERACT_FLAG
        sendClientMessageToAllTeam(player.flag.team, string.format("%s dropped the flag!", humanGetName(player.id)))

		player.flag.player = nil
        player.hasFlag = false
        player.flag = nil

		print(humanGetName(player.id) .. " dropped the flag")
	end
end

local function pickupFlag(player, pickupId)
    local flag = getFlagByID(pickupId)

    if pickupId == flag.id then
        if player.state == PlayerStates.IN_ROUND
            and not player.hasFlag
            and (not flag.isTaken or (flag.isTaken and not flag.player))
            and not compareTeams(player.team, flag.team)
            and CurTime > flag.nextInteractionTime
            and CurTime > player.timeToPickupFlag then
                print(humanGetName(player.id) .. " captured the flag!")
                sendClientMessageToAllTeam(player.team, string.format("%s captured the flag!", humanGetName(player.id)))
                pickupAttachTo(pickupId, player.id, GM.ctf.offset)
                pickupSetStatic(pickupId, false)
                flag.player = player
                flag.isTaken = true
                player.hasFlag = true
                player.flag = flag
                flag.nextInteractionTime = CurTime + Settings.WAIT_TIME.INTERACT_FLAG
        elseif player.state == PlayerStates.IN_ROUND
            and flag.isTaken
            and CurTime > flag.nextInteractionTime
            and compareTeams(player.team, flag.team) then
                print(humanGetName(player.id) .. " returned the flag!")
                sendClientMessageToAllTeam(flag.team, string.format("%s has returned the flag!", humanGetName(player.id)))
                addPlayerMoney(player, 2000)
                resetFlag(flag)
        end
    end
end

return {
    ctf = {
        offset = {0.0, 2.5, 0.0},
        flags = {
            red = {
                id = 0,
                pos = nil,
                player = nil,
                isTaken = false,
                team = Teams.tt,
                nextInteractionTime = 0.0,
            },
            blue = {
                id = 0,
                pos = nil,
                player = nil,
                isTaken = false,
                team = Teams.ct,
                nextInteractionTime = 0.0,
            },
        },
    },

    init = function ()
        -- Team deathmatch doesn't really work with economy
        Settings.PLAYER_DISABLE_SHOP = true

        -- Enforce respawn after death
        Settings.PLAYER_RESPAWN_AFTER_DEATH = true

        -- Allow time-based win condition
        Settings.GAME_WIN_CONDITION_TIME = true

        -- Allow shops without time limit
        Settings.PLAYER_SHOP_IN_ROUND_NOLIMIT = true

        -- Allow players to hotjoin
        Settings.PLAYER_HOTJOIN = true
    end,

    update = function ()
        if GM.state == GameStates.WAITING_FOR_PLAYERS then
            despawnFlag(GM.ctf.flags.red)
            despawnFlag(GM.ctf.flags.blue)
        end
    end,

    updateGameState = function (state)
        if state == GameStates.WAITING_FOR_PLAYERS then
            despawnFlag(GM.ctf.flags.red)
            despawnFlag(GM.ctf.flags.blue)
            GM.ctf.flags.red.id = pickupCreateStatic(Settings.FLAGS.RED, Settings.FLAG.MODELS.RED)
            GM.ctf.flags.blue.id = pickupCreateStatic(Settings.FLAGS.BLUE, Settings.FLAG.MODELS.BLUE)
        elseif state == GameStates.ROUND then
            for _, player in pairs(Players) do
                addHudAnnounceMessage(player, string.format("TT %d : CT %d\n%.2fs", Teams.tt.score, Teams.ct.score, WaitTime - CurTime))
            end
        elseif state == GameStates.AFTER_GAME then
            if WaitTime < CurTime then
                despawnFlag(GM.ctf.flags.red)
                despawnFlag(GM.ctf.flags.blue)
                clearPlayersInventory()
            end
        end

        return false
    end,

    updatePlayer = function (player)
        if player.hasFlag then
            local flagPos = compareTeams(player.team, Teams.tt) and Settings.FLAGS.RED or Settings.FLAGS.BLUE

            if Helpers.distanceSquared(humanGetPos(player.id), flagPos) < Settings.FLAG.PLACE_RADIUS then
                sendClientMessageToAllTeam(player.team, string.format("%s has delivered the flag!", humanGetName(player.id)))
                resetFlag(player.flag)
                advance.simple(player.team)
                addPlayerMoney(player, 4000)
            end
        end
    end,

    initPlayer = function ()
        return {
            hasFlag = false,
            timeToPickupFlag = 0.0,
            flag = nil,
        }
    end,

    onPlayerInsidePickupRadius = function (playerId, pickupId)
        local player = Players[playerId]
        pickupFlag(player, pickupId)
    end,

    diePlayer = function (player)
        if GM.state == GameStates.ROUND then
            dropFlag(player)
        end
    end,

    showObjectives = function (player)
        addHudAnnounceMessage(player, "Objectives:")
        addHudAnnounceMessage(player, "Steal the flag of the other team and deliver it back to your base!")
        addHudAnnounceMessage(player, "If your flag was stolen, kill the flag bearer and return the flag back!")
        addHudAnnounceMessage(player, string.format("Reach score of %d with your team by capturing flags to win the game!", Settings.MAX_TEAM_SCORE))
    end
}