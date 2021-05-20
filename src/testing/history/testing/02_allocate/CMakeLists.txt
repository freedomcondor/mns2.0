# experiment/testing/02_allocate

configure_file( vns.argos.in     vns.argos)
configure_file( drone.lua        drone.lua)
configure_file( pipuck.lua       pipuck.lua)

configure_file(morphology.lua
               morphology.lua
               COPYONLY)
configure_file(morphology_classic.lua
               morphology_classic.lua
               COPYONLY)
configure_file(morphology_classic_variation.lua
               morphology_classic_variation.lua
               COPYONLY)
configure_file(morphology_5_children.lua
               morphology_5_children.lua
               COPYONLY)