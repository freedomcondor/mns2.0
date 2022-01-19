configure_file( vns_template.in.argos
                vns_template.argos)

configure_file( common.in.lua    common.lua)

configure_file( morphology.lua  morphology.lua  COPYONLY)

configure_file( run.in.py
                run.py)