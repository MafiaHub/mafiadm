return {
    MISSION = "DE_DUST2",
    MODE = Modes.BOMB,
    TEAMS = {
        TT = {
            SPAWN_AREA = { {-12.897121; 3.092595; -7.727854}, {-4.540559; 3.092595; -16.911572} }, -- this consits of two points representing opposite corners of a not-rotated cuboid in 3D space
            SPAWN_DIR = { 0.900399, 0.000000, 0.435065 }
        },
        CT = {
            SPAWN_AREA = { {15.84541; -4.300481; 81.080124}, {26.495136; -4.295822; 76.572525} }, -- this consits of two points representing opposite corners of a not-rotated cuboid in 3D space
            SPAWN_DIR = { 0.900399, 0.000000, 0.435065 }
        }
    },
    BOMBSITES = {
        { {48.551144; 0.0; 75.342354}, {41.617443; 5.0; 81.552139} }, -- this consits of two points representing opposite corners of a not-rotated cuboid in 3D space
        { {-33.822891; -2.0; 91.44397}, {-25.660427; 4.0; 81.516945} }, -- this consits of two points representing opposite corners of a not-rotated cuboid in 3D space
    },
    WELCOME_CAMERA = {
        START = {
            POS = {14.831802, 14.937092, 2.560905},
            ROT = {-0.256033, -0.270936, 0.966668, 0.000000},
        },
        STOP = {
            POS = {4.185309, -2.159345, 52.666584},
            ROT = {-0.961907, -0.041701, -0.273376, 0.000000},
        },
        TIME = 20000,
    },
}
