local settings = {
    MISSION = "MISE15-PRISTAV",
    MODE = Modes.BOMB,
    TEAMS = {
        AUTOBALANCE = true,
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
    BOMBSITES = {
        { {-1878.905884; -8; -763.742249}, {-1860.74353; 0; -746.660034} }, -- this consits of two points representing opposite corners of a not-rotated cuboid in 3D space
    },
}

return settings