local menus = {}


function menus.DrawMainMenu()
	
	local intSlabWidth = 700 --205	-- the width of the main menu slab. Change this to change appearance.
	local intSlabHeight = 475 	-- the height of the main menu slab
	local fltSlabWindowX = love.graphics.getWidth() / 2 - intSlabWidth / 2
	local fltSlabWindowY = love.graphics.getHeight() / 2 - intSlabHeight / 2

	-- try to centre the Slab window
	-- note: Border is the border between the window and the layout
	Slab.BeginWindow('MainMenu', {Title = "Main menu " .. gstrGameVersion,X=fltSlabWindowX,Y=fltSlabWindowY,W=intSlabWidth,H=intSlabHeight,Border=0,AutoSizeWindow=false, AllowMove=false,AllowResize=false,NoSavedSettings=true})

	Slab.BeginLayout("MMLayout",{AlignX="center",AlignY="center",AlignRowY="center",ExpandW=false,Columns = 2})
		
		Slab.SetLayoutColumn(1)
		Slab.Image('MyImage', {Image = garrImages[9], Scale=0.4})
		
		Slab.SetLayoutColumn(2)
		
		-- -- add some white space for presentation
		-- Slab.NewLine()
		-- if Slab.Button("Hidden",{Invisible=true}) then
		-- end		
		
		Slab.NewLine()
		if Slab.Input('Name',{Text=garrLanders[1].name,Tooltip="Enter your player name here"}) then
			garrLanders[1].name = Slab.GetInputText()
			if garrLanders[1].name == "" then
				-- Blank name isn't allowed, so reset to the default
				garrLanders[1].name = gstrDefaultPlayerName
			else
				-- save the current name in the global variable (Yeah its horrible - FIXME)
				gstrCurrentPlayerName = garrLanders[1].name
			end
		end

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

		if Slab.Button("Save game",{W=155}) then
			fun.SaveGame()      --! need some sort of feedback here
		end
		Slab.NewLine()
		
		if not gbolIsAClient and not gbolIsAHost then
			if Slab.Button("Host game",{W=155}) then
				ss.StartHosting(gintServerPort)
				gbolIsAClient = false
				gbolIsAHost = true
				fun.AddScreen("World")
			end
			Slab.NewLine()
		end
		
		if gbolIsAHost then
			Slab.Text("Hosting on port: " .. gintServerPort)
			Slab.NewLine()
		end
		
		if not gbolIsAHost then
			Slab.Text("Join on port:" )
			if Slab.Input('HostEndPoint',{ReturnOnText=true,W=100,Text = ConnectedToPort}) then
				ConnectedToPort = Slab.GetInputText()
			end
			
			if Slab.Button("Join game",{W=155}) then
				gbolIsAHost = false
				gbolIsAClient = true

				ss.ConnectToHost(_, ConnectedToPort)
				
				ss.AddItemToClientOutgoingQueue(message)
				fun.AddScreen("World")

			end
			Slab.NewLine()		
		end

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

		-- -- add some white space for presentation
		-- Slab.NewLine()
		-- if Slab.Button("Hidden",{Invisible=true}) then
		-- end
		
	Slab.EndLayout()
	Slab.EndWindow()

end

function menus.DrawCredits()

	local intSlabWidth = 300	-- the width of the main menu slab. Change this to change appearance.
	local intSlabHeight = 700 	-- the height of the main menu slab
	local fltSlabWindowX = love.graphics.getWidth() / 2 - intSlabWidth / 2
	local fltSlabWindowY = love.graphics.getHeight() / 2 - intSlabHeight / 2

	Slab.BeginWindow('creditsbox',{Title ='About',BgColor = {0.5,0.5,0.5},AutoSizeWindow = true,NoOutline=true,AllowMove=false,X=fltSlabWindowX,Y=fltSlabWindowY})
	Slab.BeginLayout('mylayout', {AlignX = 'center',Columns = 2})

		Slab.Text("Mars Lander")
		Slab.NewLine()
		Slab.Text("A Love2D community project")
		Slab.NewLine()
		Slab.Text("Contributors:")
		Slab.Text("TOGFox")
		Slab.Text("Milon")
		Slab.Text("Gunroar:Cannon()")
		Slab.Text("Philbywhizz")
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
