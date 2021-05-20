# experiment/testing/02_allocate

configure_file( vns.argos.in     vns.argos)
configure_file( drone.lua        drone.lua)
configure_file( pipuck.lua       pipuck.lua)

configure_file(morphology_decentralize.lua
               morphology_decentralize.lua
               COPYONLY)

configure_file(morphology_centralize.lua
               morphology_centralize.lua
               COPYONLY)