local myType = robot.params.my_type

package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/api/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/vns/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/?.lua"

pairs = require("RandomPairs")

-- includes -------------
logger = require("Logger")
local api = require(myType .. "API")
local VNS = require("VNS")
local BT = require("DynamicBehaviorTree")
logger.enable()
logger.disable("Allocator")
logger.disable("droneAPI")
logger.disable("Stabilizer")
logger.enable()
logger.enableFileLog()

-- datas ----------------
local bt
--local vns     -- global vns to make vns appear in lua_editor
local structure = require("morphology")

-- argos functions ------
--- init
function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create(myType)
	reset()
end

--- reset
function reset()
	vns.reset(vns)
	vns.setGene(vns, structure)
	vns.setMorphology(vns, structure)
	vns.allocator.mode_switch = "stationary"
	bt = BT.create
	{ type = "sequence", children = {
		create_stationary_visual_node(vns),
		VNS.create_vns_core_node(vns),
	}}
end

--- step
function step()
	-- prestep
	logger(robot.id, "-----------------------")
	api.preStep()
	vns.preStep(vns)

	-- step
	bt()

	-- poststep
	vns.postStep(vns)
	api.postStep()

	-- debug
	api.debug.showChildren(vns)

	vns.debug.logInfo(vns, {
		idN = true,
		idS = true,
		scale = true,
		connector = true,
	})
	logger("wifi")
	logger(robot.radios.wifi.recv)
end

--- destroy
function destroy()
end

---------------------------------------------------------
local string = [[
return function()
	print("I'm crazy!") 
	vns.api.debug.drawRing("red", vector3(0,0,0), 0.2)
	return false, true
end
]]
---------------------------------------------------------

function create_stationary_visual_node(vns)
return function()
	-- set robots locations.
	local locations = {}
	-- pipucks
	local dis = 0.3 
	local row = 2
	local col = 3
	for i = 1, row do
		for j = 1, col do
			local id = (i-1) * col + j + 10
			local robotID = "pipuck" .. id
			locations[robotID] = vector3(- j * dis, - i * dis, 0)
		end
	end
	--[[
	-- drones
	local dis = 0.3
	local row = 1
	local col = 1
	for i = 1, row do
		for j = 1, col do
			local id = (i-1) * col + j
			local robotID = "drone" .. id
			locations[robotID] = vector3(i * dis, j * dis, 1.8)
		end
	end
	--]]

	-- see robots
	vns.connector.seenRobots = {}

	-- see pipucks
	local row = 2
	local col = 3
	for i = 1, row do
		for j = 1, col do
			local id = (i-1) * col + j + 10
			local robotID = "pipuck" .. id
			if robotID ~= robot.id then
				local relative_location = locations[robotID] - locations[robot.id]
				vns.connector.seenRobots[robotID] = {
					idS = robotID,
					robotTypeS = "pipuck",
					positionV3 = vns.api.virtualFrame.V3_RtoV(relative_location),
					orientationQ = vns.api.virtualFrame.Q_RtoV(quaternion()),
				}
			end
		end
	end

	-- see drones 
	--[[
	local row = 1
	local col = 1
	for i = 1, row do
		for j = 1, col do
			local id = (i-1) * col + j
			local robotID = "drone" .. id
			if robotID ~= robot.id then
				local relative_location = locations[robotID] - locations[robot.id]
				vns.connector.seenRobots[robotID] = {
					idS = robotID,
					robotTypeS = "pipuck",
					positionV3 = vns.api.virtualFrame.V3_RtoV(relative_location),
					orientationQ = vns.api.virtualFrame.Q_RtoV(quaternion()),
				}
			end
		end
	end
	--]]
end
end