local menus = {}


function menus.DrawMainMenu()
    local intSlabWidth = 205	-- the width of the main menu slab. Change this to change appearance.
	local intSlabHeight = 325 	-- the height of the main menu slab
	local fltSlabWindowX = love.graphics.getWidth() / 2 - intSlabWidth / 2
	local fltSlabWindowY = love.graphics.getHeight() / 2 - intSlabHeight / 2

	-- try to centre the Slab window
	-- note: Border is the border between the window and the layout
	Slab.BeginWindow('MainMenu', {Title = "Main menu " .. gstrGameVersion,X=fltSlabWindowX,Y=fltSlabWindowY,W=intSlabWidth,H=intSlabHeight,Border=0,AutoSizeWindow=false, AllowMove=false,AllowResize=false,NoSavedSettings=true})

	Slab.BeginLayout("MMLayout",{AlignX="center"})
    
		Slab.NewLine()
		if Slab.Button("New game",{W=155}) then
			fun.ResetGame()
			fun.AddScreen("World")
 		end
		Slab.NewLine()
 
		if Slab.Button("Resume game",{W=155}) then
			fun.AddScreen("World")
		end
		Slab.NewLine()        

		if Slab.Button("Load game",{W=155}) then
            fun.LoadGame()
			fun.AddScreen("World")
		end
		Slab.NewLine()

		
		--! this is functionally ready but there is a problem with BITSER that needs to be fixed.
		if Slab.Button("Save game",{W=155}) then
			fun.SaveGame()      --! need some sort of feedback here
		end
		Slab.NewLine()

		if Slab.Button("Credits",{W=155}) then
			fun.AddScreen("Credits")		--!
		end
		Slab.NewLine()
		
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

function menus.DrawCredits()

    local intSlabWidth = 300	-- the width of the main menu slab. Change this to change appearance.
	local intSlabHeight = 625 	-- the height of the main menu slab
	local fltSlabWindowX = love.graphics.getWidth() / 2 - intSlabWidth / 2
	local fltSlabWindowY = love.graphics.getHeight() / 2 - intSlabHeight / 2

	Slab.BeginWindow('creditsbox',{Title ='About',BgColor = {0.5,0.5,0.5},AutoSizeWindow = true,NoOutline=true,AllowMove=false,X=fltSlabWindowX,Y=fltSlabWindowY})

	Slab.BeginLayout('mylayout', {AlignX = 'center'})
		Slab.Text("Mars Lander")
		Slab.NewLine()
		Slab.Text("A Love2D community project")
		Slab.NewLine()
		Slab.Text("Contributors:")
		Slab.Text("TOGFox")
		Slab.Text("Milon")
		Slab.Text("Gunroar:Cannon()")
		Slab.NewLine()		
		
		Slab.Text("Thanks to beta testers:",{Align = 'center'})
        Slab.Textf("Boatman",{Align = 'right'})
        Slab.Textf("Darth Carcas",{Align = 'right'})
		Slab.Textf("Mini Yum",{Align = 'right'})
		Slab.NewLine()
		Slab.Text("Thanks to the Love2D community")
		Slab.NewLine()

		local fltHyperlinkColorR = 1
		local fltHyperlinkColorG = 0.9
		Slab.Text("Acknowledgements:")
		Slab.Text("Love2D", {URL="https://love2d.org",Color={1,1,1}, IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})
		Slab.Text("SLAB for Love2D", {URL="https://github.com/coding-jackalope/Slab", IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})
		Slab.Text("tlsfres", {URL="https://love2d.org/wiki/TLfres",Color={1,1,1}, IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})
		Slab.Text("inspect", {URL="https://github.com/kikito/inspect.lua",Color={1,1,1}, IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})
		Slab.Text("freesound.org", {URL="https://freesound.org/",Color={1,1,1}, IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})
 		Slab.Text("Kenney.nl", {URL="https://kenney.nl", IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})
		Slab.Text("bitser", {URL="https://github.com/gvx/bitser", IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})
		
		
		Slab.Text("Galactic Pole Position by Eric Matyas. ", {URL="www.soundimage.org", IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})
				

		--Slab.Text("Dark Fantasy Studio", {URL="http://darkfantasystudio.com/", IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})
		
		Slab.NewLine()
		Slab.Separator()
		Slab.Text("All material generated by the team, used with ",{Align = 'center'})
		Slab.Text("permission, or under creative commons",{Align = 'center'})
		Slab.NewLine()

		if Slab.Button("Awesome!") then
			-- return to the previous game state
			fun.RemoveScreen()
		end	
		
		-- add some white space for presentation
		Slab.NewLine()
		if Slab.Button("Hidden",{Invisible=true}) then
		end		

	Slab.EndLayout()
	Slab.EndWindow()
end


return menus

