-- Global settings for the GM

local settings = {
    TEAMS = {
        ENABLED = true, -- do not touch unless you know what you're doing!
        AUTOASSIGN = false, -- auto-assign player to team on join
        AUTOBALANCE = true, -- rebalance teams if there are more players on one team than on another
        NONE = {
            NAME = "None",
            COLOR = "#FFFFFF",
            MODELS = nil, -- combined with default models from teams
        },
        TT = {
            NAME = "Gangsters",
            COLOR = "#FFFF80",
            MODELS = { "Enemy04K.i3d", "Enemy06+.i3d", "Enemy08+.i3d", "Enemy10K.i3d", "Enemy12K.i3d", "TommyHAT.i3d" },
        },
        CT = {
            NAME = "Cops",
            COLOR = "#408CFF",
            MODELS = { "pol01.i3d", "pol02.i3d", "pol03.i3d", "pol11.i3d", "pol12.i3d", "pol13.i3d" },
        }
    },
    SOUNDS = {
        START_PLANT = {
            FILE = "plant.wav",
            RANGE = 50
        },
        START_DEFUSE = {
            FILE = "defuse.wav",
            RANGE = 50
        },
        BOMB_TICK = {
            FILE = "tick.wav",
            RANGE = 50
        },
        BOMB_DEFUSED = {
            FILE = "snip.wav",
            RANGE = 50
        },
        EXPLOSION = {
            FILE = "explosion.wav",
            RANGE = 100
        }
    },
    DEFUSE_RANGE = 2.0,
    DEFUSE_KIT_MODEL = "DefuseKit.i3d",
    SPAWN_RANGE = 0.5,
    BOMB = {
        BLAST_RADIUS = 13,
        BLAST_FORCE = 500,
        MODEL = "2bomb.i3d"
    },
    FLAG = {
        MODELS = {
            RED = "REDflag.i3d",
            BLUE = "BLUEflag.i3d",
        },
        PLACE_RADIUS = 1.5,
    },
    HEALTH_PICKUP = {
        HEALTH = 25,
        RESPAWN_TIME = 90.0,
        MODEL = "vodkaHP.i3d"
    },
    WEAPON_PICKUP = {
        RESPAWN_TIME = 5000 * 60,
    },
    MAX_TEAM_SCORE = 16,
    FRIENDLY_FIRE = {
        ENABLED = false, -- TODO fix in RC3 Kappa
        DAMAGE_MULTIPLIER = 0.5
    },
    WAIT_TIME = {
        ROUND = 2.5 * 60.0, -- 2.5 minutes
        PLANT_BOMB = 5.0,
        BOMB = 40.0,
        AFK_DROP_BOMB = 15.0,
        PICKUP_BOMB = 5.0,
        PICKUP_FLAG = 5.0,
        BUYING = 30.0,
        BUY_PICKUP_WEAPON = 3.0,
        END_ROUND = 10.0,
        SHOP_CLOSE = 15.0,
        AFTER_DEATH_RESPAWN = 5.0,
        END_GAME = 15.0,
        DEFUSING = {
            KIT = 5.0,
            NO_KIT = 10.0
        }
    },
    MIN_PLAYER_AMOUNT_PER_TEAM = 5,
    PLAYER_DISABLE_ECONOMY = false,
    PLAYER_DISABLE_SHOP = false,
    PLAYER_STARTING_MONEY = 1000,
    PLAYER_MAX_MONEY = 16000,
    PLAYER_RESPAWN_AFTER_DEATH = false,
    PLAYER_USE_SPAWNPOINTS = false,
    PLAYER_HOTJOIN = false,
    PLAYER_ALLOW_SHOP_IN_ROUND = true,
    PLAYER_SHOP_IN_ROUND_NOLIMIT = false,
    PLAYER_SPEED_MULT = 1.0,
    GAME_WIN_CONDITION_TIME = false,
    NORMAL_WEAPONS_RUN_SPEED = 1.0,
    HEAVY_WEAPONS_RUN_SPEED = 0.8,
    HEAVY_WEAPONS = {
        10, -- Thompson
        11, -- Pump shotgun
        12, -- Sawn-off shotgun
        13, -- Springfield
        14, -- Mosin-Nagant
    },
    LIGHT_WEAPONS_RUN_SPEED = 0.9,
    LIGHT_WEAPONS = {
        6, -- Cold Detective Shitial
        7, -- S&W model 27 Magnum
        8, -- S&W model 10 M&P
        9, -- Colt 1911
    },
    GRENADES = {
        5, -- Molotov Cocktail
        15 -- Grenade
    },
    PAGES_ORDER = {
        "Melee",
        "Pistols",
        "Shotguns",
        "Rifles",
        "Other"
    },
    WEAPONS = {
        {
            weaponId = 0,
            name = "Hands",
            killReward = 1500
        },
        {
            weaponId = 2,
            name = "Knuckleduster",
            page = "Melee",
            model = "2boxer.i3d",
            cost = 100,
            killReward = 1500,
            canBuy = { "tt" , "ct" }
        },
        {
            weaponId = 3,
            name = "Knife",
            page = "Melee",
            model = "2knife.i3d",
            cost = 100,
            killReward = 1500,
            canBuy = { "tt" , "ct" }
        },
        {
            weaponId = 4,
            name = "Baseball Bat",
            page = "Melee",
            model = "2bat.i3d",
            cost = 250,
            killReward = 1500,
            canBuy = { "tt" , "ct" }
        },
        {
            weaponId = 15,
            name = "Grenade",
            page = "Other",
            model = "2grenade.i3d",
            cost = 300,
            killReward = 300,
            canBuy = { "tt" , "ct" }
        },
        {
            weaponId = 5,
            name = "Molotov Cocktail",
            page = "Other",
            model = "2mol.i3d",
            cost = 400,
            killReward = 300,
            canBuy = { "tt" , "ct" }
        },
        {
            weaponId = 6,
            name = "Colt Detective Special",
            page = "Pistols",
            model = "2coltDS.i3d",
            cost = 300,
            killReward = 300,
            canBuy = { "tt" , "ct" }
        },
        {
            weaponId = 7,
            name = "S&W model 27 Magnum",
            page = "Pistols",
            model = "2sw27.i3d",
            cost = 700,
            killReward = 300,
            canBuy = { "tt" , "ct" }
        },
        {
            weaponId = 8,
            name = "S&W model 10 M&P",
            page = "Pistols",
            model = "2sw10.i3d",
            cost = 450,
            killReward = 300,
            canBuy = { "tt" , "ct" }
        },
        {
            weaponId = 9,
            name = "Colt 1911",
            page = "Pistols",
            model = "2c1911.i3d",
            cost = 500,
            killReward = 300,
            canBuy = { "tt" , "ct" }
        },
        {
            weaponId = 10,
            name = "Thompson 1928",
            page = "Rifles",
            model = "2tommy.i3d",
            cost = 3100,
            killReward = 300,
            canBuy = { "tt" , "ct" }
        },
        {
            weaponId = 11,
            name = "Pump shotgun",
            page = "Shotguns",
            model = "2shotgun.i3d",
            cost = 2000,
            killReward = 900,
            canBuy = { "tt" , "ct" }
        },
        {
            weaponId = 12,
            name = "Sawn-off shotgun",
            page = "Shotguns",
            model = "2sawoff2.i3d",
            cost = 1100,
            killReward = 900,
            canBuy = { "tt" , "ct" }
        },
        {
            weaponId = 13,
            name = "US Rifle M1903 Springfield",
            page = "Rifles",
            model = "2m1903.i3d",
            cost = 1700,
            killReward = 300,
            canBuy = { "tt" , "ct" }
        },
        {
            weaponId = 14,
            name = "Mosin-Nagant 1891/30",
            page = "Rifles",
            model = "2mosin.i3d",
            cost = 4750,
            killReward = 100,
            canBuy = { "tt" , "ct" }
        },
        {
            special = "defuse",
            name = "Defuse Kit",
            page = "Other",
            cost = 400,
            canBuy = { "ct" },
            gmOnly = Modes.BOMB
        }
    },
    ROUND_PAYMENT = {
        tt = {
            { -- 1st in a row
                win = 3250,
                bomb_detonate = 250,
                loss = 1400,
                bomb_plant = 800,
            },
            { -- 2nd in a row etc...
                win = 3250,
                bomb_detonate = 250,
                loss = 1900,
                bomb_plant = 800,
            },
            {
                win = 3250,
                bomb_detonate = 250,
                loss = 2400,
                bomb_plant = 800,
            },
            {
                win = 3250,
                bomb_detonate = 250,
                loss = 2900,
                bomb_plant = 800,
            },
            {
                win = 3250,
                bomb_detonate = 250,
                loss = 3400,
                bomb_plant = 800,
            }
        },
        ct = {
            { -- 1st in a row
                win = 3250,
                bomb_detonate = 250,
                loss = 1400,
                bomb_plant = 0,
            },
            { -- 2nd in a row etc...
                win = 3250,
                bomb_detonate = 250,
                loss = 1900,
                bomb_plant = 0,
            },
            {
                win = 3250,
                bomb_detonate = 250,
                loss = 2400,
                bomb_plant = 0,
            },
            {
                win = 3250,
                bomb_detonate = 250,
                loss = 2900,
                bomb_plant = 0,
            },
            {
                win = 3250,
                bomb_detonate = 250,
                loss = 3400,
                bomb_plant = 0,
            }
        }
    }
}

settings.DEFUSE_RANGE_SQUARED = settings.DEFUSE_RANGE ^ 2
settings.SPAWN_RANGE_SQUARED = settings.SPAWN_RANGE ^ 2

return settings