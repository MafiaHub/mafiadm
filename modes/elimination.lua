local function teamWin(team)
	advance.round(team, function (team)
        local oppositeTeam = getOppositeTeam(team)

        local paymentInfo = Settings.ROUND_PAYMENT[team.shortName][team.winRow > 5 and 5 or team.winRow]
        local winMoney = paymentInfo.win
        paymentInfo = Settings.ROUND_PAYMENT[oppositeTeam.shortName][team.winRow > 5 and 5 or team.winRow] -- using team here intentionally to get correct loss
        local lossMoney = paymentInfo.loss

        return {
            win = winMoney,
            loss = lossMoney
        }
    end)
end

return {
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
            else
                for _, player in pairs(Players) do
                    addHudAnnounceMessage(player, string.format("%.2fs", WaitTime - CurTime))
                end
            end
        end

        return false
    end,

    diePlayer = function (player)
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
                    teamWin(player.team == Teams.ct and Teams.tt or Teams.ct)
                end
            end
        end

        spectate(player, 1)
    end
}