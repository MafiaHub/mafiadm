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
    end,
    update = function ()
    end,

    updateGameState = function (state)
        if state == GameStates.ROUND then
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

                Game.state = GameStates.AFTER_GAME
		        WaitTime = Settings.WAIT_TIME.END_GAME + CurTime
                return true
            end

            for _, player in pairs(Players) do
                if player.state == PlayerStates.DEAD and player.dead_time < CurTime then
                    spawnPlayer(player)
                elseif player.state == PlayerStates.DEAD then
                    addHudAnnounceMessage(player, string.format("%.2fs left until respawn", player.dead_time - CurTime))
                else
                    addHudAnnounceMessage(player, string.format("TT %d : CT %d\n%.2fs", Teams.tt.score, Teams.ct.score, WaitTime - CurTime))
                end
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
        return {
            dead_time = 0.0
        }
    end,

    onPlayerInsidePickupRadius = function (playerId, pickupId)
    end,

    onPlayerKeyPress = function (player, isDown, key)
    end,

    diePlayer = function (player)
        if Game.state == GameStates.ROUND then
            player.dead_time = CurTime + Settings.WAIT_TIME.AFTER_DEATH_RESPAWN
            teamWin(getOppositeTeam(player.team))
        end
    end
}