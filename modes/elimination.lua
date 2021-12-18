local function teamWin(team)
	if team == Teams.none then
		sendClientMessageToAll("It's a draw!")
		sendClientMessageToAll(string.format("%s %d : %d %s", Teams.tt:inTeamColor(), Teams.tt.score, Teams.ct.score, Teams.ct:inTeamColor()))
		local ctPaymentInfo = Settings.ROUND_PAYMENT.ct[team.winRow > 5 and 5 or team.winRow]
		local ttPaymentInfo = Settings.ROUND_PAYMENT.tt[team.winRow > 5 and 5 or team.winRow]
		teamAddPlayerMoney(Teams.tt, ctPaymentInfo.loss, "You've got")
		teamAddPlayerMoney(Teams.tt, ttPaymentInfo.loss, "You've got")
		return
	end
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
	local winMoney = paymentInfo.win
	for _, player in pairs(team.players) do
		addPlayerMoney(player, winMoney, "You've won the round and got")
	end

	paymentInfo = Settings.ROUND_PAYMENT[oppositeTeam.shortName][team.winRow > 5 and 5 or team.winRow] -- using team here intentionally to get correct loss
	local lossMoney = paymentInfo.loss
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

return {
    update = function ()
    end,

    updateGameState = function (state)
        if state == GameStates.ROUND then
            if CurTime > WaitTime then
                print("win cause of game time ended")
                local ttScore = teamCountAlivePlayers(Teams.tt)
                local ctScore = teamCountAlivePlayers(Teams.ct)

                if ttScore > ctScore then
                    teamWin(Teams.tt)
                elseif ctScore > ttScore then
                    teamWin(Teams.ct)
                else
                    teamWin(Teams.none)
                end
            end
        end
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
                    teamWin(player.team == Teams.ct and Teams.tt or Teams.ct)
                end
            end
        end
    end
}