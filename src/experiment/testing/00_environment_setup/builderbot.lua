package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/api/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/utils/?.lua"

local api = require("builderbotAPI")

function init()
end

function step()
	api.debug.drawArrow("blue", vector3(), vector3(1,0,0))
end

function reset()
end

function destroy()
end