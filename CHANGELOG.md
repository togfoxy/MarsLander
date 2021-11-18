# Changelog

All notable changes to this project should be documented in this file.

The file format is based on [Keep a Change Log](https://keepachangelog.com/en/1.0.0/)


## v0.12 - UNRELEASED

### Added

- the 'R'eset key is disabled in mplayer mode. Use the new enter/return key to reset a single lander
- disabled load/save when in multiplayer mode
- can now buy a parachute module. Deploys automatically. Use the side thruster keys (q/e) to steer. Single use.
- Host/client disconnections are now actively managed
- ability for external clients to connect over internet (not just LAN)
- expanded the settings slab window to accommodate game options

### Changed

### Fixed
- fix background drawn wrong on full screen
- Fixed assets not being checked for supported file types
- restored the high score that somehow got removed
- removed unused audio files

## v0.11
### Added
- added the 'wrong' sound in an additional place in the shop

### Changed
- restored the original 'wrong' sound as it is better
- buildings and fuel bases are determined on demand and not up-front
- removed the images/sprites out of the lander table
- major code re-organization and optimization
- 'p' now unpauses the game

### Fixed
- fixed saved player name not being displayed correctly in-game
- fixed regression introduced in v0.10 causing the rangefinder indicator not being displayed correctly
- fixed the lag when running co-op. Can run two windows on localhost really well now (but only one at a time can receive keyboard input :( )
- fixed a bizarre drawing bug when in co-op mode (work around applied)
- fuel bases are now determined on demand and not up front. Big performance boost.
- save game bug
- fixed game over not triggering (again)
- loading a game that doesn't exist no longer crashes the game
- rangefinder fixed
- fixed the '$' sign in the shop
- fix smoke particles not being removed after starting a new game

## v0.10
### Added
- added a player name label to the lander (set via the main menu)
- added a FAILED audio file
- FAILED audio file plays when trying to purchase something that can't be afforded
- added a score
- added an input box for capturing IP address
- added MadByte to the credits
- socket logic that won't let the client start the game until the host confirms the connection
- game settings now persist so they don't need to be retyped (player name, IP, port)
- Added a Settings Menu. Can also be accessed via 'o' while playing the game

### Changed
- smoke spritesheet and code that draws smoke
- adjusted the player label so it does not clash with lander graphic
- stopped LOW FUEL alert playing when takes are empty
- the NOISE parameters to make better terrain
- window now starts full screen
- window now starts windowed if in non-fused mode
- added wallpaper to the main menu
- added parameters to some functions to remove reliance on globals
- re-organized lander and terrain functionality into separate files
- credits window how has 2 columns and is more compact

### Fixed
- fixed crash when the port number on the main menu was blank. Now only supports numbers

## v0.09
### Added
- you can now pause the game with 'p'
- added a lovelyToast to the SAVE button
- simple "end game" screen allows a game restart
- low fuel audio
- added smoke effect
- an image to the main menu
- some commentary to the code to ease understanding and maintenance
- a CONST section (for constants) to enum.lua
- add a HEALTH indicator
- hard landings will remove HEALTH

### Changed
- started replacing constant values with the equivalent CONSTant declared in enum.lua
- removed images that aren't used
- repositioned FUEL indicator and WEALTH counter

## v0.08
### Added
- created a CHANGELOG.md
- can now purchase sideways thrusters. Use q/e or numpad 7/numpad 9 to use
- a whole bunch of multiplayer features added (but not yet working)

### Changed
- terrain algorithm has changed to be multiplayer compatible. Will be changed again in future to be less flat
- fixed a bug with mass not being calculated after a shop purchase

## v0.07
### Added
- added building #1 thanks to @GUNROAR
- added building #2 thanks to @GUNROAR
### Changed
- base tank light turns off when tank is empty of fuel. Thanks to @GUNROAR
- base tanks have a little fuel indicator
- game spawns 20+ bases now (more than 10)
- shop menu removes items you have already bought
- green landing lights turn red after you've landed there once
### Fixed
- graphics fix with some graphics 'blinking' out when too close to screen edge

## v0.06
### Added
### Changed
- wealth reward is now tied to soft landing (vx & vy) and how close to centre of the landing pad
- can now buy upgrades: larger fuel tank, efficient thrusters and a rangefinder
- lots of refactoring
### Fixed
- players can't fly off the left side of the screen now

## v0.05a
### Fixed
- forgot to add missing assets

## v0.05
### Added
- a "win" sound is added to let you know you've landed on a base correctly
- a "salary" is now payable based on landing close to the base
- an animated landing pad is added
- 10 bases are now added. Easy to add more
- load game added
- save game added
- game balancing added
### Changed
- the lander is scaled up a little bit (but now quite ugly)
- the ground is now "filled" and looks better
- some code refactoring
- bases will deactivate when out of fuel
### Fixed
- refueling is no longer instant. You can watch the fuel bar fill up (it's really cool)
- things drawn off the screen are no longer drawn off the screen (for performance reasons)
- some runtime bugs fixed
- bitser implemented correctly

## v0.04
### Added
- main menu added
- added a 'thrust' sound effect
- credits window added
- WASD support added (actually WAD - no 'S')
### Changed
- landing near a fuel base will now refuel the lander, and de-fuel the base
- bases with no fuel are visibly ghosted

## v0.03
### Added
- placeholder background added. Needs to be scrollable later
### Changed
- engine thrust is more effective when the lander is lighter
- Lander can turn left/right while landed
- off-screen indicator now merged into the main branch. Thanks @milon
### Fixed
- Fuel gauge now drawn across the top of the screen. Thanks @milon

## v0.02
### Added
- added a basic algorithm that adds mountains and bumpy terrain. Opted for the retro look instead of @milon's wavey noise (for now)
- lander has mass and fuel now. Burning fuel reduces mass
### Changed
- drawing points replaced by @milon's drawing by lines. Collision detection retained!
- terrain now side-scrolls as the lander moves left/right
### Fixed
- screen resizing now works properly

## v0.01
### Added
- Initial project creation
