function cmds.pos(player, ...)
	if zac.isAdmin(player.uid) then
		if player.isSpawned then
			local pos = humanGetPos(player.id)
			local dir = humanGetDir(player.id)
			local msg = "{ " .. tostring(pos[1]) .. " " .. tostring(pos[2]) .. " " .. tostring(pos[3] .. " }, ")
			msg = msg .. "{ " .. tostring(dir[1]) .. " " .. tostring(dir[2]) .. " " .. tostring(dir[3] .. " }")
			print(msg)
			sendClientMessage(player.id, msg)
		else
			sendClientMessage(player.id, "You are not spawned.")
		end
	end
end

function cmds.tskip(player, ...)
	if zac.isAdmin(player.uid) then
		WaitTime = CurTime
	end
end

function cmds.skip(player, ...)
	if zac.isAdmin(player.uid) then
		Game.skipTeamReq = true
	end
end

function cmds.moolah(player, ...)
	if zac.isAdmin(player.uid) then
		arg = {...}
		if #arg > 0 then
			local money = tonumber(arg[1])
			if money and money > 0 then
				addPlayerMoney(player, money, "You cheeky wanker, you got", Helpers.rgbToColor(255, 0, 255))
			end
		end
	end
end

function cmds.kickme(player)
	humanKick(player.id, "Self-Kick!!")
end

function cmds.acreload(player)
	if zac.isAdmin(player.uid) then
		zac.reloadLists()
	end
end

function cmds.whois(player)
	if zac.isAdmin(player.uid) then
		zac.showPlayerData()
	end
end

function cmds.p(player)
	if zac.isAdmin(player.uid) then
		Game.pauseGame = not Game.pauseGame
	end
end

function cmds.ban(player, ...)
	if zac.isAdmin(player.uid) then
		local arg = {...}
		if #arg > 0 then
			local playerId = tonumber(arg[1])
			if playerId then
				zac.banPlayer(humanGetUID(playerId))
				humanKick(playerId, "You have been banned from the server.")
			end
		end
	end
end

function cmds.banid(player, ...)
	if zac.isAdmin(player.uid) then
		local arg = {...}
		if #arg > 0 then
			local uid = tonumber(arg[1])
			if uid then
				zac.banPlayer(uid)

				local playerId = findPlayerWithUID(uid)
				if playerId then
					humanKick(playerId, "You have been banned from the server.")
				end
			end
		end
	end
end

function cmds.setSpeed(player, ...)
	if zac.isAdmin(player.uid) then
		if player.isSpawned then
			local speed = tonumber(arg[1])
			humanSetSpeed(player.id, speed)
		else
			sendClientMessage(player.id, "You are not spawned :)")
		end
	end
end
