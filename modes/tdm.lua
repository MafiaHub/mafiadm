return {
    init = function ()
        -- Team deathmatch doesn't really work with economy
        Settings.PLAYER_DISABLE_SHOP = true

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
        if GM.state == GameStates.ROUND then
            advance.simple(getOppositeTeam(player.team))
        end
    end,

    showObjectives = function (player)
        addHudAnnounceMessage(player, "Objectives:")
        addHudAnnounceMessage(player, string.format("Reach score of %d with your team by the time limit. Team with the most score wins if time is up!", Settings.MAX_TEAM_SCORE))
    end
}