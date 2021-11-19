local Menus = {}


function Menus.DrawMainMenu()

	local intSlabWidth = 700 -- the width of the main menu slab. Change this to change appearance.
	local intSlabHeight = 550 	-- the height of the main menu slab
	local fltSlabWindowX = love.graphics.getWidth() / 2 - intSlabWidth / 2
	local fltSlabWindowY = love.graphics.getHeight() / 2 - intSlabHeight / 2

	-- try to centre the Slab window
	-- note: Border is the border between the window and the layout
	local mainMenuOptions = {
		Title = "Main menu " .. GAME_VERSION,
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
		Slab.Image('MyImage', {Image = Assets.getImage("clipartLander"), Scale=0.4})

		Slab.SetLayoutColumn(2)

		Slab.NewLine()
		Slab.Text("Name: " .. GAME_SETTINGS.PlayerName)

		Slab.NewLine()
		if Slab.Button("New game",{W=155}) then
			Fun.ResetGame()
			Fun.SaveGameSettings()
			Fun.AddScreen("World")
 		end

		Slab.NewLine()

		if Slab.Button("Resume game",{W=155}) then
			Fun.SaveGameSettings()
			Fun.AddScreen("World")
		end
		Slab.NewLine()

		if Slab.Button("Load game",{W=155}) then

			if not ENET_IS_CONNECTED then
				Fun.LoadGame()
				Fun.SaveGameSettings()
				Fun.AddScreen("World")
			else
				LovelyToasts.show("Can't load when in multiplayer mode",3, "middle")
			end

		end
		Slab.NewLine()

		if Slab.Button("Save game",{W=155}) then
			if not ENET_IS_CONNECTED then
				Fun.SaveGame() 
			else
				LovelyToasts.show("Can't save a multiplayer game",3, "middle")
			end
		end
		Slab.NewLine()

		if Slab.Button("Settings",{W=155}) then
			Fun.AddScreen("Settings")
		end
		Slab.NewLine()

		if not ENET_IS_CONNECTED then
			if Slab.Button("Host game",{W=155}) then
				IS_A_CLIENT = false
				IS_A_HOST = true
				LANDERS[1].connectionID = 111	-- random ID. Can be any number (not nil)
				Fun.SaveGameSettings()
				EnetHandler.createHost()
				Fun.AddScreen("World")
			end
			Slab.NewLine()
		end

		if IS_A_HOST then
			Slab.Text("Hosting on port: " .. GAME_SETTINGS.hostPort)
			Slab.NewLine()
		end

		if not IS_A_HOST then
			Slab.Text("Join on IP:")
			local joinIPOptions = {
				ReturnOnText=true,
				W=100,
				Text=GAME_SETTINGS.hostIP,
				NumbersOnly=false,
				NoDrag=true,
			}
			if Slab.Input('hostIP', joinIPOptions) then
				GAME_SETTINGS.hostIP = Slab.GetInputText()
			end		

			Slab.Text("Join on port:" )
			local joinPortOptions = {
				ReturnOnText=true,
				W=100,
				Text=GAME_SETTINGS.hostPort,
				NumbersOnly=true,
				NoDrag=true,
				MinNumber=22100,
				MaxNumber=22199
			}
			if Slab.Input('HostPort', joinPortOptions) then
				GAME_SETTINGS.hostPort = Slab.GetInputText() or "22122"
			end

			-- don't show JOIN button if already connected
			if not ENET_IS_CONNECTED then
				if Slab.Button("Join game",{W=155}) then
					IS_A_HOST = false
					IS_A_CLIENT = true
					Fun.SaveGameSettings()
					EnetHandler.createClient()
				end
				Slab.NewLine()
			end
		end

		if Slab.Button("Credits",{W=155}) then
			Fun.AddScreen("Credits")		--!
		end
		Slab.NewLine()

		if Slab.Button("Exit",{W=155}) then
			-- love.event.quit(0)
			Fun.quitGame()
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

function Menus.DrawCredits()

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
				Fun.RemoveScreen()
			end	

		Slab.EndLayout()

	Slab.EndLayout()
	Slab.EndWindow()
end

function Menus.DrawSettingsMenu()
	local intSlabWidth = 500	-- the width of the settings window slab.
	local intSlabHeight = 325 	-- the height of the windowslab
	local fltSlabWindowX = love.graphics.getWidth() / 2 - intSlabWidth / 2
	local fltSlabWindowY = love.graphics.getHeight() / 2 - intSlabHeight / 2

	local settingsWindowOptions = {
		Title ='Game Settings',
		X = fltSlabWindowX,
		Y = fltSlabWindowY,
		W = intSlabWidth,
		H = intSlabHeight,
		Border = 15,
		AutoSizeWindow = false,
		AllowMove = false,
		AllowResize = false,
		NoSavedSettings = true,
		}

	Slab.BeginWindow('settingsWindow', settingsWindowOptions)
		Slab.BeginLayout('layout-settings',{AlignX = "left", Columns = 2})
		
		Slab.SetLayoutColumn(1)

		Slab.Textf("Name:")
		local PlayerName = GAME_SETTINGS.PlayerName
		if Slab.Input('Name',{Text=PlayerName,Tooltip="Enter your player name here"}) then
			PlayerName = Slab.GetInputText()
			if PlayerName == "" then
				-- Blank name isn't allowed, so reset to the default
				LANDERS[1].name = DEFAULT_PLAYER_NAME
			else
				-- save the current name in the global variable (Yeah its horrible - FIXME)
				LANDERS[1].name = PlayerName
				CURRENT_PLAYER_NAME = PlayerName
				GAME_SETTINGS.PlayerName = PlayerName
			end
		end

		Slab.NewLine()
		Slab.Text("Game Settings:")
		if Slab.CheckBox(GAME_SETTINGS.FullScreen, "Full Screen") then
			GAME_SETTINGS.FullScreen = not GAME_SETTINGS.FullScreen
			love.window.setFullscreen(GAME_SETTINGS.FullScreen)
		end

		Slab.NewLine()

		-- all the configurable options go here
		Slab.SetLayoutColumn(2)
		
		Slab.Textf("Options:")
		if Slab.CheckBox(GAME_CONFIG.showDEBUG, "Show debug info") then
			GAME_CONFIG.showDEBUG = not GAME_CONFIG.showDEBUG
		end		

		if Slab.CheckBox(GAME_CONFIG.easyMode, "Easy mode") then
			GAME_CONFIG.easyMode = not GAME_CONFIG.easyMode
		end
		
		if Slab.CheckBox(GAME_CONFIG.allowParachutes, "Allow parachutes") then
			GAME_CONFIG.allowParachutes = not GAME_CONFIG.allowParachutes
		end
		
		if Slab.CheckBox(GAME_CONFIG.useAdvancedPhysics, "Use advanced physics") then
			GAME_CONFIG.useAdvancedPhysics = not GAME_CONFIG.useAdvancedPhysics
		end
		
		Slab.EndLayout() -- layout-settings
		
		-- this displays the OK button at the bottom
		Slab.BeginLayout('layout-settings2',{AlignX = "center"})
			
			Slab.NewLine()
			Slab.NewLine()
			Slab.NewLine()
			Slab.NewLine()
			Slab.NewLine()
			Slab.NewLine()
			Slab.NewLine()
			Slab.NewLine()
			
			Slab.Separator()	
			Slab.NewLine()
			if Slab.Button("OK") then
				-- return to the previous game state
				Fun.RemoveScreen()
			end		
		Slab.EndLayout() -- layout-settings
		
	Slab.EndWindow()
end

return Menus
