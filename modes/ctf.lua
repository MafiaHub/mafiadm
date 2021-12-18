local function teamWin(team)
	team.score = team.score + 1

	if team.score >= Settings.MAX_TEAM_SCORE then
		Game.state = GameStates.AFTER_GAME
		WaitTime = Settings.WAIT_TIME.END_GAME + CurTime

        sendClientMessageToAll(team:inTeamColor() .. " win!")
	    sendClientMessageToAll(string.format("%s %d : %d %s", Teams.tt:inTeamColor(), Teams.tt.score, Teams.ct.score, Teams.ct:inTeamColor()))
	end
end

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

local function getFlagPos(flag)
    if flag.team.name == Teams.tt.name then
        return Settings.FLAGS.RED
    elseif flag.team.name == Teams.ct.name then
        return Settings.FLAGS.BLUE
    end
end

local function getFlagModel(flag)
    if flag.team.name == Teams.tt.name then
        return Settings.FLAG.MODELS.RED
    elseif flag.team.name == Teams.ct.name then
        return Settings.FLAG.MODELS.BLUE
    end
end

local function getFlagByID(pickupId)
    if pickupId == Game.ctf.flags.red.id then
        return Game.ctf.flags.red
    elseif pickupId == Game.ctf.flags.blue.id then
        return Game.ctf.flags.blue
    else
        return {
            id = 0,
        }
    end
end

local function resetFlag(flag)
    local flagPos = getFlagPos(flag)
    local flagModel = getFlagModel(flag)
    despawnFlag(flag)

    flag.id = pickupCreate(flagPos, flagModel)
end

local function dropFlag(player)
	if player.hasFlag then
		player.timeToPickupFlag = CurTime + Settings.WAIT_TIME.PICKUP_FLAG

		local pos = Helpers.addRandomVectorOffset(humanGetPos(player.id), {1.0, 0, 1.0})
		pickupDetach(player.flag.id)
		pickupSetPos(player.flag.id, pos)

		player.flag.player = nil
        player.hasFlag = false
        player.flag = nil

		print(humanGetName(player.id) .. " dropped the flag")
        sendClientMessageToAll(string.format("#FF0000%s dropped the flag!", humanGetName(player.id)))
	end
end

local function pickupFlag(player, pickupId)
    local flag = getFlagByID(pickupId)

    if pickupId == flag.id then
        if player.state == PlayerStates.IN_ROUND
            and not player.hasFlag
            and not flag.isTaken
            and player.team.name ~= flag.team.name
            and CurTime > player.timeToPickupFlag then
                print(humanGetName(player.id) .. " captured the flag!")
                sendClientMessageToAll(string.format("#00FF00%s captured the flag!", humanGetName(player.id)))
                pickupAttachTo(pickupId, player.id, Game.ctf.offset)
                flag.player = player
                flag.isTaken = true
                player.hasFlag = true
                player.flag = flag
        elseif player.state == PlayerStates.IN_ROUND
            and flag.isTaken
            and player.team.name == flag.team.name then
                print(humanGetName(player.id) .. " returned the flag!")
                sendClientMessageToAll(string.format("#0000FF%s has returned the flag!", humanGetName(player.id)))
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
                team = Teams.tt
            },
            blue = {
                id = 0,
                pos = nil,
                player = nil,
                isTaken = false,
                team = Teams.ct
            },
        },
    },

    init = function ()
        -- Team deathmatch doesn't really work with economy
        Settings.PLAYER_DISABLE_ECONOMY = true

        -- Enforce respawn after death
        Settings.PLAYER_RESPAWN_AFTER_DEATH = true

        -- Allow time-based win condition
        Settings.WIN_CONDITION_TIME = true
    end,

    update = function ()
        if Game.state == GameStates.WAITING_FOR_PLAYERS then
            despawnFlag(Game.ctf.flags.red)
            despawnFlag(Game.ctf.flags.blue)
        end
    end,

    updateGameState = function (state)
        if state == GameStates.WAITING_FOR_PLAYERS then
            despawnFlag(Game.ctf.flags.red)
            despawnFlag(Game.ctf.flags.blue)
            Game.ctf.flags.red.id = pickupCreate(Settings.FLAGS.RED, Settings.FLAG.MODELS.RED)
            Game.ctf.flags.blue.id = pickupCreate(Settings.FLAGS.BLUE, Settings.FLAG.MODELS.BLUE)
        elseif state == GameStates.ROUND then
            for _, player in pairs(Players) do
                addHudAnnounceMessage(player, string.format("TT %d : CT %d\n%.2fs", Teams.tt.score, Teams.ct.score, WaitTime - CurTime))
            end
        elseif state == GameStates.AFTER_GAME then
            if WaitTime < CurTime then
                despawnFlag(Game.ctf.flags.red)
                despawnFlag(Game.ctf.flags.blue)
            end
        end

        return false
    end,

    updatePlayer = function (player)
        if player.hasFlag then
            local flagPos = player.team.name == Teams.tt.name and Settings.FLAGS.RED or Settings.FLAGS.BLUE

            if Helpers.distanceSquared(humanGetPos(player.id), flagPos) < Settings.FLAG.PLACE_RADIUS then
                sendClientMessageToAll(string.format("%s has delivered the flag!", humanGetName(player.id)))
                resetFlag(player.flag)
                teamWin(player.team)
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
        if Game.state == GameStates.ROUND then
            dropFlag(player)
        end
    end
}