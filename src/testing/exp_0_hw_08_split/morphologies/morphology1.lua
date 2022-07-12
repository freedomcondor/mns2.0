MorphologyCommon = require("MorphologyCommon")

local pipuckDis = 0.7
local droneDis = 1.5
local height = 1.8

return 
{ 	robotTypeS = "drone",
    positionV3 = vector3(),
    orientationQ = quaternion(),
    children = {
    {	robotTypeS = "pipuck",
        positionV3 = vector3(pipuckDis*0.5, pipuckDis, -height),
        orientationQ = quaternion(0, vector3(0,0,1)),
        reference = true,
    },

    {	robotTypeS = "pipuck",
        positionV3 = vector3(-pipuckDis*0.5, -pipuckDis, -height),
        orientationQ = quaternion(0, vector3(0,0,1)),
        calcBaseValue = function(base, current, target)
            --local base_target_V3 = target - base
            --local base_current_V3 = current - base
            local base_target_V3 = base - target
            local base_current_V3 = current - target 
            base_target_V3.z = 0
            base_current_V3.z = 0
            local dot = base_current_V3:dot(base_target_V3:normalize())
            if dot < 0 then 
                return dot 
            else
                local x = dot
                local x2 = dot ^ 2
                local l = base_current_V3:length()
                local y2 = l ^ 2 - x2
                elliptic_distance2 = x2 + (1/4) * y2
                return elliptic_distance2
            end
        end,
        children = {
        {	robotTypeS = "pipuck",
            positionV3 = vector3(pipuckDis*0.5 - (-pipuckDis*0.5), -pipuckDis - (-pipuckDis), -height),
            orientationQ = quaternion(0, vector3(0,0,1)),
        },
        {	robotTypeS = "pipuck",
            positionV3 = vector3(-pipuckDis*0.5 - (-pipuckDis*0.5), pipuckDis - (-pipuckDis), -height),
            orientationQ = quaternion(0, vector3(0,0,1)),
        },
    }},

    { 	robotTypeS = "drone",
        positionV3 = vector3(0, droneDis, 0),
        orientationQ = quaternion(),
		split = true,
        children = {
            {	robotTypeS = "pipuck",
                positionV3 = vector3(pipuckDis*0.5, pipuckDis, -height),
                orientationQ = quaternion(0, vector3(0,0,1)),
            },
            {	robotTypeS = "pipuck",
                positionV3 = vector3(-pipuckDis*0.5, pipuckDis, -height),
                orientationQ = quaternion(0, vector3(0,0,1)),
            },  
        },
    },
}}