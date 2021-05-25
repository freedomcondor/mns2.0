package.path = package.path .. ";@CMAKE_SOURCE_DIR@/scripts/logReader/?.lua"

logReader = require("logReader")

logReader.loadData("./logs")