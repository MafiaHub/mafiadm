return {
    MISSION = "XMAS_2021_CTF",
    MODE = Modes.CTF,
    TEAMS = {
        AUTOASSIGN = true,
        TT = {
            SPAWN_AREA = { {-56.221218, -4.096076, -19.344057}, {-61.312107, -4.096076, -22.260204} },
            SPAWN_DIR = { 0.900399, 0.000000, 0.435065 }
        },
        CT = {
            SPAWN_AREA = { {60.125362, -1.945289, 22.320036}, {65.215324, -1.945289, 25.234195} },
            SPAWN_DIR = { 0.900399, 0.000000, 0.435065 }
        }
    },
    FLAG = {
        PLACE_RADIUS = 3.0
    },
    FLAGS = {
        RED = {-1849.201660, -5.309030, -769.778564},
        BLUE = {-1861.321411, -5.362978, -751.921265},
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
    MAX_TEAM_SCORE = 16,
}
