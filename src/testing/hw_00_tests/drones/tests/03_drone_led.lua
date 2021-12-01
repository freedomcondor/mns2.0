function init()
	print("I am drone")
	--ShowTable(robot.directional_leds)
	ShowTable(robot.leds)
	robot.leds.set_leds("blue")
	count = 0
end
 
function step()
	count = count + 1
	local index = math.floor(count / 20)
	robot.leds.set_leds("blue")
	-- index from 1 to 4
	if count % 20 == 0 then
		if index % 5 == 0 then
			print("robot.leds.set_leds(0,0,0)")
		else
			print("robot.leds.set_led_index(" .. tostring(index % 5) .. ", \"red\")")
		end
	end
	if index % 5 == 0 then
		--robot.leds.set_leds(255,255,255)
		robot.leds.set_leds(0,0,0)
	else
		robot.leds.set_led_index(index % 5, "red")
	end
end
 
function reset()
end
 
function destroy()
	print("I am destroy")
	robot.leds.set_leds(0,0,0)
end


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