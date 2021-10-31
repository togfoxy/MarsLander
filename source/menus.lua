local menus = {}


function menus.DrawMainMenu()
	
	local intSlabWidth = 700 -- the width of the main menu slab. Change this to change appearance.
	local intSlabHeight = 550 	-- the height of the main menu slab
	local fltSlabWindowX = love.graphics.getWidth() / 2 - intSlabWidth / 2
	local fltSlabWindowY = love.graphics.getHeight() / 2 - intSlabHeight / 2

	-- try to centre the Slab window
	-- note: Border is the border between the window and the layout
	local mainMenuOptions = {
		Title = "Main menu " .. gstrGameVersion,
		X = fltSlabWindowX,
		Y = fltSlabWindowY,
		W = intSlabWidth,
		H = intSlabHeight,
		Border = 0,
		AutoSizeWindow=false,
		AllowMove=false,
		AllowResize=false,
		NoSavedSettings=true
	}

	Slab.BeginWindow('MainMenu', mainMenuOptions)
	Slab.BeginLayout("MMLayout",{AlignX="center",AlignY="center",AlignRowY="center",ExpandW=false,Columns = 2})
		
		Slab.SetLayoutColumn(1)
		Slab.Image('MyImage', {Image = garrImages[9], Scale=0.4})
		
		Slab.SetLayoutColumn(2)
		
		Slab.NewLine()
		Slab.Text("Name: " .. garrGameSettings.PlayerName)

		Slab.NewLine()
		if Slab.Button("New game",{W=155}) then
			fun.ResetGame()
			fun.SaveGameSettings()
			fun.AddScreen("World")
 		end
		Slab.NewLine()
 
		if Slab.Button("Resume game",{W=155}) then
			fun.SaveGameSettings()
			fun.AddScreen("World")
		end
		Slab.NewLine()        

		if Slab.Button("Load game",{W=155}) then
            fun.LoadGame()
			fun.SaveGameSettings()
			fun.AddScreen("World")
		end
		Slab.NewLine()

		if Slab.Button("Save game",{W=155}) then
			fun.SaveGame() 
		end
		Slab.NewLine()

		if Slab.Button("Settings",{W=155}) then
			fun.AddScreen("Settings")
		end
		Slab.NewLine()
		
		if not gbolIsAClient and not gbolIsAHost then
			if Slab.Button("Host game",{W=155}) then
				ss.StartHosting(gintServerPort)
				gbolIsAClient = false
				gbolIsAHost = true
				fun.SaveGameSettings()
				fun.AddScreen("World")
			end
			Slab.NewLine()
		end
		
		if gbolIsAHost then
			Slab.Text("Hosting on port: " .. gintServerPort)
			Slab.NewLine()
		end

		if not gbolIsAHost then
			Slab.Text("Join on IP:")
			local joinIPOptions = {
				ReturnOnText=true,
				W=100,
				Text=garrGameSettings.HostIP,
				NumbersOnly=false,
				NoDrag=true,
			}			
			if Slab.Input('HostIP', joinIPOptions) then
				garrGameSettings.HostIP = Slab.GetInputText()
			end		
		
			Slab.Text("Join on port:" )
			local joinPortOptions = {
				ReturnOnText=true,
				W=100,
				Text=garrGameSettings.HostPort,
				NumbersOnly=true,
				NoDrag=true,
				MinNumber=6000,
				MaxNumber=6999
			}
			if Slab.Input('HostPort', joinPortOptions) then
				garrGameSettings.HostPort = Slab.GetInputText() or 6000
			end
			
			if Slab.Button("Join game",{W=155}) then
				gbolIsAHost = false
				gbolIsAClient = true

				ss.ConnectToHost(garrGameSettings.HostIP, garrGameSettings.HostPort)		--! Note!!! ss.ConnectToHost does not use the IP address. socketstuff.lua needs to be finished/fixed

				-- send a test message to the host. The host will return the client's IP and port
				local msg = {}
				msg.name = "ConnectionRequest"
	
				ss.AddItemToClientOutgoingQueue(msg)
				-- gbolIsConnected = true	--!temporary code
				-- fun.AddScreen("World")
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

	local intSlabWidth = 550	-- the width of the main menu slab. Change this to change appearance.
	local intSlabHeight = 500 	-- the height of the main menu slab
	local fltSlabWindowX = love.graphics.getWidth() / 2 - intSlabWidth / 2
	local fltSlabWindowY = love.graphics.getHeight() / 2 - intSlabHeight / 2

	local creditBoxOptions = {
		Title ='About',
		BgColor = {0.5,0.5,0.5},
		AutoSizeWindow=false,
		AllowMove=false,
		AllowResize=false,
		X = fltSlabWindowX,
		Y = fltSlabWindowY,
		W = intSlabWidth,
		H = intSlabHeight,
	}
	Slab.BeginWindow('creditsbox', creditBoxOptions)
	Slab.BeginLayout('mylayout', {AlignX = 'center'})

		Slab.BeginLayout('credits-top', {AlignX = 'center'})
		Slab.Text("Mars Lander")
		Slab.Text("A Love2D community project")
		Slab.Separator()
		Slab.EndLayout()
		Slab.BeginLayout('credits-middle', {AlignX = 'center', AlignY = 'top', AlignRowY='center', Columns = 2})

		Slab.SetLayoutColumn(1)
		Slab.Text("Contributors:")
		Slab.NewLine()
		Slab.Text("TOGFox")
		Slab.Text("Milon")
		Slab.Text("Gunroar:Cannon()")
		Slab.Text("Philbywhizz")
		Slab.Text("MadByte")
		Slab.NewLine()		
		
		Slab.Text("Thanks to beta testers:",{Align = 'center'})
		Slab.NewLine()
        Slab.Textf("Boatman",{Align = 'right'})
        Slab.Textf("Darth Carcas",{Align = 'right'})
		Slab.Textf("Mini Yum",{Align = 'right'})
		Slab.NewLine()

		local fltHyperlinkColorR = 1
		local fltHyperlinkColorG = 0.9
		Slab.SetLayoutColumn(2)
		Slab.Text("Acknowledgements:")
		Slab.NewLine()
		Slab.Text("Love2D", {URL="https://love2d.org",Color={1,1,1}, IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})
		Slab.Text("SLAB for Love2D", {URL="https://github.com/coding-jackalope/Slab", IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})
		Slab.Text("tlsfres", {URL="https://love2d.org/wiki/TLfres",Color={1,1,1}, IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})
		Slab.Text("inspect", {URL="https://github.com/kikito/inspect.lua",Color={1,1,1}, IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})
		Slab.Text("freesound.org", {URL="https://freesound.org/",Color={1,1,1}, IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})
 		Slab.Text("Kenney.nl", {URL="https://kenney.nl", IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})
		Slab.Text("bitser", {URL="https://github.com/gvx/bitser", IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})
		Slab.Text("nativefs", {URL="https://github.com/megagrump/nativefs", IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})
		Slab.Text("anim8", {URL="https://github.com/kikito/anim8", IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})
		Slab.Text("Lovely-Toasts", {URL="https://github.com/Loucee/Lovely-Toasts", IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})
		
		Slab.Text("Galactic Pole Position by Eric Matyas. ", {URL="www.soundimage.org", IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})

		--Slab.Text("Dark Fantasy Studio", {URL="http://darkfantasystudio.com/", IsSelectable = true, IsSelectableTextOnly = true, HoverColor = {fltHyperlinkColorR,fltHyperlinkColorG,fltHyperlinkColorG}})

		Slab.EndLayout()
		Slab.BeginLayout('credits-bottom', {AlignX = 'center', AlignY = 'bottom', AlignRowY='bottom'})

		Slab.Separator()
		Slab.Text("Thanks to the Love2D community")
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

	Slab.EndLayout()
	Slab.EndWindow()
end

function menus.DrawSettingsMenu()
	local intSlabWidth = 400	-- the width of the settings window slab.
	local intSlabHeight = 250 	-- the height of the windowslab
	local fltSlabWindowX = love.graphics.getWidth() / 2 - intSlabWidth / 2
	local fltSlabWindowY = love.graphics.getHeight() / 2 - intSlabHeight / 2

	local settingsWindowOptions = {
		Title ='Game Settings',
		X = fltSlabWindowX,
		Y = fltSlabWindowY,
		W = intSlabWidth,
		H = intSlabHeight,
		Border = 0,
		AutoSizeWindow=false,
		AllowMove=false,
		AllowResize=false,
		NoSavedSettings=true
		}

	Slab.BeginWindow('settingsWindow', settingsWindowOptions)
		Slab.BeginLayout('layout-settings',{AlignX = "center"})

		Slab.NewLine()
		Slab.Textf("Player Settings:")
		Slab.NewLine()
		Slab.Textf("Name:")
		local PlayerName = garrGameSettings.PlayerName
		if Slab.Input('Name',{Text=PlayerName,Tooltip="Enter your player name here"}) then
			PlayerName = Slab.GetInputText()
			if PlayerName == "" then
				-- Blank name isn't allowed, so reset to the default
				garrLanders[1].name = gstrDefaultPlayerName
			else
				-- save the current name in the global variable (Yeah its horrible - FIXME)
				garrLanders[1].name = PlayerName
				gstrCurrentPlayerName = PlayerName
				garrGameSettings.PlayerName = PlayerName
			end
		end
		Slab.NewLine()
		Slab.Separator()

		Slab.NewLine()
		Slab.Text("Game Settings:")
		if Slab.CheckBox(garrGameSettings.FullScreen, "Full Screen") then
			garrGameSettings.FullScreen = not garrGameSettings.FullScreen
			love.window.setFullscreen(garrGameSettings.FullScreen)
			fun.SaveGameSettings()
		end

		Slab.NewLine()
		Slab.Separator()

		Slab.NewLine()
		if Slab.Button("OK") then
			-- return to the previous game state
			fun.RemoveScreen()
		end	

		Slab.EndLayout() -- layout-settings
	Slab.EndWindow()
end

return menus
