# Mafia: Oakwood MafiaDM gamemode

Official gamemode framework for Mafia: Oakwood

Currently hosts these gamemodes:
- CSGO-alike bomb-defusal gamemode
- Team Deathmatch
- Elimination
- Capture The Flag

## How to use

1. Open **server.json** and set `gamemode` to `<mod_path>/init.lua`
2. Set `static-dir` to `<mod_path>/static`
3. Open **<mod_path>/config/mapload.lua** and set **MAPNAME** to your desired map from `<mod_path>/maps`
4. Have a look at **<mod_path>/config/settings.lua** for more settings