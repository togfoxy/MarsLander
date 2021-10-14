local functions = {}

function functions.AddScreen(strNewScreen)
	table.insert(garrCurrentScreen, strNewScreen)
end

function functions.RemoveScreen()
	table.remove(garrCurrentScreen)
	if #garrCurrentScreen < 1 then
	
		--if success then
			love.event.quit()       --! this doesn't dothe same as the EXIT button
		--end
	end
end

function functions.GetMoreTerrain()
-- determines the next bit of terrain and adds that to the terrain table

	for i = #garrGround + 1, #garrGround + 2000 do
	
		local newgroundaltitude = garrGround[i-1] + love.math.random (-5,5)
		
		if newgroundaltitude > (gintScreenHeight * 0.90) then newgroundaltitude = (gintScreenHeight * 0.90) end
		if newgroundaltitude < (gintScreenHeight * 0.65) then newgroundaltitude = (gintScreenHeight * 0.65) end
	
		table.insert(garrGround, newgroundaltitude)
	end
end


return functions