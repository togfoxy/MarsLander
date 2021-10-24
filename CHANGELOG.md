# Changelog

All notable changes to this project should be documented in this file.

The file format is based on [Keep a Change Log](https://keepachangelog.com/en/1.0.0/)

## Unreleased
### Added
- Created a CHANGELOG.md
### Changed
- Libraries moved into a lib folder to keep the codebase tidy

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