local menus = {}


function menus.DrawMainMenu()
    local intSlabWidth = 205	-- the width of the main menu slab. Change this to change appearance.
	local intSlabHeight = 300 	-- the height of the main menu slab
	local fltSlabWindowX = love.graphics.getWidth() / 2 - intSlabWidth / 2
	local fltSlabWindowY = love.graphics.getHeight() / 2 - intSlabHeight / 2

	-- try to centre the Slab window
	-- note: Border is the border between the window and the layout
	Slab.BeginWindow('MainMenu', {Title = "Main menu " .. gstrGameVersion,X=fltSlabWindowX,Y=fltSlabWindowY,W=intSlabWidth,H=intSlabHeight,Border=0,AutoSizeWindow=false, AllowMove=false,AllowResize=false,NoSavedSettings=true})

	Slab.BeginLayout("MMLayout",{AlignX="center"})
    
		Slab.NewLine()
		if Slab.Button("New game",{W=155}) then
			fun.AddScreen("World")
 		end
		Slab.NewLine()
 
		-- if Slab.Button("Resume game",{W=155}) then
			-- fun.AddScreen("Vessel")
		-- end
		-- Slab.NewLine()        

		-- if Slab.Button("Load game",{W=155}) then
            -- fun.LoadGame()
			-- fun.AddScreen("World")
		-- end
		-- Slab.NewLine()

		-- if Slab.Button("Save game",{W=155}) then
			-- fun.SaveGame()      --! need some sort of feedback here
		-- end
		-- Slab.NewLine()

		-- if Slab.Button("Credits",{W=155}) then
			-- fun.AddScreen("Credits")		--!
		-- end
		-- Slab.NewLine()
		
		local exitstatus
		if Slab.Button("Exit",{W=155}) then
			love.event.quit(exitstatus)
		end
		Slab.NewLine()

		-- ** Increase window height if adding new things ** --

		-- add some white space for presentation
		Slab.NewLine()
		if Slab.Button("Hidden",{Invisible=true}) then
		end

	Slab.EndLayout()
	Slab.EndWindow()
end


return menus

