-- Global settings for the GM
local Settings = {
    MISSION = "MISE15-PRISTAV",
    TEAMS = {
        NONE = {
            NAME = "None",
            COLOR = "#FFFFFF"
        },
        TT = {
            NAME = "Terrorists",
            COLOR = "#FFFF80",
            MODELS = { "Enemy04K.i3d", "Enemy06+.i3d", "Enemy08+.i3d", "Enemy10K.i3d", "Enemy12K.i3d", "TommyHAT.i3d" },
            SPAWN_AREA = { {-1837.071, -4.7, -750.245}, {-1834.463, -4.7, -766.136} }, -- this consits of two points representing opposite corners of a not-rotated cuboid in 3D space
            SPAWN_DIR = { 0.900399, 0.000000, 0.435065 }
        },
        CT = {
            NAME = "Counter Terrorists",
            COLOR = "#408CFF",
            MODELS = { "pol01.i3d", "pol02.i3d", "pol03.i3d", "pol11.i3d", "pol12.i3d", "pol13.i3d" },
            SPAWN_AREA = { {-1857.230225; -4.7; -735.69043}, {-1863.850342; -4.7; -740.580566} }, -- this consits of two points representing opposite corners of a not-rotated cuboid in 3D space
            SPAWN_DIR = { 0.900399, 0.000000, 0.435065 }
        }
    },
    BOMBSITES = {
        { {-1878.905884; -8; -763.742249}, {-1860.74353; 0; -746.660034} }, -- this consits of two points representing opposite corners of a not-rotated cuboid in 3D space
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
    MAX_TEAM_SCORE = 999,
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
        BUYING = 30.0,
        END_ROUND = 10.0,
        END_GAME = 15.0,
        DEFUSING = {
            KIT = 5.0,
            NO_KIT = 10.0
        }
    },
    MIN_PLAYER_AMOUNT_PER_TEAM = 1, -- TODO change to 5
    PLAYER_STARTING_MONEY = 1000,
    PLAYER_MAX_MONEY = 16000,
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
            weaponId = 3,
            name = "Knife",
            page = "Melee",
            cost = 100,
            killReward = 1500,
            canBuy = { "tt" , "ct" }
        },
        { 
            weaponId = 4,
            name = "Baseball Bat",
            page = "Melee",
            cost = 250,
            killReward = 1500,
            canBuy = { "tt" , "ct" }
        },
        {
            weaponId = 15,
            name = "Grenade",
            page = "Other",
            cost = 300,
            killReward = 300,
            canBuy = { "tt" , "ct" }
        },
        {
            weaponId = 5,
            name = "Molotov Cocktail",
            page = "Other",
            cost = 400,
            killReward = 300,
            canBuy = { "tt" , "ct" }
        },
        {
            weaponId = 6,
            name = "Colt Detective Special",
            page = "Pistols",
            cost = 300,
            killReward = 300,
            canBuy = { "tt" , "ct" }
        },
        {
            weaponId = 7,
            name = "S&W model 27 Magnum",
            page = "Pistols",
            cost = 700,
            killReward = 300,
            canBuy = { "tt" , "ct" }
        },
        {
            weaponId = 8,
            name = "S&W model 10 M&P",
            page = "Pistols",
            cost = 450,
            killReward = 300,
            canBuy = { "tt" , "ct" }
        },
        {
            weaponId = 9,
            name = "Colt 1911",
            page = "Pistols",
            cost = 500,
            killReward = 300,
            canBuy = { "tt" , "ct" }
        },
        {
            weaponId = 10,
            name = "Thompson 1928",
            page = "Rifles",
            cost = 3100,
            killReward = 300,
            canBuy = { "tt" , "ct" }
        },
        {
            weaponId = 11,
            name = "Pump shotgun",
            page = "Shotguns",
            cost = 2000,
            killReward = 900,
            canBuy = { "tt" , "ct" }
        },
        {
            weaponId = 12,
            name = "Sawn-off shotgun",
            page = "Shotguns",
            cost = 1100,
            killReward = 900,
            canBuy = { "tt" , "ct" }
        },
        {
            weaponId = 13,
            name = "US Rifle M1903 Springfield",
            page = "Rifles",
            cost = 1700,
            killReward = 300,
            canBuy = { "tt" , "ct" }
        },
        {
            weaponId = 14,
            name = "Mosin-Nagant 1891/30",
            page = "Rifles",
            cost = 4750,
            killReward = 100,
            canBuy = { "tt" , "ct" }
        },
        {
            special = "defuse",
            name = "Defuse Kit",
            page = "Other",
            cost = 400,
            canBuy = { "ct" }
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

Settings.DEFUSE_RANGE_SQUARED = Settings.DEFUSE_RANGE ^ 2
Settings.SPAWN_RANGE_SQUARED = Settings.SPAWN_RANGE ^ 2

return Settings