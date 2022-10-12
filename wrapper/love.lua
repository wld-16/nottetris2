local loveSound = require "loveSound"
local loveImage = require "loveImage"
local loveImageData = require "loveImageData"
local loveEnvironment = require "loveEnvironment"
local loveFont = require "loveFont"

local love = {
    graphics = {},
    filesystem = {},
    mouse = {},
    audio = {},
    image = {},
    env = {},
    timer = {},
    coordinateSystemTranslation = {x = 0, y = 0},
    scissor = { x = 0, y = 0, width = 960, height = 544 },
    keyboard = {},
    textCount = 1
}

function love.init()
    love.env = loveEnvironment:new({id = 0, backgroundColor = Color.new(0,0,0,0), activeFont = 0, timer = Timer.new()})
end

function love.graphics.getModes()
    local modes = {
        { width = 960, height = 544 }
    }
    return modes
end

function love.filesystem.exists(filePath)
    return System.doesFileExist("ux0:/data/lpp-vita/samples/nottetris2/" .. filePath)
end

-- TODO: Figure out how big the read/ write length needs to be
function love.filesystem.read(filePath)
    local handle = System.openFile("ux0:/data/lpp-vita/samples/nottetris2/" .. filePath, FREAD)
    local sizeOfFile = 200
    return System.readFile(handle, sizeOfFile)
end


-- TODO: Figure out how big the read/ write
function love.filesystem.write(filePath, content)
    --local handle = System.openFile("app0:/" .. filePath, FCREATE)
    --local sizeOfFile = 200
    --System.write(handle, content, sizeOfFile)
end

function love.graphics.setMode( width, height, fullscreen, vsync, fsaa)
    if(fullscreen) then
    else
        --Graphics.initBlend()
        --Graphics.debugPrint(5, 5, "Only Fullscreen Mode possible", Color.new(255, 255, 255))
        --Graphics.termBlend()
    end
end

function love.mouse.setVisible( visible )

end

function love.graphics.getWidth()
    return 960
end

function love.graphics.getHeight()
    return 544
end

function love.audio.newSource(filePath, type)
    local soundId = Sound.open("ux0:/data/lpp-vita/samples/nottetris2/" .. filePath)
    return loveSound:new({id = soundId, volume = 0, isLooping = false})
end

function love.graphics.newImageFromFile(filePath)
    return loveImage:new({id = Graphics.loadImage("ux0:/data/lpp-vita/samples/nottetris2/" .. filePath), filterWidth = "", filterHeight = ""})
end

function love.graphics.newImageFromImageData(imageData)
    return loveImage:new({id = imageData.id, filterWidth = "", filterHeight = ""})
end

function love.graphics.setBackgroundColor(r,g,b)
    love.env:setBackgroundColor(Color.new(r,g,b, 255))
end

function love.graphics.newImageFont(image, glyphs)
    return loveFont:new({ id = Font.load("ux0:/data/lpp-vita/samples/nottetris2/" .. fontPath)})
end

function love.image.newImageDataFromPath(filePath)
    local graphicsId = Graphics.loadImage("ux0:/data/lpp-vita/samples/nottetris2/" .. filePath)
    local graphics_width = Graphics.getImageWidth(graphicsId)
    local graphics_height = Graphics.getImageHeight(graphicsId)

    local graphic = loveImageData:new({id = graphicsId, width = graphics_width, height = graphics_height})

    love.graphics.debugPrint("filePath: " .. filePath .. "\nGraphics Id: " .. graphicsId .. "\nWidth: " .. graphics_width .. "\nHeight:" .. graphics_height)
    --love.graphics.draw(graphic, 40,40, 0, 1, 1, 0, 0)

    return graphic
end

function love.image.newImageDataFromDimensions(image_width, image_height)
     idsa = Graphics.createImage(image_width, image_height, Color.new(0,0,0))
     obj = loveImageData:new({id = idsa, width = image_width, height = image_height})
     return obj
end

function love.graphics.newFont(fontPath)
    return loveFont:new({ id = Font.load("ux0:/data/lpp-vita/samples/nottetris2/" .. fontPath)})
end

function love.graphics.setFont(font)
    love.env:setActiveFont(font)
end

function love.audio.play(snd)
    if (snd.isLooping) then
        Sound.play(snd.id, LOOP)
    else
        Sound.play(snd.id, NO_LOOP)
    end
end

function love.audio.pause(snd)
    Sound.pause(snd.id)
end

function love.audio.stop(snd)
    Sound.pause(snd.id)
end

function love.timer.getTime()
    return Timer.getTime(love.env.timer)
end

function love.keyboard.isDown(key)
    local pad = Controls.read()
    return Controls.check(pad, key)
end

function love.graphics.translate(dx, dy)
    love.coordinateSystemTranslation.x = love.coordinateSystemTranslation.x + dx
    love.coordinateSystemTranslation.y = love.coordinateSystemTranslation.y + dy
end

function love.graphics.draw(drawable, x, y, angle, scale_x, scale_y, offset_x, offset_y)
    local x_position = x + love.coordinateSystemTranslation.x + offset_x
    local y_position = y + love.coordinateSystemTranslation.y + offset_y

    Graphics.initBlend()
    Graphics.drawImage(x_position, y_position, drawable.id)
    Graphics.termBlend()
end

function love.graphics.setScissor(x, y, width, height)
    love.scissor.x = x
    love.scissor.y = y
    love.scissor.width = width
    love.scissor.height = height
end

function love.graphics.print( text, x, y, r, scale_x, scale_y)
    Graphics.initBlend()
    Font.print(love.env.activeFont.id, x, y, text, Color.new(0, 255, 255))
    Graphics.termBlend()
end

function love.graphics.debugPrint( text )
    Graphics.initBlend()
    Screen.clear()
    Graphics.debugPrint(20, 20, text, Color.new(255, 255, 255))
    Graphics.termBlend()
    Screen.flip()
end

function love.physics.newWorld(x1, y1, x2, y2, xg, yg, sleep ) 
-- TODO: Implement
end

function love.physics.newBody(world, x, y, m, i)
-- TODO: Implement
end

-- function love.physics.newPolygonShape( wallbodies, ...)
function love.physics.newPolygonShape( body, ...)
-- TODO: Implement for all cases
end

-- for wall
function love.physics.newPolygonShape( wallbodies, x1, y1, x2,y2, x3,y3, x4,y4)

end

function love.physics.newRectangleShape(body, x, y, width, height, angle)
-- TODO: Implement
end

function love.graphics.setColor(r, g, b)
-- TODO: Implement
end

function love.graphics.rectangle(mode, x, y, width, height)
-- TODO: Implement
end

function love.graphics.clear()
    Screen.clear()
end
            
function love.graphics.present()
-- TODO: Implement
end

return love