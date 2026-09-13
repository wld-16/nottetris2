--
-- Created by IntelliJ IDEA.
-- User: spacewave
-- Date: 08.03.2021
-- Time: 15:25
-- To change this template use File | Settings | File Templates.
--

local loveSound = require "loveSound"
local loveImage = require "loveImage"
local loveImageData = require "loveImageData"
local loveEnvironment = require "loveEnvironment"
local loveFont = require "loveFont"

-- Where the game's files live on the Vita
GAME_ROOT = "ux0:/data/lpp-vita/samples/nottetris2/"

-- PSVita screen resolution
SCREEN_WIDTH = 960
SCREEN_HEIGHT = 544

-- Resolution the game itself draws in (Game Boy), before its own `scale` factor
GAME_WIDTH = 160
GAME_HEIGHT = 144

local love = {
    graphics = {},
    filesystem = {},
    mouse = {},
    audio = {},
    image = {},
    env = {},
    timer = {},
    coordinateSystemTranslation = {x = 0, y = 0},
    scissor = { x = 0, y = 0, width = SCREEN_WIDTH, height = SCREEN_HEIGHT },
    keyboard = {},
    textCount = 1
}

function love.init()
    -- Sound.init starts lpp-vita's audio threads. Without it every Sound.play
    -- finds no free thread and returns silently, so nothing is ever audible.
    Sound.init()
    love.env = loveEnvironment:new({id = 0, backgroundColor = Color.new(0,0,0,0), activeFont = 0, timer = Timer.new()})
end

-- Every Graphics call has to sit between initBlend/termBlend, and starting a
-- second blend while one is already open crashes lpp-vita outright. All blend
-- handling goes through these two so the error screen can tell whether a frame
-- was left open by whatever threw, and close it before drawing.
love.blendDepth = 0

function love.beginBlend()
    if love.blendDepth == 0 then
        Graphics.initBlend()
    end
    love.blendDepth = love.blendDepth + 1
end

function love.endBlend()
    if love.blendDepth == 0 then
        return
    end
    love.blendDepth = love.blendDepth - 1
    if love.blendDepth == 0 then
        Graphics.termBlend()
    end
end

-- Rough character metrics of the debug font, used to lay the error screen out.
ERROR_LINE_HEIGHT = 20
ERROR_CHARACTERS_PER_LINE = 100
ERROR_LOG_PATH = GAME_ROOT .. "error.log"
TRACE_LOG_PATH = GAME_ROOT .. "trace.log"

-- FCREATE is O_CREAT|O_WRONLY and does not truncate, so an old longer file would
-- leave a garbage tail behind the new contents.
function love.writeLines(path, lines)
    local text = table.concat(lines, "\n") .. "\n"
    pcall(System.deleteFile, path)
    local handle = System.openFile(path, FCREATE)
    System.writeFile(handle, text, #text)
    System.closeFile(handle)
end

love.traceLog = {}

-- Kept short because tracing outlives loading: pieces are built from images at
-- spawn time too, so the log has to stay a fixed-size window on the last steps
-- rather than a transcript of the whole session.
TRACE_LOG_LENGTH = 20

-- Not every failure on the Vita is a Lua error: a malformed image or font takes
-- the process down inside the native loader, with no chance to display anything.
-- Each step rewrites and closes the whole log, so after a hard crash the last
-- line in trace.log is the last step that was reached.
function love.trace(step)
    love.traceLog[#love.traceLog + 1] = tostring(step)
    if #love.traceLog > TRACE_LOG_LENGTH then
        table.remove(love.traceLog, 1)
    end
    pcall(love.writeLines, TRACE_LOG_PATH, love.traceLog)
end

function love.lastTrace()
    if #love.traceLog == 0 then
        return "nothing traced"
    end
    return love.traceLog[#love.traceLog]
end

-- Splits `text` on newlines and hard-wraps anything too wide for the screen,
-- since Graphics.debugPrint neither wraps nor clips.
function love.errorLines(text)
    local lines = {}
    for paragraph in (tostring(text) .. "\n"):gmatch("([^\n]*)\n") do
        if paragraph == "" then
            lines[#lines + 1] = ""
        else
            for start = 1, #paragraph, ERROR_CHARACTERS_PER_LINE do
                lines[#lines + 1] = paragraph:sub(start, start + ERROR_CHARACTERS_PER_LINE - 1)
            end
        end
    end
    return lines
end

-- Written before anything is drawn: if the error screen itself takes the app
-- down (a native crash is not catchable from Lua) the message can still be
-- pulled off the Vita over FTP.
function love.logError(message)
    love.writeLines(ERROR_LOG_PATH, {
        "last step reached: " .. love.lastTrace(),
        tostring(message)
    })
end

-- Holds an error on screen until the player dismisses it with START. lpp-vita's
-- built-in error screen would do that too, except it opens its frame with
-- vita2d_start_drawing() without checking whether the script died mid-frame --
-- a second open on the same scene takes the process down, which is why the
-- message only ever flashed up. Handling it here, after closing any frame the
-- failure left behind, is what makes it stay.
function love.showError(message)
    local lines = love.errorLines(message)
    pcall(love.logError, message)

    love.endBlend()
    love.blendDepth = 0

    table.insert(lines, 1, "last step reached: " .. love.lastTrace())
    table.insert(lines, 2, "")

    local red = Color.new(255, 80, 80)
    local white = Color.new(255, 255, 255)

    while true do
        Graphics.initBlend()
        Screen.clear()
        Graphics.debugPrint(5, 5, "ERROR", red)
        for index = 1, #lines do
            local y = 5 + index * ERROR_LINE_HEIGHT
            if y < SCREEN_HEIGHT - ERROR_LINE_HEIGHT then
                Graphics.debugPrint(5, y, lines[index], white)
            end
        end
        Graphics.debugPrint(5, SCREEN_HEIGHT - ERROR_LINE_HEIGHT, "Press START to quit", red)
        Graphics.termBlend()
        Screen.flip()

        if Controls.check(Controls.read(), SCE_CTRL_START) then
            break
        end
    end

    if System.exit then
        System.exit()
    end
end

-- Runs `body` and parks on the error screen instead of letting the interpreter
-- exit if it throws. A traceback is attached when the debug library is around,
-- but never at the cost of losing the message itself.
function love.protectedCall(body)
    local handler = function(message)
        local text = tostring(message)
        if debug and debug.traceback then
            local traced, traceback = pcall(debug.traceback, text, 2)
            if traced and traceback then
                return traceback
            end
        end
        return text
    end

    local succeeded, message = xpcall(body, handler)
    if not succeeded then
        love.showError(message)
    end
    return succeeded
end

function love.graphics.getModes()
    local modes = {
        { width = SCREEN_WIDTH, height = SCREEN_HEIGHT }
    }
    return modes
end

function love.filesystem.exists(filePath)
    return System.doesFileExist(GAME_ROOT .. filePath)
end

-- Absolute Vita path for a game-relative asset. Fails loudly when the file is
-- missing: Graphics.loadImage/Sound.open would otherwise read an unopened
-- handle and report a garbage magic number instead of the real problem.
function love.filesystem.assetPath(filePath)
    local absolutePath = GAME_ROOT .. filePath
    if not System.doesFileExist(absolutePath) then
        error("asset not found on the Vita:\n " .. absolutePath)
    end
    return absolutePath
end

-- TODO: Figure out how big the read/ write length needs to be
function love.filesystem.read(filePath)
    local handle = System.openFile(love.filesystem.assetPath(filePath), FREAD)
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
        love.beginBlend()
        Graphics.debugPrint(5, 5, "Only Fullscreen Mode possible", Color.new(255, 255, 255))
        love.endBlend()
    end
end

function love.mouse.setVisible( visible )

end

function love.graphics.getWidth()
    return SCREEN_WIDTH
end

function love.graphics.getHeight()
    return SCREEN_HEIGHT
end

-- The game lays everything out in a GAME_WIDTH x GAME_HEIGHT canvas blown up by
-- its own integer `scale` (3 on the Vita, i.e. 480x432). These factors stretch
-- that canvas onto the full 960x544 screen, so images end up at Vita dimensions.
function love.graphics.getScreenScale()
    local gameScale = scale or 1
    return SCREEN_WIDTH / (GAME_WIDTH * gameScale),
           SCREEN_HEIGHT / (GAME_HEIGHT * gameScale)
end

function love.audio.newSource(filePath, type)
    local soundId = Sound.open(love.filesystem.assetPath(filePath))
    return loveSound:new({id = soundId, volume = 0, isLooping = false})
end

function love.graphics.newImageFromFile(filePath)
    return loveImage:new({id = Graphics.loadImage(love.filesystem.assetPath(filePath)), filterWidth = "", filterHeight = ""})
end

function love.graphics.newImageFromImageData(imageData)
    return loveImage:new({
        id = imageData.id,
        filterWidth = "",
        filterHeight = "",
        pixelScale = imageData.pixelScale or 1
    })
end

function love.graphics.setBackgroundColor(r,g,b)
    love.env:setBackgroundColor(Color.new(r,g,b, 255))
end

function love.image.newImageDataFromPath(filePath)
    local graphicsId = Graphics.loadImage(love.filesystem.assetPath(filePath))
    local graphics_width = Graphics.getImageWidth(graphicsId)
    local graphics_height = Graphics.getImageHeight(graphicsId)

    return loveImageData:new({id = graphicsId, width = graphics_width, height = graphics_height})
end

function love.image.newImageDataFromDimensions(image_width, image_height)
    local graphicsId = Graphics.createImage(image_width, image_height, Color.new(0, 0, 0, 0))
    return loveImageData:new({id = graphicsId, width = image_width, height = image_height})
end

function love.image.newImageData(image_width, image_height)
    return loveImageData:new({width = image_width, heigth = image_height})
end

-- An upscaled copy of `imageData`. vita2d scales textures on the GPU when they
-- are drawn, so the factor is recorded on the image rather than baked into a new
-- texture: no pixel copying, no second allocation. love.graphics.draw multiplies
-- by it, and getWidth/getHeight report the scaled size the game expects.
function love.image.scaledImageData(imageData, factor)
    return loveImageData:new({
        id = imageData.id,
        width = imageData.width * factor,
        height = imageData.height * factor,
        pixelScale = (imageData.pixelScale or 1) * factor
    })
end

function love.graphics.newFont(fontPath)
    love.trace(fontPath)
    local assetPath = love.filesystem.assetPath(fontPath)
    love.trace(assetPath)
    local fontId = Font.load(assetPath)
    love.trace(fontId)
    return loveFont:new({ id = fontId})
end

function love.graphics.setFont(font)
    love.env:setActiveFont(font)
end

-- lpp-vita takes a plain boolean for looping; LOOP and NO_LOOP are LOVE names it
-- never defines, so passing them handed Sound.play a nil that always read false.
function love.audio.play(snd)
    Sound.play(snd.id, snd.isLooping == true)
end

function love.audio.stop(snd)
    Sound.pause(snd.id)
end

function love.audio.pause(snd)
    Sound.pause(snd.id)
end

function love.audio.resume(snd)
    Sound.resume(snd.id)
end

-- lpp-vita timers count milliseconds, LOVE counts seconds, and every delay in
-- the game is written in seconds (creditsdelay = 2, selectblinkrate = 0.29).
function love.timer.getTime()
    return Timer.getTime(love.env.timer) / 1000
end

function love.keyboard.isDown(key)
    local pad = Controls.read()
    return Controls.check(pad, key)
end

function love.graphics.translate(dx, dy)
    love.coordinateSystemTranslation.x = love.coordinateSystemTranslation.x + dx
    love.coordinateSystemTranslation.y = love.coordinateSystemTranslation.y + dy
end

-- LOVE hands each frame a fresh transform. translate() only ever adds, so
-- without this the fullscreen offset menu_draw applies every frame would keep
-- accumulating and walk the picture off the screen.
function love.graphics.resetTransform()
    love.coordinateSystemTranslation.x = 0
    love.coordinateSystemTranslation.y = 0
end

function love.graphics.draw(drawable, x, y, angle, scale_x, scale_y, offset_x, offset_y)
    local stretch_x, stretch_y = love.graphics.getScreenScale()
    scale_x = scale_x or 1
    scale_y = scale_y or scale_x
    offset_x = offset_x or 0
    offset_y = offset_y or 0

    -- Everything that can throw (a nil drawable, most often) is resolved before
    -- the blend opens, so a bad call cannot leave a frame half-drawn.
    local imageId = drawable.id
    -- Images the game asked to upscale carry the factor instead of a bigger
    -- texture (see love.image.scaledImageData), so it lands here.
    local pixel_scale = drawable.pixelScale or 1
    local screen_x = (x + love.coordinateSystemTranslation.x + offset_x) * stretch_x
    local screen_y = (y + love.coordinateSystemTranslation.y + offset_y) * stretch_y

    love.beginBlend()
    Graphics.drawScaleImage(screen_x, screen_y, imageId,
        scale_x * pixel_scale * stretch_x, scale_y * pixel_scale * stretch_y)
    love.endBlend()
end

function love.graphics.setScissor(x, y, width, height)
    local stretch_x, stretch_y = love.graphics.getScreenScale()
    love.scissor.x = x * stretch_x
    love.scissor.y = y * stretch_y
    love.scissor.width = width * stretch_x
    love.scissor.height = height * stretch_y
end

-- Text is one element of the frame the caller is drawing, so this no longer
-- clears or flips: doing either here wiped whatever love.draw had already put on
-- screen and presented a half-built frame.
function love.graphics.print( text, x, y, r, scale_x, scale_y)
    -- love.env.activeFont is 0 until setFont runs, so resolve the id outside the
    -- blend: printing too early should raise a readable error, not wedge the GPU.
    local fontId = love.env.activeFont.id
    local stretch_x, stretch_y = love.graphics.getScreenScale()

    love.beginBlend()
    Font.print(fontId,
        (x + love.coordinateSystemTranslation.x) * stretch_x,
        (y + love.coordinateSystemTranslation.y) * stretch_y,
        text, Color.new(0, 255, 255))
    love.endBlend()
end

return love