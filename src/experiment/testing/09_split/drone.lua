package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/api/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/utils/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/vns/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/?.lua"

pairs = require("RandomPairs")

-- includes -------------
logger = require("Logger")
local api = require("droneAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.enable()

-- datas ----------------
stepCount = 0
local bt
--local vns
--local structure = require("morphology_classic_variation")
local structure = require("morphology_classic")
--local structure = require("morphology_5_children")

-- argos functions ------
--- init
function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("drone")
	reset()
end

--- reset
function reset()
	vns.reset(vns)
	if vns.idS == "drone1" then vns.idN = 1 end
	vns.setGene(vns, structure)
	bt = BT.create(VNS.create_vns_node(vns))
end

--- step
function step()
	-- prestep
	--logger(robot.id, "-----------------------")
	api.preStep()
	vns.preStep(vns)

	-- step
	bt()

	local dis = 0.5
	if robot.id == "drone4" and stepCount == 350 then
		logger("split")
		vns.deleteChild(vns, "drone2")
		vns.Msg.send("drone2", "split", {morphology = 
			{	robotTypeS = "drone",
				positionV3 = vector3(0, 0, 0),
				orientationQ = quaternion(0, vector3(0,0,1)),
				children = {
				{	robotTypeS = "pipuck",
					positionV3 = vector3(-dis, -dis, 0),
					orientationQ = quaternion(0, vector3(0,0,1)),
				},
				{	robotTypeS = "pipuck",
					positionV3 = vector3(-dis, dis, 0),
					orientationQ = quaternion(0, vector3(0,0,1)),
				},
			}}
		})
	end
	if robot.id == "drone2" and stepCount >= 350 then
		vns.Driver.move(vector3(-0.05, 0, 0), vector3())
	end

	stepCount = stepCount + 1

	-- poststep
	vns.postStep(vns)
	api.droneMaintainHeight(1.5)
	api.postStep()

	-- debug
	api.debug.showChildren(vns)
	--api.debug.showParent(vns)

end

--- destroy
function destroy()
end
