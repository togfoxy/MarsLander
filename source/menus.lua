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
				ss.startHosting(gintServerPort)
				gbolIsAClient = false
				gbolIsAHost = true
				fun.SaveGameSettings()
				table.insert(garrLanders, Lander.create())
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

				ss.connectToHost(garrGameSettings.HostIP, garrGameSettings.HostPort)

				-- send a test message to the host. The host will return the client's IP and port
				local msg = {}
				msg.name = "ConnectionRequest"

				ss.addItemToClientOutgoingQueue(msg)
				ss.sendToHost()
				table.insert(garrLanders, Lander.create())
			end
			Slab.NewLine()
		end

		if Slab.Button("Credits",{W=155}) then
			fun.AddScreen("Credits")		--!
		end
		Slab.NewLine()

		if Slab.Button("Exit",{W=155}) then
			love.event.quit(0)
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
		BgColor = {0.4, 0.4, 0.4},
		AutoSizeWindow=false,
		AllowMove=false,
		AllowResize=false,
		X = fltSlabWindowX,
		Y = fltSlabWindowY,
		W = intSlabWidth,
		H = intSlabHeight,
	}
	local URLOptions = function(url) 
		local option = {}
		option.URL = url
		option.IsSelectable = true
		option.IsSelectableTextOnly = true
		option.HoverColor = {0.75, 0.75, 0.75}
		return option
	end

	Slab.BeginWindow('creditsbox', creditBoxOptions)
	Slab.BeginLayout('credits', {AlignX = 'center'})

		Slab.BeginLayout('credits-top', {AlignX = 'center'})
			Slab.Text("Mars Lander")
			Slab.Text("Github Repository", URLOptions("https://github.com/togfoxy/MarsLander"))
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

		Slab.SetLayoutColumn(2)
			Slab.Text("Acknowledgements:")
			Slab.NewLine()
			Slab.Text("Love2D", URLOptions("https://love2d.org"))
			Slab.Text("SLAB for Love2D", URLOptions("https://github.com/coding-jackalope/Slab"))
			Slab.Text("tlsfres", URLOptions("https://love2d.org/wiki/TLfres"))
			Slab.Text("inspect", URLOptions("https://github.com/kikito/inspect.lua"))
			Slab.Text("freesound.org", URLOptions("https://freesound.org/"))
 			Slab.Text("Kenney.nl", URLOptions("https://kenney.nl"))
			Slab.Text("bitser", URLOptions("https://github.com/gvx/bitser"))
			Slab.Text("nativefs", URLOptions("https://github.com/megagrump/nativefs"))
			Slab.Text("anim8", URLOptions("https://github.com/kikito/anim8"))
			Slab.Text("Lovely-Toasts", URLOptions("https://github.com/Loucee/Lovely-Toasts"))

			Slab.Text("Galactic Pole Position by Eric Matyas. ", URLOptions("www.soundimage.org"))

			--Slab.Text("Dark Fantasy Studio", URLOptions("http://darkfantasystudio.com/"))

			Slab.EndLayout()


		Slab.BeginLayout('credits-bottom', {AlignX = 'center', AlignY = 'top'})
			Slab.Separator()
			Slab.NewLine()
			Slab.Text("Thanks to the Love2D community")
			Slab.NewLine()
			Slab.Text("All material generated by the team, used with ",{Align = 'center'})
			Slab.Text("permission, or under creative commons",{Align = 'center'})
			Slab.NewLine()

			if Slab.Button("Awesome!") then
				-- return to the previous game state
				fun.RemoveScreen()
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
