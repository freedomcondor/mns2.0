local file
local count 

function write(branch, baseV3, baseQ)
    count = count + 1
    if branch.idN ~= count then print("warning: branch count doesn't match\n") end

    baseV3 = baseV3 or vector3()
    baseQ = baseQ or quaternion()
    baseV3 = vector3(branch.positionV3):rotate(baseQ) + baseV3
    baseQ = branch.orientationQ * baseQ

    local z = baseV3.z
    if branch.robotTypeS == "drone" then z = 1.5 end
    file:write("\tVector3(" .. 
               tostring(baseV3.x) .. ", " ..
               tostring(baseV3.y) .. ", " ..
               tostring(z) .. 
               "),\n")

    if branch.children ~= nil then
        for i, child in ipairs(branch.children) do
            write(child, baseV3, baseQ)
        end
    end
end

function generate(morphology, file_name)
    file = io.open(file_name, "w")

    file:write("{\n")

    count = 0;
    write(morphology)

    file:write("};\n")

    file:close()
end

return generate