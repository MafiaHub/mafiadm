local function teamWin(team)
	team.score = team.score + 1

	if team.score >= Settings.MAX_TEAM_SCORE then
		Game.state = GameStates.AFTER_GAME
		WaitTime = Settings.WAIT_TIME.END_GAME + CurTime

        sendClientMessageToAll(team:inTeamColor() .. " win!")
	    sendClientMessageToAll(string.format("%s %d : %d %s", Teams.tt:inTeamColor(), Teams.tt.score, Teams.ct.score, Teams.ct:inTeamColor()))
	end
end

return {
    init = function ()
        -- Team deathmatch doesn't really work with economy
        Settings.PLAYER_DISABLE_ECONOMY = true

        -- Enforce respawn after death
        Settings.PLAYER_RESPAWN_AFTER_DEATH = true

        -- Allow time-based win condition
        Settings.WIN_CONDITION_TIME = true
    end,
    update = function ()
    end,

    updateGameState = function (state)
        if state == GameStates.ROUND then
            for _, player in pairs(Players) do
                addHudAnnounceMessage(player, string.format("TT %d : CT %d\n%.2fs", Teams.tt.score, Teams.ct.score, WaitTime - CurTime))
            end
        end

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
        if Game.state == GameStates.ROUND then
            teamWin(getOppositeTeam(player.team))
        end
    end
}