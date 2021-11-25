package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/api/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
--package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/VNS/?.lua"

local api = require("builderbotAPI")

function init()
end

function step()
	api.debug.drawArrow("blue", vector3(), vector3(1,0,0))
	robot.radios.wifi.send({a=1, b=2})
end

function reset()
end

function destroy()
end