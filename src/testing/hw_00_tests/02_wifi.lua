function ShowTable(table, number, skipindex)
	-- number means how many indents when printing
	if number == nil then number = 0 end
	if type(table) ~= "table" then return nil end
 
	for i, v in pairs(table) do
	   local str = "DebugMSG:\t\t"
	   for j = 1, number do
		  str = str .. "\t"
	   end
 
	   str = str .. tostring(i) .. "\t"
 
	   if i == skipindex then
		  print(str .. "SKIPPED")
	   else
		  if type(v) == "table" then
			 print(str)
			 ShowTable(v, number + 1, skipindex)
		  else
			 str = str .. tostring(v)
			 print(str)
		  end
	   end
	end
end

function init()
   count = 0
end

function step()
   count = count + 1

   print("--------------------")
   print("I am " .. robot.id)

   local toS = "ALLMSG"

   if robot.id == "pipuck11" then toS = "pipuck12" end
   if robot.id == "pipuck12" then toS = "pipuck13" end
   if robot.id == "pipuck13" then toS = "pipuck14" end
   if robot.id == "pipuck14" then toS = "pipuck15" end
   if robot.id == "pipuck15" then toS = "pipuck16" end
   if robot.id == "pipuck16" then toS = "pipuck11" end

   data1 = {
      vec = vector3(-1.111, 2.222, -3.333),
      str = robot.id,
      num = count,
	  fromS = robot.id,
	  toS = toS,
   }

   data2 = {
      str = "data2",
	  fromS = robot.id,
	  toS = "ALLMSG",
   }

   robot.radios.wifi.send(data1)
   robot.radios.wifi.send(data2)

   ShowTable(robot.radios.wifi.recv)
   --[[
   for index, message in pairs(robot.radios.wifi.recv) do
      log(tostring(message.vec))
   end
   --]]
end

function reset()
end

function destroy()
end
