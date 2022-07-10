MorphologyCommon = require("MorphologyCommon")

local pipuckDis = 0.7
local droneDis = 1.5
local height = 1.5
local octo_ratio = 0.4

return
{ 	robotTypeS = "drone",
    positionV3 = position,
    orientationQ = orientationQ,
    children = {
    {	robotTypeS = "pipuck",
        positionV3 = vector3(pipuckDis, pipuckDis*octo_ratio, -height),
        orientationQ = quaternion(0, vector3(0,0,1)),
        reference = true
    },
    {	robotTypeS = "drone",
        positionV3 = vector3(0, droneDis, 0),
        orientationQ = quaternion(0, vector3(0,0,1)),
    },

    {	robotTypeS = "pipuck",
        positionV3 = vector3(pipuckDis*octo_ratio, pipuckDis, -height),
        orientationQ = quaternion(0, vector3(0,0,1)),
        children = { 

        {	robotTypeS = "pipuck",
            positionV3 = vector3(-pipuckDis*octo_ratio - pipuckDis*octo_ratio, pipuckDis - pipuckDis, 0),
            orientationQ = quaternion(0, vector3(0,0,1)),
            children = { 

            {	robotTypeS = "pipuck",
                    positionV3 = vector3(-pipuckDis - (-pipuckDis*octo_ratio), pipuckDis*octo_ratio - pipuckDis, 0),
                    orientationQ = quaternion(0, vector3(0,0,1)),
                    children = { 

                {	robotTypeS = "pipuck",
                    positionV3 = vector3(-pipuckDis - (-pipuckDis), -pipuckDis*octo_ratio - pipuckDis*octo_ratio, 0),
                    orientationQ = quaternion(0, vector3(0,0,1)),
                    children = { 

                {  	robotTypeS = "pipuck",
                    positionV3 = vector3(-pipuckDis*octo_ratio - (-pipuckDis), -pipuckDis - (-pipuckDis*octo_ratio), 0),
                    orientationQ = quaternion(0, vector3(0,0,1)),
                    children = { 

                {	robotTypeS = "pipuck",
                    positionV3 = vector3(pipuckDis*octo_ratio - (-pipuckDis*octo_ratio), -pipuckDis - (-pipuckDis), 0),
                    orientationQ = quaternion(0, vector3(0,0,1)),
                    children = { 

                {	robotTypeS = "pipuck",
                    positionV3 = vector3(pipuckDis- (pipuckDis*octo_ratio), -pipuckDis*octo_ratio - (-pipuckDis), 0),
                    orientationQ = quaternion(0, vector3(0,0,1)),
                    children = { 

                }},

                }},

                }},

                }},
            }},

            {	robotTypeS = "pipuck",
                positionV3 = vector3(-pipuckDis - (-pipuckDis*octo_ratio), -(pipuckDis*octo_ratio - pipuckDis), 0),
                orientationQ = quaternion(0, vector3(0,0,1)),
                children = { 

            {	robotTypeS = "pipuck",
                positionV3 = vector3(-pipuckDis - (-pipuckDis), -(-pipuckDis*octo_ratio - pipuckDis*octo_ratio), 0),
                orientationQ = quaternion(0, vector3(0,0,1)),
                children = { 

            {  	robotTypeS = "pipuck",
                positionV3 = vector3(-pipuckDis*octo_ratio - (-pipuckDis), -(-pipuckDis - (-pipuckDis*octo_ratio)), 0),
                orientationQ = quaternion(0, vector3(0,0,1)),
                children = { 

            {	robotTypeS = "pipuck",
                positionV3 = vector3(pipuckDis*octo_ratio - (-pipuckDis*octo_ratio), -(-pipuckDis - (-pipuckDis)), 0),
                orientationQ = quaternion(0, vector3(0,0,1)),
                children = { 

            {	robotTypeS = "pipuck",
                positionV3 = vector3(pipuckDis- (pipuckDis*octo_ratio), -(-pipuckDis*octo_ratio - (-pipuckDis)), 0),
                orientationQ = quaternion(0, vector3(0,0,1)),
                children = { 
                {	robotTypeS = "pipuck",
                    positionV3 = vector3(pipuckDis- (pipuckDis), (-pipuckDis*octo_ratio - pipuckDis*octo_ratio), 0),
                    orientationQ = quaternion(0, vector3(0,0,1)),
                },
            }},
            }},
            }},
            }},
            }},
        }},
    }},
}}
