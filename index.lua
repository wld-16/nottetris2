--
-- Created by IntelliJ IDEA.
-- User: spacewave
-- Date: 08.03.2021
-- Time: 15:26
-- To change this template use File | Settings | File Templates.
--

-- Load
local white = Color.new(255,255,255)
Graphics.initBlend()
Graphics.debugPrint(5, 5, "Hello World!", white)
Graphics.termBlend()
-- love.lua brings in love.showError/love.protectedCall, so it is loaded on its
-- own with a bare fallback screen in case that load is what fails.
local function showFatal(message)
    if love and love.showError then
        love.showError(message)
        return
    end
    while true do
        Graphics.initBlend()
        Screen.clear()
        Graphics.debugPrint(5, 5, tostring(message), Color.new(255, 80, 80))
        Graphics.termBlend()
        Screen.flip()
    end
end

local wrapperLoaded, wrapperError = pcall(dofile, "ux0:/data/lpp-vita/samples/nottetris2/wrapper/love.lua")
if not wrapperLoaded then
    showFatal(wrapperError)
end

-- main.lua defines update/draw/keypressed on the global love table, not on
-- main.love -- that table stays empty, which is why dispatching through
-- main.love.keypressed only ever found a nil.
local BUTTON_KEYS = {
    {SCE_CTRL_UP,       "up"},
    {SCE_CTRL_DOWN,     "down"},
    {SCE_CTRL_LEFT,     "left"},
    {SCE_CTRL_RIGHT,    "right"},
    {SCE_CTRL_START,    "return"},
    {SCE_CTRL_SELECT,   "escape"},
    {SCE_CTRL_LTRIGGER, "y"},
    {SCE_CTRL_RTRIGGER, "x"}
}

local function mainLoop()
    local held = {}
    local previousTime = love.timer.getTime()

    while true do
        local currentTime = love.timer.getTime()
        local dt = currentTime - previousTime
        previousTime = currentTime

        local pad = Controls.read()
        for index = 1, #BUTTON_KEYS do
            local button, key = BUTTON_KEYS[index][1], BUTTON_KEYS[index][2]
            local isDown = Controls.check(pad, button)
            -- keypressed is an edge, not a state: dispatching while the button is
            -- held would fire it once per frame and race through every menu.
            if isDown and not held[button] then
                love.keypressed(key)
            end
            held[button] = isDown
        end

        love.update(dt)

        love.graphics.resetTransform()
        -- One blend for the whole frame. love.graphics.draw/print nest inside it
        -- through the depth counter, so the frame is presented once, complete.
        love.beginBlend()
        -- setBackgroundColor only recorded the colour until now; passing it here
        -- is what makes it the colour the frame actually starts from.
        Screen.clear(love.env.backgroundColor)
        love.draw()
        love.endBlend()
        Screen.flip()
    end
end

-- Each love.trace lands in trace.log before the step runs, so a step that kills
-- the process outright (native image/font loaders do) still names itself.
local function boot()
    love.trace("loading main.lua")
    dofile("ux0:/data/lpp-vita/samples/nottetris2/main.lua")

    volume = 1
    hue = 0.08
    scale = suggestedscale
    fullscreen = true
    -- Left nil on purpose: love.update starts the game through start() -> menu_load()
    -- once the state is nil, and that is what fills in logotime, oldtime and the
    -- credits text. Setting it to "logo" here skipped menu_load, so the very first
    -- menu_update did arithmetic on a nil logotime.
    gamestate = nil


    love.trace("love.init")
    love.init()

    love.trace("loading font")
    tetrisfont = love.graphics.newFont("graphics/font/Masaaki-Regular.ttf")
    love.graphics.setFont(tetrisfont)

    love.trace("main.load")
    main.load()

    love.trace("entering main loop")
    mainLoop()
end

love.protectedCall(boot)