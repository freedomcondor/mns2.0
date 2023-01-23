require("morphologiesGenerator")

local pipuckDis = 0.7
local droneDis = 1.5
local height = 1.8

function create_left2_right1_line_morphology(scale, droneDis, pipuckDis, height)
    return 
    {	robotTypeS = "drone",
        positionV3 = vector3(),
        orientationQ = quaternion(),
        children = {
        {	robotTypeS = "pipuck",
            positionV3 = vector3(pipuckDis/2*math.sqrt(3), pipuckDis/2, -height),
            orientationQ = quaternion(0, vector3(0,0,1)),
        },
        {	robotTypeS = "pipuck",
            positionV3 = vector3(-pipuckDis/2*math.sqrt(3), pipuckDis/2, -height),
            orientationQ = quaternion(0, vector3(0,0,1)),
        },
        {	robotTypeS = "pipuck",
            positionV3 = vector3(pipuckDis/2*math.sqrt(3), -pipuckDis/2, -height),
            orientationQ = quaternion(0, vector3(0,0,1)),
        },
        {	robotTypeS = "pipuck",
            positionV3 = vector3(-pipuckDis/2*math.sqrt(3), -pipuckDis/2, -height),
            orientationQ = quaternion(0, vector3(0,0,1)),
        },
        create_1drone_4pipuck_children_node(droneDis, pipuckDis, height, 
            vector3(droneDis/2*math.sqrt(3), droneDis/2, 0),
            quaternion(-math.pi/2, vector3(0,0,1))
        ),
        create_1drone_4pipuck_children_node(droneDis, pipuckDis, height, 
            vector3(droneDis/2*math.sqrt(3), -droneDis/2, 0),
            quaternion(math.pi/2, vector3(0,0,1)),
            true
        ),
        create_1drone_4pipuck_children_node(droneDis, pipuckDis, height, 
            vector3(-droneDis/2*math.sqrt(3), droneDis/2, 0),
            quaternion(-math.pi/2, vector3(0,0,1)),
            true
        ),
        create_1drone_4pipuck_children_node(droneDis, pipuckDis, height, 
            vector3(-droneDis/2*math.sqrt(3), -droneDis/2, 0),
            quaternion(math.pi/2, vector3(0,0,1))
        ),
        create_3drone_12pipuck_children_chain(scale, droneDis, pipuckDis, height, 
            vector3(0, droneDis, 0), 
            quaternion(-math.pi/2, vector3(0,0,1)),
            "left"
        ),
        create_3drone_12pipuck_children_chain(scale-1, droneDis, pipuckDis, height, 
            vector3(0, -droneDis, 0), 
            quaternion(math.pi/2, vector3(0,0,1)),
            "right"
        ),
    }}
end

local morph = create_left2_right1_line_morphology(2, droneDis, pipuckDis, height)
morph.children[1].reference = true

return morph
