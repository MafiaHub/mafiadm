local function teamWin(team)
end

return {
    init = function ()
        -- Team deathmatch doesn't really work with economy
        Settings.PLAYER_DISABLE_ECONOMY = true

        -- Enforce respawn after death
        Settings.PLAYER_RESPAWN_AFTER_DEATH = true

        -- Allow time-based win condition
        Settings.GAME_WIN_CONDITION_TIME = true
    end,

    updateGameState = function (state)
        if state == GameStates.ROUND then
            for _, player in pairs(Players) do
                addHudAnnounceMessage(player, string.format("TT %d : CT %d\n%.2fs", Teams.tt.score, Teams.ct.score, WaitTime - CurTime))
            end
        end

        return false
    end,

    diePlayer = function (player)
        if Game.state == GameStates.ROUND then
            advance.simple(getOppositeTeam(player.team))
        end
    end
}