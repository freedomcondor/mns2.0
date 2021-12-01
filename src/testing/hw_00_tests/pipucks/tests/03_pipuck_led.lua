function init()
	print("I am pipuck")
	ShowTable(robot.leds)
	count = 0
end
 
function step()
	count = count + 1
	robot.leds.set_ring_leds(true)
	robot.leds.set_body_led(true)
end

function operation(index)
	if index == 0 then
		robot.leds.set_body_led(true)
	elseif index == 1 then
		robot.leds.set_body_led(false)
		robot.leds.set_front_led(true)
	end
end
 
function reset()
end
 
function destroy()
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