function cmds.score()
    -- TODO print leaderboards
end

return {
    init = function ()
        -- FFA has no shops
        Settings.PLAYER_DISABLE_SHOP = true

        -- Enforce respawn after death
        Settings.PLAYER_RESPAWN_AFTER_DEATH = true

        -- Spawn player during round (required since we don't do rounds)
        Settings.PLAYER_HOTJOIN = true

        -- Deny time-based win condition
        Settings.GAME_WIN_CONDITION_TIME = false

        -- Disable teams
        Settings.TEAMS.ENABLED = false

        -- Use spawnpoints
        Settings.PLAYER_USE_SPAWNPOINTS = true

        -- Allow shops without time limit
        Settings.PLAYER_SHOP_IN_ROUND_NOLIMIT = true

        -- Ensure there's no min player count needed to start the game
        Settings.MIN_PLAYER_AMOUNT_PER_TEAM = 0
    end,

    initPlayer = function ()
        return {
            score = 0
        }
    end,

    updateGameState = function (state)
        if state == GameStates.ROUND then
            for _, player in pairs(Players) do
                addHudAnnounceMessage(player, string.format("SCORE %d", player.score))
            end
        end

        return false
    end,

    diePlayer = function (player, inflictor)
        if Game.state == GameStates.ROUND and inflictor then
            inflictor.score = inflictor.score + 1
        end
    end
}