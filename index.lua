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
dofile("ux0:/data/lpp-vita/samples/nottetris2/wrapper/love.lua")
dofile("ux0:/data/lpp-vita/samples/nottetris2/main.lua")

volume = 1
hue = 0.08
fullscreen = true
gamestate = "logo"


love.init()

tetrisfont = love.graphics.newFont("graphics/font/Masaaki-Regular.ttf")
love.graphics.setFont(tetrisfont)

mainFuction.load()
local pad = Controls.read()

while true do
    pad = Controls.read()
    --love.graphics.print("helloa", 20, 60, 0, 1, 1)
    -- if any key pressed send out events
    if(false) then
        if(Controls.check(pad,SCE_CTRL_UP)) then
            main.love.keypressed("up")
        elseif(Controls.check(pad,SCE_CTRL_DOWN)) then
            main.love.keypressed("down")
        elseif(Controls.check(pad,SCE_CTRL_LEFT)) then
            main.love.keypressed("left")
        elseif(Controls.check(pad,SCE_CTRL_RIGHT)) then
            main.love.keypressed("right")
        elseif(Controls.check(pad,SCE_CTRL_START)) then
            main.love.keypressed("return")
        elseif(Controls.check(pad,SCE_CTRL_SELECT)) then
            main.love.keypressed("escape")
        elseif(Controls.check(pad,SCE_CTRL_LTRIGGER)) then
            main.love.keypressed("y")
        elseif(Controls.check(pad,SCE_CTRL_RTRIGGER)) then
            main.love.keypressed("x")
        end
    end 
    Screen.clear()
    main.love.update(math.ceil(love.timer.getTime()))
    main.love.draw()
    Screen.flip()
end