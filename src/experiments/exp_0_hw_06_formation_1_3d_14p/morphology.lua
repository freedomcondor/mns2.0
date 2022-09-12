MorphologyCommon = require("MorphologyCommon")

local pipuckDis = 0.8
local droneDis = 1.6
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