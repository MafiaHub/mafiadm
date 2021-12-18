# Mafia: Oakwood MafiaDM gamemode

Official gamemode framework for Mafia: Oakwood

Currently hosts these gamemodes:
- CSGO-alike bomb-defusal gamemode
- Team Deathmatch
- Elimination
- Capture The Flag
- Free-For-All (no rounds, just kill everyone)

## How to use

1. Open **server.json** and set `gamemode` to `<mod_path>/init.lua`
2. Set `static-dir` to `<mod_path>/static`
3. Set `map` to `TUTORIAL`
4. Open **<mod_path>/init.lua** and set **MAPNAME** to your desired map from `<mod_path>/maps`
5. Have a look at **<mod_path>/config/settings.lua** for more settings

## Credits

Huge thanks to [@NanobotZ](https://github.com/nanobotz/) for implementing the CS:GO inspired bomb-defusal gamemode and [@saska](https://www.youtube.com/channel/UCn-RCjui_E6TOBXpGtxcJfg) for various assets used by this framework.
See [LICENSE](LICENSE) for more information regarding licensing.
