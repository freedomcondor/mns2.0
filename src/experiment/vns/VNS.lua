local VNS = {VNSCLASS = true}
VNS.__index = VNS

VNS.Msg = require("Message")

VNS.Connector = require("Connector")
VNS.DroneConnector = require("DroneConnector")
VNS.PipuckConnector = require("PipuckConnector")

VNS.ScaleManager = require("ScaleManager")
VNS.Assigner = require("Assigner")
VNS.Allocator = require("Allocator")
--VNS.Allocator = require("Allocator_old")
VNS.Avoider = require("Avoider")
--[[
VNS.Spreader = require("Spreader")
--]]
VNS.Driver= require("Driver")

VNS.Modules = {
	VNS.DroneConnector,
	VNS.PipuckConnector,
	VNS.Connector,
	VNS.Assigner,

	VNS.ScaleManager,

	VNS.Allocator,
	VNS.Avoider,
--[[
	VNS.Spreader,
--]]
	VNS.Driver,
}

--[[
--	vns = {
--		idS
--		brainS
--		robotTypeS
--		scale
--		
--		parentR
--		childrenRT
--
--	}
--]]

function VNS.create(myType)

	-- a robot =  {
	--     idS,
	--     positionV3, 
	--     orientationQ,
	--     robotTypeS = "drone",
	-- }

	local vns = {}
	vns.robotTypeS = myType

	setmetatable(vns, VNS)

	for i, module in ipairs(VNS.Modules) do
		if type(module.create) == "function" then
			module.create(vns)
		end
	end

	VNS.reset(vns)
	return vns
end

function VNS.reset(vns)
	vns.parentR = nil
	vns.childrenRT = {}

	vns.idS = VNS.Msg.myIDS()
	vns.idN = robot.random.uniform()

	for i, module in ipairs(VNS.Modules) do
		if type(module.reset) == "function" then
			module.reset(vns)
		end
	end
end

function VNS.preStep(vns)
	VNS.Msg.preStep()
	for i, module in ipairs(VNS.Modules) do
		if type(module.preStep) == "function" then
			module.preStep(vns)
		end
	end
end

function VNS.postStep(vns)
	for i = #VNS.Modules, 1, -1 do
		local module = VNS.Modules[i]
		if type(module.postStep) == "function" then
			module.postStep(vns)
		end
	end
	vns.Msg.postStep()
end

function VNS.addChild(vns, robotR)
	for i, module in ipairs(VNS.Modules) do
		if type(module.addChild) == "function" then
			module.addChild(vns, robotR)
		end
	end
end
function VNS.deleteChild(vns, idS)
	for i = #VNS.Modules, 1, -1 do
		local module = VNS.Modules[i]
		if type(module.deleteChild) == "function" then
			module.deleteChild(vns, idS)
		end
	end
end

function VNS.addParent(vns, robotR)
	for i, module in ipairs(VNS.Modules) do
		if type(module.addParent) == "function" then
			module.addParent(vns, robotR)
		end
	end
end
function VNS.deleteParent(vns)
	for i = #VNS.Modules, 1, -1 do
		local module = VNS.Modules[i]
		if type(module.deleteParent) == "function" then
			module.deleteParent(vns)
		end
	end
end

function VNS.setGene(vns, morph)
	for i, module in ipairs(VNS.Modules) do
		if type(module.setGene) == "function" then
			module.setGene(vns, morph)
		end
	end
end

---- Behavior Tree Node ------------------------------------------
function VNS.create_preconnector_node(vns)
	local pre_connector_node
	if vns.robotTypeS == "drone" then
		return VNS.DroneConnector.create_droneconnector_node(vns)
	elseif vns.robotTypeS == "pipuck" then
		return VNS.PipuckConnector.create_pipuckconnector_node(vns)
	elseif vns.robotTypeS == "builderbot" then
		return VNS.PipuckConnector.create_pipuckconnector_node(vns) -- TODO
	end
end

function VNS.create_vns_node_without_driver(vns)
	return 
	{type = "sequence", children = {
		vns.create_preconnector_node(vns),
		vns.Connector.create_connector_node(vns),
		vns.Assigner.create_assigner_node(vns),
		vns.ScaleManager.create_scalemanager_node(vns),
		vns.Allocator.create_allocator_node(vns),
		vns.Avoider.create_avoider_node(vns),
		--[[
		vns.Spreader.create_spreader_node(vns),
		]]
		--vns.Driver.create_driver_node(vns),
	}}
end

function VNS.create_vns_node(vns)
	return { 
		type = "sequence", children = {
		vns.create_vns_node_without_driver(vns),
		vns.Driver.create_driver_node(vns),
	}}
end

return VNS
