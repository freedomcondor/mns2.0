--[[
--	Pipuck connector
--	the Pipuck listen to drone's recruit message, with deny
--]]

local PipuckConnector = {}

function PipuckConnector.preStep(vns)
	vns.connector.seenRobots = {}
end

function PipuckConnector.step(vns)
	-- do nothing
end

function PipuckConnector.create_pipuckconnector_node(vns)
	return function()
		vns.PipuckConnector.step(vns)
		return false, true
	end
end

return PipuckConnector
