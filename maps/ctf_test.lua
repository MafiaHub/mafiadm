local settings = {
    MISSION = "MISE15-PRISTAV",
    MODE = Modes.CTF,
    TEAMS = {
        AUTOASSIGN = true,
        NONE = {
            NAME = "None",
            COLOR = "#FFFFFF"
        },
        TT = {
            NAME = "Gangsters",
            COLOR = "#FFFF80",
            MODELS = { "Enemy04K.i3d", "Enemy06+.i3d", "Enemy08+.i3d", "Enemy10K.i3d", "Enemy12K.i3d", "TommyHAT.i3d" },
            SPAWN_AREA = { {-1837.071, -4.7, -750.245}, {-1834.463, -4.7, -766.136} }, -- this consits of two points representing opposite corners of a not-rotated cuboid in 3D space
            SPAWN_DIR = { 0.900399, 0.000000, 0.435065 }
        },
        CT = {
            NAME = "Cops",
            COLOR = "#408CFF",
            MODELS = { "pol01.i3d", "pol02.i3d", "pol03.i3d", "pol11.i3d", "pol12.i3d", "pol13.i3d" },
            SPAWN_AREA = { {-1857.230225; -4.7; -735.69043}, {-1863.850342; -4.7; -740.580566} }, -- this consits of two points representing opposite corners of a not-rotated cuboid in 3D space
            SPAWN_DIR = { 0.900399, 0.000000, 0.435065 }
        }
    },
    FLAGS = {
        RED = {-1849.201660, -5.309030, -769.778564},
        BLUE = {-1861.321411, -5.362978, -751.921265},
    },
    HEALTH_PICKUPS = {
        {-1856.507812, -5.309011, -762.003967},
        {-1851.658691, -5.308902, -756.330627},
    },
    WEAPON_PICKUPS = {
        { {-1702.395996, -5.935770, -568.837769}, 10 },
        { {-1744.685059, -5.386947, -646.439453}, 10 },
        { {-1823.035156, -5.203501, -674.039673}, 11 },
        { {-1863.053955, -5.348383, -666.220276}, 10 },
        { {-1891.020752, -5.428892, -729.963989}, 12 },
        { {-1912.142212, -1.006007, -753.185181}, 5 },
        { {-1958.036743, -5.431374, -819.409851}, 14 },
    },
    WELCOME_CAMERA = {
        START = {
            POS = {-1700.850708, 8.153258, -605.137939},
            ROT = {-0.870903, -0.216014, -0.491455, 0.000000},
        },
        STOP = {
            POS = {-1769.448364, -1.662790, -659.857788},
            ROT = {-0.809314, -0.016318, -0.587376, 0.000000},
        },
        TIME = 80000,
    },
    MAX_TEAM_SCORE = 50,
}

return settings