MorphologyCommon = require("MorphologyCommon")

local pipuckDis = 0.7
local droneDis = 1.5
local height = 1.8

return 
{   robotTypeS = "drone",
    positionV3 = vector3(),
    orientationQ = quaternion(),
    children = {
    {   robotTypeS = "drone",
        positionV3 = vector3(-pipuckDis * 2, pipuckDis*2/3, height),
        orientationQ = quaternion(),
    },

    {   robotTypeS = "pipuck",
        positionV3 = vector3(0, pipuckDis/2, 0),
        orientationQ = quaternion(),
    },

    {   robotTypeS = "pipuck",
        positionV3 = vector3(-pipuckDis/7*4, pipuckDis/2, 0),
        orientationQ = quaternion(),
        reference = true,
        children = {
        {   robotTypeS = "pipuck",
            positionV3 = vector3(-pipuckDis/7*4, 0, 0),
            orientationQ = quaternion(),
            children = {
            {   robotTypeS = "pipuck",
                positionV3 = vector3(-pipuckDis/7*4, 0, 0),
                orientationQ = quaternion(),
                children = {
                {   robotTypeS = "pipuck",
                    positionV3 = vector3(-pipuckDis/7*4, 0, 0),
                    orientationQ = quaternion(),
                    children = {
                    {   robotTypeS = "pipuck",
                        positionV3 = vector3(-pipuckDis/7*4, 0, 0),
                        orientationQ = quaternion(),
                    }
                }},
            }},
        }},
    }},
}}