local dis = 1.0
local wing_x_offset = -dis/3
return 
-- 1
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(wing_x_offset, -dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(wing_x_offset, dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
-- 2
{	robotTypeS = "drone",
	positionV3 = vector3(-dis, 0, 0),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(wing_x_offset, -dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(wing_x_offset, dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
-- 3
{	robotTypeS = "drone",
	positionV3 = vector3(-dis, 0, 0),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(wing_x_offset, -dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(wing_x_offset, dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
-- 4
{	robotTypeS = "drone",
	positionV3 = vector3(-dis, 0, 0),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(wing_x_offset, -dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(wing_x_offset, dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
-- 5
{	robotTypeS = "drone",
	positionV3 = vector3(-dis, 0, 0),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(-dis*2/3, -dis/2, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(-dis*2/3, dis/2, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
}} -- 5
}} -- 4
}} -- 3
}} -- 2
}} -- 1
