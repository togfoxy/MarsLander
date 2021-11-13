
-- ~~~~~~~~~~~~~~~
-- assetloader.lua
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Asset managment tool created for Mars Lander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- https://github.com/togfoxy/MarsLander
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

local license = [[
    MIT LICENSE

    Copyright (c) 2021 Lars Loenneker

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]

local Assets = {audioStreamSizeLimit = 1024}
Assets.debugOutput  = true
Assets.imageSets    = {}
Assets.sounds       = {}
Assets.fonts        = {}
Assets.animations   = {}



-- ~~~~~~~~~~~~~~
-- Dependencies
-- ~~~~~~~~~~~~~~
-- FIXME: Make usage of Anim8 optional & check environment if its already loaded
local Anim8 = require("lib.anim8")



-- ~~~~~~~~~~~~~~~~
-- Local variables
-- ~~~~~~~~~~~~~~~~

local prefix    = " [Asset Tool] "
local newSource = love.audio.newSource
local newImage  = love.graphics.newImage
local newFont   = love.graphics.newFont
local fs        = love.filesystem
local fileExtensions = {
    ["image"] = {"png", "jpg", "jpeg", "bmp", "tga", "hdr", "pic", "exr"},
    ["sound"] = {"ogg", "mp3", "oga", "ogv", "wav", "flac"},
}



-- ~~~~~~~~~~~~~~~~
-- Local functions
-- ~~~~~~~~~~~~~~~~

local function log(...)
    if Assets.debugOutput then
        print(prefix.. ...)
        -- TODO: Add support for logging into a logfile
    end
end



local function getFileExtension(path)
    return path:match("[^.]+$")
end



local function getFilename(path)
    return path:match("([^/]+)%..+")
end



local function getAsset(table, name)
    local file = table[name]
    if not file then
        error(prefix.."Asset '"..name.."' does not exist.")
    end
    return file
end



local function getDirectoryItems(basePath, items)
    local items = items or {}

    -- Check if the given path is valid
    local baseInfo = fs.getInfo(basePath)
    if baseInfo.type == "directory" then

        -- Found initial directory
        log("[Info] Found directory at path '/"..basePath.."'")

        -- Recursivly load directories and files
        local fileNames = fs.getDirectoryItems(basePath)
        for _, name in ipairs(fileNames) do
            local filePath = basePath.."/"..name

            -- Found a single file
            local fileInfo = fs.getInfo(filePath)
            if fileInfo.type == "file" then
                local item = {}
                item.name = name
                item.path = filePath
                item.fileType = getFileExtension(item.path)
                item.fileSize = fileInfo.size / 1000 -- Convert bytes to kb
                table.insert(items, item)

            -- Found another directory, load the content as well!
            elseif fileInfo.type == "directory" then
                getDirectoryItems(filePath, items)
            end
        end
    else
        -- Base directory not found
        log("[WARN] No directory at path '"..basePath.."'. Skipping!")
    end
    return items
end



-- ~~~~~~~~~~~~~~~~~
-- Public functions
-- ~~~~~~~~~~~~~~~~~

function Assets.loadDirectory(path, audioMode)
    local directoryName = path:match("([^/]+)$")
    local items = getDirectoryItems(path)

    -- Iterate all loaded files and sort based on their type
    for _, item in pairs(items) do
        local fileLoaded = false

        -- Check if the file is an image
        for _, extension in pairs(fileExtensions.image) do
            if item.fileType == extension then
                -- Create new image data
                Assets.newImageSet(item.path)
                log("[Info] New image: "..item.name)
                fileLoaded = true
                break
            end
        end

        -- Check if the file is a sound
        for _, extension in pairs(fileExtensions.sound) do
            if item.fileType == extension then
                -- Determine if the file should be streamed
                -- fileSize in kilobytes
                local mode = "static"
                if item.fileSize >= Assets.audioStreamSizeLimit then
                    mode = "stream"
                end

                -- Create new sound data
                Assets.newSound(item.path, audioMode or mode)
                log("[Info] New Sound: "..item.name.." ("..mode.." mode)")
                fileLoaded = true
                break
            end
        end

        -- Show a warning when no supported file type is found
        if not fileLoaded then
            log("[WARN] Cannot load file '"..item.name.."'. Skipping!")
        end
    end
end



function Assets.newImageSet(path, ...)
    local imageSet = {}
    imageSet.image    = newImage(path, ...)
    imageSet.width    = imageSet.image:getWidth()
    imageSet.height   = imageSet.image:getHeight()
    local filename  = getFilename(path)
    Assets.imageSets[filename] = imageSet
    return imageSet
end



-- INFO: Added newImage because that's what users would expect to use
-- based on the LÖVE function name
function Assets.newImage(path, ...)
    local imageSet = Assets.newImageSet(path, ...)
    return imageSet.image
end



function Assets.newSound(path, ...)
    local sound     = newSource(path, ...)
    local filename  = getFilename(path)
    Assets.sounds[filename] = sound
    return sound
end



function Assets.newFont(...)
    local args      = {...}
    local font      = newFont(...)
    local filename  = "font"..args[1]
    -- If the first argument is a string, attach the font size (second argument)
    if type(args[1]) == "string" then
        filename = getFilename(args[1])..args[2]
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
    animation.width = width
    animation.height = height
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
    sound:setLooping(isLooping or false)
    sound:play()
    return sound
end



function Assets.setFont(name)
    local font = Assets.getFont(name)
    love.graphics.setFont(font)
    return font
end



function Assets.getImageSet(name)
    local asset = getAsset(Assets.imageSets, name)
    return asset
end



function Assets.getImage(name)
    return Assets.getImageSet(name).image
end



function Assets.getAnimation(name)
    local asset = getAsset(Assets.animations, name)
    return asset
end



function Assets.getSound(name)
    local asset = getAsset(Assets.sounds, name)
    return asset
end



function Assets.getFont(name)
    local asset = getAsset(Assets.fonts, name)
    return asset
end


return Assets