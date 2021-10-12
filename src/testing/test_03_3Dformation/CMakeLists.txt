configure_file( vns.in.argos     vns.argos)
configure_file( drone.in.lua     drone.lua)
configure_file( pipuck.in.lua    pipuck.lua)

configure_file(morphology_cube.lua 
               morphology_cube.lua 
               COPYONLY)

configure_file(morphology_octahedron.lua 
               morphology_octahedron.lua 
               COPYONLY)