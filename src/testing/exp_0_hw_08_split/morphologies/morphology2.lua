MorphologyCommon = require("MorphologyCommon")

local pipuckDis = 0.7
local droneDis = 1.5
local height = 1.8

return
{ 	robotTypeS = "drone",
	positionV3 = vector3(0, droneDis, 0),
	orientationQ = quaternion(),
	ranger = true,
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
}