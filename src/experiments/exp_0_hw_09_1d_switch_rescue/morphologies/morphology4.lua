local pipuckDis = 0.7
local droneDis = 1.5
local height = 1.8

return 
{ 	robotTypeS = "drone",
    positionV3 = vector3(),
    orientationQ = quaternion(),
    children = {
    {	robotTypeS = "pipuck",
        positionV3 = vector3(-pipuckDis, pipuckDis, -height),
        orientationQ = quaternion(0, vector3(0,0,1)),
        reference = true,
    },

    {	robotTypeS = "pipuck",
        positionV3 = vector3(pipuckDis*0.5, pipuckDis*0.5, -height),
        orientationQ = quaternion(0, vector3(0,0,1)),
        children = {
        {	robotTypeS = "pipuck",
            positionV3 = vector3(pipuckDis*0.3, pipuckDis*0.3, -height),
            orientationQ = quaternion(0, vector3(0,0,1)),
        },
        {	robotTypeS = "pipuck",
            positionV3 = vector3(0, pipuckDis*0.3, -height),
            orientationQ = quaternion(0, vector3(0,0,1)),
        },
    }},

    { 	robotTypeS = "drone",
        positionV3 = vector3(0, droneDis, 0),
        orientationQ = quaternion(),
        children = {
        {	robotTypeS = "pipuck",
            positionV3 = vector3(pipuckDis*0.5, -pipuckDis*0.5, -height),
            orientationQ = quaternion(0, vector3(0,0,1)),
            children = {
            {	robotTypeS = "pipuck",
                positionV3 = vector3(pipuckDis*0.3, -pipuckDis*0.3, -height),
                orientationQ = quaternion(0, vector3(0,0,1)),
            },
            {	robotTypeS = "pipuck",
                positionV3 = vector3(0, -pipuckDis*0.3, -height),
                orientationQ = quaternion(0, vector3(0,0,1)),
            },
        }},
    }},
}}
