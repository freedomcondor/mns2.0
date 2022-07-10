MorphologyCommon = require("MorphologyCommon")

local pipuckDis = 0.7
local droneDis = 1.5
local height = 1.5
local octo_ratio = 0.4

return
{ 	robotTypeS = "drone",
    positionV3 = vector3(),
    orientationQ = quaternion(),
    children = {
    { 	robotTypeS = "drone",
        positionV3 = vector3(0, droneDis, 0),
        orientationQ = quaternion(),
    },
    { 	robotTypeS = "drone",
        positionV3 = vector3(0, -droneDis, 0),
        orientationQ = quaternion(),
    },
    { 	robotTypeS = "pipuck",
        positionV3 = vector3(pipuckDis, 0, -height),
        orientationQ = quaternion(),
        reference = true,
    },

    -- chain start
    { 	robotTypeS = "pipuck",
        positionV3 = vector3(-pipuckDis, 0, -height),
        orientationQ = quaternion(),
        children = {
        -- left chain 1
        { 	robotTypeS = "pipuck",
            positionV3 = vector3(pipuckDis/2, pipuckDis/2*math.sqrt(3), 0),
            orientationQ = quaternion(),
            children = {
            -- go left 2
            { 	robotTypeS = "pipuck",
                positionV3 = vector3(-pipuckDis/2, pipuckDis/2*math.sqrt(3), 0),
                orientationQ = quaternion(),
                children = {
                -- go left 3
                { 	robotTypeS = "pipuck",
                    positionV3 = vector3(pipuckDis/2, pipuckDis/2*math.sqrt(3), 0),
                    orientationQ = quaternion(),
                }
            }},
            -- go up 2
            { 	robotTypeS = "pipuck",
                positionV3 = vector3(pipuckDis, 0, 0),
                orientationQ = quaternion(),
                children = {
                -- go left 3
                { 	robotTypeS = "pipuck",
                    positionV3 = vector3(pipuckDis/2, pipuckDis/2*math.sqrt(3), 0),
                    orientationQ = quaternion(),
                    children = {
                    -- go left 4
                    { 	robotTypeS = "pipuck",
                        positionV3 = vector3(-pipuckDis/2, pipuckDis/2*math.sqrt(3), 0),
                        orientationQ = quaternion(),
                        children = {
                    }},
                }},
            }},
        }},
        -- right chain 1
        { 	robotTypeS = "pipuck",
            positionV3 = vector3(pipuckDis/2, -pipuckDis/2*math.sqrt(3), 0),
            orientationQ = quaternion(),
            children = {
            -- go right 2
            { 	robotTypeS = "pipuck",
                positionV3 = vector3(-pipuckDis/2, -pipuckDis/2*math.sqrt(3), 0),
                orientationQ = quaternion(),
                children = {
                -- go right 3
                { 	robotTypeS = "pipuck",
                    positionV3 = vector3(pipuckDis/2, -pipuckDis/2*math.sqrt(3), 0),
                    orientationQ = quaternion(),
                }
            }},
            -- go up 2
            { 	robotTypeS = "pipuck",
                positionV3 = vector3(pipuckDis, 0, 0),
                orientationQ = quaternion(),
                children = {
                -- go right 3
                { 	robotTypeS = "pipuck",
                    positionV3 = vector3(pipuckDis/2, -pipuckDis/2*math.sqrt(3), 0),
                    orientationQ = quaternion(),
                    children = {
                    -- go right 4
                    { 	robotTypeS = "pipuck",
                        positionV3 = vector3(-pipuckDis/2, -pipuckDis/2*math.sqrt(3), 0),
                        orientationQ = quaternion(),
                        children = {
                    }},
                }},
            }},
        }},    
    }},
}}