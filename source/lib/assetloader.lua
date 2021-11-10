
-- ~~~~~~~~~~~~~~
-- assetloader.lua
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Asset managment tool for Mars Lander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local Assets = {}
Assets.debugOutput  = false
Assets.imageSets    = {}
Assets.images       = {}
Assets.sounds       = {}
Assets.fonts        = {}
Assets.animations   = {}



-- ~~~~~~~~~~~~~~
-- Dependencies
-- ~~~~~~~~~~~~~~

local Anim8 = require("lib.anim8")



-- ~~~~~~~~~~~~~~~~
-- Local variables
-- ~~~~~~~~~~~~~~~~

local prefix    = " [Asset Tool] "
local newSource = love.audio.newSource
local newImage  = love.graphics.newImage
local newFont   = love.graphics.newFont



-- ~~~~~~~~~~~~~~~~
-- Local functions
-- ~~~~~~~~~~~~~~~~

local function debugPrint(...)
    if Assets.debugOutput then
        print(...)
    end
end



local function getFilenameFromPath(path)
    return path:match("([^/]+)%..+")
end



local function getDirectoryItems(path)
    local items = {}
    local info = love.filesystem.getInfo(path)
    if info and info.type == "directory" then
        debugPrint(prefix.."Found directory at path '/"..path.."'")
        local filenames = love.filesystem.getDirectoryItems(path)
        for _, name in pairs(filenames) do
            local item = {}
            item.name = name
            item.path = path.."/"..name
            table.insert(items, item)
        end
    else
        debugPrint(prefix.."No directory at path '"..path.."'. Skipping!")
    end
    return items
end



-- ~~~~~~~~~~~~~~~~~
-- Public functions
-- ~~~~~~~~~~~~~~~~~

-- FIXME: Make sure the file to load is actually an image / sound
function Assets.loadDirectory(path, type)
    local directoryName = path:match("([^/]+)$")
    local items = getDirectoryItems(path)
    for _, item in pairs(items) do
        if type == "image" then
            Assets.newImageSet(item.path)
            debugPrint(prefix.."New Image: "..item.name)
        elseif type == "sound" then
            Assets.newSound(item.path, "static")
            debugPrint(prefix.."New Sound: "..item.name)
        elseif type == "music" then
            local music = Assets.newSound(item.path, "stream")
            debugPrint(prefix.."New Music: "..item.name)
        end
    end
end



function Assets.newImageSet(path, ...)
    local imageData = {}
    imageData.image    = newImage(path, ...)
    imageData.width    = imageData.image:getWidth()
    imageData.height   = imageData.image:getHeight()
    local filename  = getFilenameFromPath(path)
    Assets.images[filename] = imageData
    return imageData
end



function Assets.newImage(path, ...)
    local image     = newImage(path, ...)
    local filename  = getFilenameFromPath(path)
    Assets.images[filename] = image
    return image
end



function Assets.newSound(path, ...)
    local sound     = newSource(path, ...)
    local filename  = getFilenameFromPath(path)
    Assets.sounds[filename] = sound
    return sound
end



function Assets.newFont(...)
    local args      = {...}
    local font      = newFont(...)
    local filename  = "font"..args[1]

    if type(args[1]) == "string" then
        filename = getFilenameFromPath(args[1])..args[2]
    end

    Assets.fonts[filename] = font
    return font
end



function Assets.newAnimation(name, image, width, height, column, row, durations, onLoop)

    local grid = Anim8.newGrid(width, height, image:getWidth(), image:getHeight())
    local animation = Anim8.newAnimation(grid(column, row), durations, onLoop)
    animation.name = name
    animation.grid = grid
    animation.image = image
    local anim8_draw = animation.draw
    animation.draw = function(animation, ...)
        -- just to skip passing the spritesheet everytime manually.. yikes -_-'
        anim8_draw(animation, animation.image, ...)
    end
    return animation
end



function Assets.draw(name, ...)
    local image = Assets.getImage(name)
    love.graphics.draw(image, ...)
end



function Assets.playSound(name, isLooping)
    local sound = Assets.getSound(name)
    -- if the sound needs to be played more then once at the same time, clone it
    -- sound = Assets.getSound(name):clone()
    sound:setLooping(isLooping or false)
    sound:play()
    return sound
end



function Assets.getImage(name)
    if not Assets.images[name] then
        error(prefix.."Image '"..name.."' does not exist.")
    end
    return Assets.images[name].image
end



function Assets.getImageSet(name)
    if not Assets.images[name] then
        error(prefix.."Image '"..name.."' does not exist.")
    end
    return Assets.images[name]
end



function Assets.getAnimation(name)
    if not Assets.animations[name] then
        error(prefix.."Animation '"..name.."' does not exist.")
    end
    return Assets.animations[name]
end



function Assets.getSound(name)
    if not Assets.sounds[name] then
        error(prefix.."Sound '"..name.."' does not exist.")
    end
    return Assets.sounds[name]
end



function Assets.getFont(name)
    if not Assets.fonts[name] then
        error(prefix.."Font '"..name.."' does not exist.")
    end
    return Assets.fonts[name]
end



function Assets.setFont(name)
    local font = Assets.getFont(name)
    love.graphics.setFont(font)
    return font
end


return Assets