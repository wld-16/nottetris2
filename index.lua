--
-- Created by IntelliJ IDEA.
-- User: spacewave
-- Date: 08.03.2021
-- Time: 15:26
-- To change this template use File | Settings | File Templates.
--

package.path = "ux0:/data/lpp-vita/samples/nottetris2/?.lua;" .. package.path
package.path = "ux0:/data/lpp-vita/samples/nottetris2/wrapper/?.lua;" .. package.path

-- Load
local white = Color.new(255,255,255) 

local love = require "love"
local main = require "main"

volume = 1
hue = 0.08
fullscreen = true
gamestate = "logo"


love.init()

main.load()
local pad = Controls.read()

Sound.init()

while true do
    Graphics.initBlend()
    Screen.clear()
    Graphics.termBlend()

    pad = Controls.read()
    --love.graphics.print("helloa", 20, 60, 0, 1, 1)
    -- if any key pressed send out events
    if(Controls.check(pad,SCE_CTRL_UP)) then
        main.keypressed("up")
    elseif(Controls.check(pad,SCE_CTRL_DOWN)) then
        main.keypressed("down")
    elseif(Controls.check(pad,SCE_CTRL_LEFT)) then
        main.keypressed("left")
    elseif(Controls.check(pad,SCE_CTRL_RIGHT)) then
        main.keypressed("right")
    elseif(Controls.check(pad,SCE_CTRL_START)) then
        main.keypressed("return")
    elseif(Controls.check(pad,SCE_CTRL_SELECT)) then
        main.keypressed("escape")
    elseif(Controls.check(pad,SCE_CTRL_LTRIGGER)) then
        main.keypressed("y")
    elseif(Controls.check(pad,SCE_CTRL_RTRIGGER)) then
        main.keypressed("x")
    end
    
    main.update(math.ceil(love.timer.getTime()))
    main.draw()
    Screen.flip()
end