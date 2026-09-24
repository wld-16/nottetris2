local love = require "love"
local menu = require "menu"
local gameA = require "gameA"

local main = {
   gamestate = "logo",
   -- sounds
   boot = {},

   -- music
   musictitle = {},
   musicoptions = {},
   highscoreintro = {},
   musicresults = {},
   musicrocket1to3 = {},
   musicrocket4 = {},
   musichighscore = {},
   music = {},

   -- images
   stabyourselflogo = {},
   logo = {},
   title = {},
   blockfall = {},
   blockturn = {},
   blockmove = {},
   lineclear = {},
   fourlineclear = {},
   gameover1 = {},
   gameover2 = {},
   pausesound = {},
   highscorebeep = {},
   newlevel = {},
   rainbowgradient = {},
   gametype = {},
   mpmenu = {},
   optionsmenu = {},
   volumeslider = {},
   gamebackground = {},
   gamebackgroundcutoff = {},
   gamebackgroundmulti = {},
   multiresults = {},
   number1 = {},
   number2 = {},
   number3 = {},
   gameover = {},
   gameovercutoff = {},
   pausegraphic = {},
   pausegraphiccutoff = {},
   marioidle = {},
   mariojump = {},
   mariocry1 = {},
   mariocry2 = {},
   luigiidle = {},
   luigijump = {},
   luigicry1 = {},
   luigicry2 = {},
   rocket1 = {},
   rocket2 = {},
   rocket3 = {},
   spaceshuttle = {},
   rocketbackground = {},
   bigrocketbackground = {},
   bigrockettakeoffbackground = {},
   smoke1left = {},
   smoke1right = {},
   smoke2left = {},
   smoke2right = {},
   fire1 = {},
   fire2 = {},
   firebig1 = {},
   firebig2 = {},
   congratsline = {},
   nextpieceimg = {},

    -- fonts
   tetrisfont = {},
   whitefont = {},

   whitelist = {},

   -- settings
   musicno = 1,
   soundenabled = true,
   playerselection = 1,
   oldmusicno = 1
}

function main.load()
     require "gameB"
     require "gameBmulti"
     require "controls"
     require "menu"
     require "failed"
     require "rocket"
   --requires--
   love.trace("dofile controls/menu/failed/rocket")
   
   vsync = true

   love.trace("autosize")
   autosize()

   suggestedscale = math.min(math.floor((desktopheight-50)/144), math.floor((desktopwidth-10)/160))
   if suggestedscale > 5 then
      suggestedscale = 5
   end
   
   love.trace("loadoptions")
   loadoptions()

   maxscale = math.min(math.floor(desktopheight/144), math.floor(desktopwidth/160)) 
   maxmpscale = math.min(math.floor(desktopheight/144), math.floor(desktopwidth/274)) 
   
   if fullscreen == false then
      if scale ~= 5 then
         love.graphics.setMode( 160*scale, 144*scale, false, vsync, 0 )
      end
   else
      love.graphics.setMode( 0, 0, true, vsync, 0 )
      love.mouse.setVisible( false )
      desktopwidth, desktopheight = love.graphics.getWidth(), love.graphics.getHeight()
      saveoptions()
      
      suggestedscale = math.floor((desktopheight-50)/144)
      if suggestedscale > 5 then
         suggestedscale = 5
      end
      maxscale = math.min(math.floor(desktopheight/144), math.floor(desktopwidth/160))
      
      scale = maxscale

      -- no letterboxing: the wrapper stretches the canvas over the whole Vita screen
      fullscreenoffsetX = 0
      fullscreenoffsetY = 0
   end

   physicsscale = scale/4
   
   --pieces--
   tetriimages = {}
   tetriimagedata = {}

   loadMenuMusic()
   main.boot = love.audio.newSource( "sounds/boot.ogg", "boot")

   love.trace("changevolume")
   -- changevolume(volume)

   ----IMAGES THAT WON'T CHANGE HUE:
   love.trace("image graphics/rainbow.png")
   main.rainbowgradient = love.graphics.newImageFromFile("graphics/rainbow.png")
   main.rainbowgradient:setFilter("nearest", "nearest")

   --Whitelist for highscorenames--
   main.whitelist = {}
   for i = 48, 57 do -- 0 - 9
      main.whitelist[i] = true
   end
   for i = 65, 90 do -- A - Z
      main.whitelist[i] = true
   end
   for i = 97, 122 do --a - z
      main.whitelist[i] = true
   end
   main.whitelist[32] = true -- space
   main.whitelist[44] = true -- ,
   main.whitelist[45] = true -- -
   main.whitelist[46] = true -- .
   main.whitelist[95] = true -- _

   -------------------------------

   math.randomseed( os.time() )
   math.random();math.random();math.random() --discarding some as they seem to tend to unrandomness.

   love.graphics.setBackgroundColor( 255, 255, 255 )

   p1wins = 0
   p2wins = 0

   skipupdate = true
   main.soundenabled = true
   startdelay = 1
   logoduration = 1.5
   logodelay = 1
   creditsdelay = 2
   selectblinkrate = 0.29
   cursorblinkrate = 0.14
   selectblink = true
   cursorblink = true
   main.playerselection = 1
   main.musicno = 1 --
   gameno = 1 --
   selection = 1 --
   colorizeduration = 3 --seconds
   lineclearduration = 1.2 --seconds
   lineclearblinks = 7 --i
   linecleartreshold = 8.1 --in blocks
   densityupdateinterval = 1/30 --in seconds
   nextpiecerotspeed = 1 --rad per seconnd
   minfps = 1/50 --dt doesn't go higher than this
   scoreaddtime = 0.5
   startdelaytime = 0
   density = 0.1

   blockstartY = -64 --where new blocks are created
   losingY = 0 --lose if block 1 collides above this line
   blockmass = 5 --probably obsolete because body:setMassFromShapes()
   blockrot = 10
   blockrestitution = 0.1
   minmass = 1

   optionschoices = {"volume", "color", "scale", "fullscrn"}

   piececenter = {}
   piececenter[1] = {17, 5}
   piececenter[2] = {13, 9}
   piececenter[3] = {13, 9}
   piececenter[4] = { 9, 9}
   piececenter[5] = {13, 9}
   piececenter[6] = {13, 9}
   piececenter[7] = {13, 9}

   piececenterpreview = {}
   piececenterpreview[1] = {17, 5}
   piececenterpreview[2] = {15, 7}
   piececenterpreview[3] = {11, 7}
   piececenterpreview[4] = { 9, 9}
   piececenterpreview[5] = {13, 9}
   piececenterpreview[6] = {13, 7}
   piececenterpreview[7] = {13, 9}
   --
   love.trace("loadhighscores")
   loadhighscores()
   --
   love.trace("loadimages")
   loadimages()
   love.trace("loadimages done")
   --
   ----all done!
   menu.loadMain(main, love)
   if startdelay == 0 then
      menu_load()
   end
end

function start()
   menu_load()
end

function loadHighscoreMusic()
   main.musichighscore = love.audio.newSource( "sounds/highscoremusic.ogg", "highscore")
   main.musichighscore:setVolume( 0.6 )
   main.musichighscore:setLooping( true )
   love.audio.play(main.musichighscore)
   love.audio.pause(main.musichighscore)

   main.musicrocket4 = love.audio.newSource( "sounds/rocket4.ogg", "rocket4")
   main.musicrocket4:setVolume( 0.6 )
   main.musicrocket4:setLooping( false )
   love.audio.play(main.musicrocket4)
   love.audio.pause(main.musicrocket4)

   main.musicrocket1to3 = love.audio.newSource( "sounds/rocket1to3.ogg", "rocket1to3")
   main.musicrocket1to3:setVolume( 0.6 )
   main.musicrocket1to3:setLooping( false )
   love.audio.play(main.musicrocket1to3)
   love.audio.pause(main.musicrocket1to3)

   main.musicresults = love.audio.newSource( "sounds/resultsmusic.ogg", "results")
   main.musicresults:setVolume( 1 )
   main.musicresults:setLooping( false )
   love.audio.play(main.musicresults)
   love.audio.pause(main.musicresults)

   main.highscoreintro = love.audio.newSource( "sounds/highscoreintro.ogg", "highscoreIntro")
   main.highscoreintro:setVolume( 0.6 )
   main.highscoreintro:setLooping( false )
   love.audio.play(main.highscoreintro)
   love.audio.pause(main.highscoreintro)

end

function loadIngameSounds()
   main.blockfall = love.audio.newSource( "sounds/blockfall.ogg", "fall")
   main.blockturn = love.audio.newSource( "sounds/turn.ogg", "turn")
   main.blockmove = love.audio.newSource( "sounds/move.ogg", "move")
   main.lineclear = love.audio.newSource( "sounds/lineclear.ogg", "clear")
   main.fourlineclear = love.audio.newSource( "sounds/4lineclear.ogg", "fourlineclear")
   main.gameover1 = love.audio.newSource( "sounds/gameover1.ogg", "gameover1")
   main.gameover2 = love.audio.newSource( "sounds/gameover2.ogg", "gameover2")
   main.pausesound = love.audio.newSource( "sounds/pause.ogg", "pause")
   main.highscorebeep = love.audio.newSource( "sounds/highscorebeep.ogg", "beep")
   main.newlevel = love.audio.newSource( "sounds/newlevel.ogg", "newlevel")
   main.newlevel:setVolume( 0.6 )
end

function loadMenuMusic()
   main.music = {}

   main.music[1] = love.audio.newSource( "sounds/themeA.ogg", "music1")
   main.music[1]:setVolume( 0.6 )
   main.music[1]:setLooping( true )
   love.audio.play(main.music[1])
   love.audio.pause(main.music[1])

   main.music[2] = love.audio.newSource( "sounds/themeB.ogg", "music2")
   main.music[2]:setVolume( 0.6 )
   main.music[2]:setLooping( true )
   love.audio.play(main.music[2])
   love.audio.pause(main.music[2])

   main.music[3] = love.audio.newSource( "sounds/themeC.ogg", "music3")
   main.music[3]:setVolume( 0.6 )
   main.music[3]:setLooping( true )
   love.audio.play(main.music[3])
   love.audio.pause(main.music[3])

   main.musictitle = love.audio.newSource( "sounds/titlemusic.ogg", "title")
   main.musictitle:setVolume( 0.6 )
   main.musictitle:setLooping( true )
   love.audio.play(main.musictitle)
   love.audio.pause(main.musictitle)

   main.musicoptions = love.audio.newSource( "sounds/musicoptions.ogg", "options")
   main.musicoptions:setVolume( 1 )
   main.musicoptions:setLooping( true )
   love.audio.play(main.musicoptions)
   love.audio.pause(main.musicoptions)
end

function loadimages()
   --IMAGES--
   --menu--
   main.stabyourselflogo = newPaddedImage("graphics/stabyourselflogo.png")
   main.logo = newPaddedImage("graphics/logo.png")
   main.title = newPaddedImage("graphics/title.png")
   main.gametype = newPaddedImage("graphics/gametype.png")
   main.mpmenu = newPaddedImage("graphics/mpmenu.png")
   main.optionsmenu = newPaddedImage("graphics/options.png")
   main.volumeslider = newPaddedImage("graphics/volumeslider.png")
   ----game--
   main.gamebackground = newPaddedImage("graphics/gamebackground.png")
   main.gamebackgroundcutoff = newPaddedImage("graphics/gamebackgroundgamea.png")
   main.gamebackgroundmulti = newPaddedImage("graphics/gamebackgroundmulti.png")
   main.multiresults = newPaddedImage("graphics/multiresults.png")

   main.number1 = newPaddedImage("graphics/versus/number1.png")
   main.number2 = newPaddedImage("graphics/versus/number2.png")
   main.number3 = newPaddedImage("graphics/versus/number3.png")

   main.gameover = newPaddedImage("graphics/gameover.png")
   main.gameovercutoff = newPaddedImage("graphics/gameovercutoff.png")
   main.pausegraphic = newPaddedImage("graphics/pause.png")
   main.pausegraphiccutoff = newPaddedImage("graphics/pausecutoff.png")

   ----figures--
   main.marioidle = newPaddedImage("graphics/versus/marioidle.png")
   main.mariojump = newPaddedImage("graphics/versus/mariojump.png")
   main.mariocry1 = newPaddedImage("graphics/versus/mariocry1.png")
   main.mariocry2 = newPaddedImage("graphics/versus/mariocry2.png")

   main.luigiidle = newPaddedImage("graphics/versus/luigiidle.png")
   main.luigijump = newPaddedImage("graphics/versus/luigijump.png")
   main.luigicry1 = newPaddedImage("graphics/versus/luigicry1.png")
   main.luigicry2 = newPaddedImage("graphics/versus/luigicry2.png")

   --rockets--
   main.rocket1 = newPaddedImage("graphics/rocket1.png");
   --main.rocket1:setFilter( "nearest", "nearest" )
   main.rocket2 = newPaddedImage("graphics/rocket2.png")
   main.rocket3 = newPaddedImage("graphics/rocket3.png")
   main.spaceshuttle = newPaddedImage("graphics/spaceshuttle.png")

   main.rocketbackground = newPaddedImage("graphics/rocketbackground.png")
   main.bigrocketbackground = newPaddedImage("graphics/bigrocketbackground.png")
   main.bigrockettakeoffbackground = newPaddedImage("graphics/bigrockettakeoffbackground.png")


   main.smoke1left = newPaddedImage("graphics/smoke1left.png")
   main.smoke1right = newPaddedImage("graphics/smoke1right.png")
   main.smoke2left = newPaddedImage("graphics/smoke2left.png")
   main.smoke2right = newPaddedImage("graphics/smoke2right.png")

   main.fire1 = newPaddedImage("graphics/fire1.png")
   main.fire2 = newPaddedImage("graphics/fire2.png")
   main.firebig1 = newPaddedImage("graphics/firebig1.png")
   main.firebig2 = newPaddedImage("graphics/firebig2.png")

   main.congratsline = newPaddedImage("graphics/congratsline.png")

   ----nextpiece
   main.nextpieceimg = {}
   for i = 1, 7 do
      main.nextpieceimg[i] = newPaddedImage( "graphics/pieces/"..i..".png", scale )
   end

   ----font--
   ---- original
   main.tetrisfont = newPaddedImageFont("graphics/font.png", "0123456789abcdefghijklmnopqrstTuvwxyz.,'C-#_>:<! ")
   main.whitefont = newPaddedImageFont("graphics/fontwhite.png", "0123456789abcdefghijklmnopqrstTuvwxyz.,'C-#_>:<!+ ")
--
   ---- modified font
   -- main.tetrisfont = love.graphics.newFont("graphics/font/Masaaki-Regular.ttf")
   -- main.whitefont = love.graphics.newFont("graphics/font/Masaaki-Regular.ttf")
   love.graphics.setFont(main.tetrisfont)
   --
   ----filters!
   --stabyourselflogo:setFilter("nearest", "nearest")
   --logo:setFilter( "nearest", "nearest" )
   --title:setFilter( "nearest", "nearest" )
   --gametype:setFilter( "nearest", "nearest" )
   --mpmenu:setFilter( "nearest", "nearest" )
   --optionsmenu:setFilter( "nearest", "nearest" )
   --volumeslider:setFilter( "nearest", "nearest" )
   --gamebackground:setFilter( "nearest", "nearest" )
   --gamebackgroundcutoff:setFilter( "nearest", "nearest" )
   --gamebackgroundmulti:setFilter( "nearest", "nearest" )
   --multiresults:setFilter( "nearest", "nearest" )
   --number1:setFilter( "nearest", "nearest" )
   --number2:setFilter( "nearest", "nearest" )
   --number3:setFilter( "nearest", "nearest" )
   --gameover:setFilter( "nearest", "nearest" )
   --gameovercutoff:setFilter( "nearest", "nearest" )
   --pausegraphic:setFilter( "nearest", "nearest" )
   --pausegraphiccutoff:setFilter( "nearest", "nearest" )
   --marioidle:setFilter( "nearest", "nearest" )
   --mariojump:setFilter( "nearest", "nearest" )
   --mariocry1:setFilter( "nearest", "nearest" )
   --mariocry2:setFilter( "nearest", "nearest" )
   --luigiidle:setFilter( "nearest", "nearest" )
   --luigijump:setFilter( "nearest", "nearest" )
   --luigicry1:setFilter( "nearest", "nearest" )
   --luigicry2:setFilter( "nearest", "nearest" )
   --rocket2:setFilter( "nearest", "nearest" )
   --rocket3:setFilter( "nearest", "nearest" )
   --spaceshuttle:setFilter( "nearest", "nearest" )
   --rocketbackground:setFilter( "nearest", "nearest" )
   --bigrocketbackground:setFilter( "nearest", "nearest" )
   --bigrockettakeoffbackground:setFilter( "nearest", "nearest" )
   --smoke1left:setFilter( "nearest", "nearest" )
   --smoke1right:setFilter( "nearest", "nearest" )
   --smoke2left:setFilter( "nearest", "nearest" )
   --smoke2right:setFilter( "nearest", "nearest" )
   --fire1:setFilter( "nearest", "nearest" )
   --fire2:setFilter( "nearest", "nearest" )
   --firebig1:setFilter( "nearest", "nearest" )
   --firebig2:setFilter( "nearest", "nearest" )
   --congratsline:setFilter( "nearest", "nearest" )
end

function love.update(dt)
   if main.gamestate == nil then
      startdelaytime = startdelaytime + dt
      if startdelaytime >= startdelay then
         start()
      end
   end

   if skipupdate then
      skipupdate = false
      return
   end
   
   if cuttingtimer ~= 0 then
      dt = math.min(dt, minfps)
   end
   
   if main.gamestate == "logo" or main.gamestate == "credits" or main.gamestate == "title" or main.gamestate == "menu" or main.gamestate == "multimenu" or main.gamestate == "highscoreentry" or main.gamestate == "options" then
      menu_update(dt)
   elseif main.gamestate == "gameA" or main.gamestate == "failingA" then
      if pause == false then
         gameA_update(dt)
      end
   elseif main.gamestate == "gameB" or main.gamestate == "failingB" then
      if pause == false then
         gameB_update(dt)
      end
      elseif main.gamestate == "gameBmulti" or main.gamestate == "failingBmulti" or main.gamestate == "failedBmulti" or main.gamestate == "gameBmulti_results" then
      gameBmulti_update(dt)
   elseif main.gamestate == "rocket1" or main.gamestate == "rocket2" or main.gamestate == "rocket3" or main.gamestate == "rocket4" then
      rocket_update()
   end
end

function love.draw()
   if main.gamestate == "logo" or main.gamestate == "credits" or main.gamestate == "title" or main.gamestate == "menu" or main.gamestate == "multimenu" or main.gamestate == "highscoreentry" or main.gamestate == "options" then
      menu_draw()
   elseif main.gamestate == "gameA" or main.gamestate == "failingA" then
      gameA_draw()
   elseif main.gamestate == "gameB" or main.gamestate == "failingB" then
      gameB_draw()
   elseif main.gamestate == "gameBmulti" or main.gamestate == "failingBmulti" or main.gamestate == "failedBmulti" or main.gamestate == "gameBmulti_results" then
      gameBmulti_draw()
   elseif main.gamestate == "failed" then
      failed_draw()
   elseif main.gamestate == "rocket1" or main.gamestate == "rocket2" or main.gamestate == "rocket3" or main.gamestate == "rocket4" then
      rocket_draw()
   end
end

function newImageData(path, s)
   local imagedata = love.image.newImageDataFromPath( path )

   local width, height = imagedata:getWidth(), imagedata:getHeight()

   local rr, rg, rb = unpack(getrainbowcolor(hue))

   for y = 0, height-1 do
      for x = 0, width-1 do
         local oldr, oldg, oldb, olda = imagedata:getPixel(x, y)

         if olda ~= 0 then
            if oldr > 203 and oldr < 213 then --lightgrey
               local r = 145 + rr*64
               local g = 145 + rg*64
               local b = 145 + rb*64
               imagedata:setPixel(x, y, r, g, b, olda)
            elseif oldr > 107 and oldr < 117 then --darkgrey
               local r = 73 + rr*43
               local g = 73 + rg*43
               local b = 73 + rb*43
               imagedata:setPixel(x, y, r, g, b, olda)
            end
         end
      end
   end

   -- Scaled last: the loop above walks the texture pixel by pixel, and a scaled
   -- imagedata reports the enlarged size while the texture behind it stays the
   -- size it was loaded at.
   if s then
      imagedata = scaleImagedata(imagedata, s)
   end

   return imagedata
end

-- The power-of-two padding this used to do is a LOVE 0.7 texture requirement
-- that vita2d does not have, so it is skipped on the Vita: it went through
-- LoveImageData:paste, which cannot expand a source that is scaled on the GPU.
function newPaddedImage(filename, s)
   love.trace("image " .. filename)
   local source = newImageData(filename)

   if s then
      source = scaleImagedata(source, s)
   end

   return love.graphics.newImageFromImageData(source)
end

function padImagedata(source) --returns image, not imagedata!
    return love.graphics.newImageFromImageData(source)
end

function newPaddedImageFont(filename, glyphs)
    local source = newImageData(filename)
    local w, h = source:getWidth(), source:getHeight()

    love.trace("power of two")
    -- Find closest power-of-two.
    local wp = math.pow(2, math.ceil(math.log(w)/math.log(2)))
    local hp = math.pow(2, math.ceil(math.log(h)/math.log(2)))

    -- Only pad if needed:
    if wp ~= w or hp ~= h then
        local padded = love.image.newImageData(wp, hp)
        padded:paste(source, 0, 0)
        local image = love.graphics.newImageFromImageData(padded)
        image:setFilter("nearest", "nearest")
        return love.graphics.newImageFont(image.id, glyphs)
    end

    return love.graphics.newImageFont(source, glyphs)
end

-- Nearest-neighbour upscale of the piece graphics. The original copied every
-- pixel in Lua; on the Vita the factor is handed to the GPU at draw time
-- instead, so this stays a constant-time call no matter how large the scale is.
function scaleImagedata(imagedata, i)
   if i == nil or i == 1 then
      return imagedata
   end

   return love.image.scaledImageData(imagedata, i)
end

function changevolume(i)
   main.music[1]:setVolume( 0.6*i )
   main.music[2]:setVolume( 0.6*i )
   main.music[3]:setVolume( 0.6*i )
   main.musictitle:setVolume( 0.6*i )
   main.musichighscore:setVolume( 0.6*i )
   main.musicrocket4:setVolume( 0.6*i )
   main.musicrocket1to3:setVolume( 0.6*i )
   main.musicresults:setVolume( i )
   main.highscoreintro:setVolume( 0.6*i )
   main.musicoptions:setVolume( i )
   main.boot:setVolume( i )
   main.blockfall:setVolume( i )
   main.blockturn:setVolume( i )
   main.blockmove:setVolume( i )
   main.lineclear:setVolume( i )
   main.fourlineclear:setVolume( i )
   main.gameover1:setVolume( i )
   main.gameover2:setVolume( i )
   main.pausesound:setVolume( i )
   main.highscorebeep:setVolume( i )
   main.newlevel:setVolume( 0.6*i )
end

function loadoptions()
   if love.filesystem.exists("options.txt") then
      local s = love.filesystem.read("options.txt")
      local split1 = s:split("\n")
      for i = 1, #split1 do
         local split2 = split1[i]:split("=")
         if split2[1] == "volume" then
            local v = tonumber(split2[2])
            --clamp and round
            if v < 0 then
               v = 0
            elseif v > 1 then
               v = 1
            end
            v = math.floor(v*10)/10
            
            volume = v
            
         elseif split2[1] == "hue" then
            hue = tonumber(split2[2])
         
         elseif split2[1] == "scale" then
            scale = tonumber(split2[2])
         
         elseif split2[1] == "fullscreen" then
            if split2[2] == "true" then
               fullscreen = true
            else
               fullscreen = false
            end   
         end
      end
      
      if volume == nil then
         volume = 1
      end
      if hue == nil then
         hue = 0.08
      end
      if fullscreen == nil then
         fullscreen = false
      end
      
      if scale == nil then
         scale = suggestedscale
      end
      
      
   else
      volume = 1
      hue = 0.08
      autosize()
      scale = suggestedscale
      fullscreen = false
   end
   
   saveoptions()
end

function saveoptions()
   local s = ""
   
   s = s .. "volume=" .. volume .. "\n"
   s = s .. "hue=" .. hue .. "\n"
   s = s .. "scale=" .. scale .. "\n"
   s = s .. "fullscreen=" .. tostring(fullscreen) .. "\n"
   
   love.filesystem.write("options.txt", s)
end

function autosize()
   local modes = love.graphics.getModes()
   desktopwidth, desktopheight = modes[1]["width"], modes[1]["height"]
end

function togglefullscreen(fullscr)
   fullscreen = fullscr
   love.mouse.setVisible( not fullscreen )
   if fullscr == false then
      scale = suggestedscale
      physicsscale = scale/4
      love.graphics.setMode( 160*scale, 144*scale, false, vsync, 0 )
   else
      love.graphics.setMode( 0, 0, true, vsync, 16 )
      desktopwidth, desktopheight = love.graphics.getWidth(), love.graphics.getHeight()
      suggestedscale = math.min(math.floor((desktopheight-50)/144), math.floor((desktopwidth-10)/160))
      suggestedscale = math.min(math.floor((desktopheight-50)/144), math.floor((desktopwidth-10)/160))
      if suggestedscale > 5 then
         suggestedscale = 5
      end
      maxscale = math.min(math.floor(desktopheight/144), math.floor(desktopwidth/160))
      
      scale = maxscale
      physicsscale = scale/4

      -- no letterboxing: the wrapper stretches the canvas over the whole Vita screen
      fullscreenoffsetX = 0
      fullscreenoffsetY = 0
   end
end

function loadhighscores()
   if gameno == 1 then
      fileloc = "highscoresA.txt"
   else
      fileloc = "highscoresB.txt"
   end
   
   if love.filesystem.exists( fileloc ) then
      
      highdata = love.filesystem.read( fileloc )
      highdata = highdata:split(";")
      highscore = {}
      highscorename = {}
      for i = 1, 3 do
         highscore[i] = tonumber(highdata[i*2])
         highscorename[i] = string.lower(highdata[i*2-1])
      end
   else
      highscore = {}
      highscorename = {}
      highscore[1] = 0
      highscorename[1] = ""
      highscore[2] = 0
      highscorename[2] = ""
      highscore[3] = 0
      highscorename[3] = ""
      savehighscores()
   end
end

function newhighscores()
   highscore = {}
   highscorename = {}
   highscore[1] = 0
   highscorename[1] = ""
   highscore[2] = 0
   highscorename[2] = ""
   highscore[3] = 0
   highscorename[3] = ""
   savehighscores()
end

function savehighscores()
   if gameno == 1 then
      fileloc = "highscoresA.txt"
   else
      fileloc = "highscoresB.txt"
   end
   
   highdata = ""
   for i = 1, 3 do
      highdata = highdata..highscorename[i]..";"..highscore[i]..";"
   end
   love.filesystem.write( fileloc, highdata.."\n" )
end

function changescale(i)
   love.graphics.setMode( 160*i, 144*i, false, vsync, 0 )
   nextpieceimg = {}
   for j = 1, 7 do
      nextpieceimg[j] = newPaddedImage( "graphics/pieces/"..j..".png", i )
   end
   physicsscale = i/4
end

function isElement(t, value)
   for i, v in pairs(t) do
      if v == value then
         return true
      end
   end
   
   return false
end

function string:split(delimiter)
   local result = {}
   local from  = 1
   local delim_from, delim_to = string.find( self, delimiter, from  )
   while delim_from do
      table.insert( result, string.sub( self, from , delim_from-1 ) )
      from  = delim_to + 1
      delim_from, delim_to = string.find( self, delimiter, from  )
   end
   table.insert( result, string.sub( self, from  ) )
   return result
end

function pythagoras(a, b)
   c = math.sqrt(a^2 + b^2)
   if a < 0 or b < 0 then
      c = -c
   end
   return c
end

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function table2string(mytable)
   output = {}
   for i, v in pairs (mytable) do
      output[i] = mytable[i]
   end
   return output
end

function getPoints2table(shape)
   x1,y1,x2,y2,x3,y3,x4,y4,x5,y5,x6,y6,x7,y7,x8,y8 = shape:getPoints()
   if x4 == nil then
      return {x1,y1,x2,y2,x3,y3}
   end
   if x5 == nil then
      return {x1,y1,x2,y2,x3,y3,x4,y4}
   end
   if x6 == nil then
      return {x1,y1,x2,y2,x3,y3,x4,y4,x5,y5}
   end
   if x7 == nil then
      return {x1,y1,x2,y2,x3,y3,x4,y4,x5,y5,x6,y6}
   end
   if x8 == nil then
      return {x1,y1,x2,y2,x3,y3,x4,y4,x5,y5,x6,y6,x7,y7}
   end
   return     {x1,y1,x2,y2,x3,y3,x4,y4,x5,y5,x6,y6,x7,y7,x8,y8}
end

function getrainbowcolor(i)
   local r, g, b
   if i < 1/6 then
      r = 1
      g = i*6
      b = 0
   elseif i >= 1/6 and i < 2/6 then
      r = (1/6-(i-1/6))*6
      g = 1
      b = 0
   elseif i >= 2/6 and i < 3/6 then
      r = 0
      g = 1
      b = (i-2/6)*6
   elseif i >= 3/6 and i < 4/6 then
      r = 0
      g = (1/6-(i-3/6))*6
      b = 1
   elseif i >= 4/6 and i < 5/6 then
      r = (i-4/6)*6
      g = 0
      b = 1
   else
      r = 1
      g = 0
      b = (1/6-(i-5/6))*6
   end
   
   return {r, g, b}
end

-- TODO: Either remove any code that expects keyboard text input or use vita touch keyboard
function love.keypressed( key )
   if main.gamestate == nil then
      if controls.check("return", key) then
         main.gamestate = "title"
         love.graphics.setBackgroundColor( 0, 0, 0)
         love.audio.resume(main.musictitle)
         oldtime = love.timer.getTime()
      end
      
    elseif main.gamestate == "logo" then
      if controls.check("return", key) then
         main.gamestate = "title"
         love.graphics.setBackgroundColor( 0, 0, 0)
         love.audio.resume(main.musictitle)
         oldtime = love.timer.getTime()
      end
      
   elseif main.gamestate == "credits" then
      if controls.check("return", key) then
         main.gamestate = "title"
         love.graphics.setBackgroundColor( 0, 0, 0)
         love.audio.resume(main.musictitle)
         oldtime = love.timer.getTime()
      end
      
   elseif main.gamestate == "title" then
      if controls.check("return", key) then
         if main.playerselection ~= 3 then
            if main.soundenabled then
               love.audio.pause(main.musictitle)
               if main.musicno < 4 then
                  love.audio.resume(main.music[main.musicno])
               end
            end
         end
         if main.playerselection == 1 then
            main.gamestate = "menu"
         elseif main.playerselection == 2 then
            main.gamestate = "multimenu"
         else
            main.gamestate = "options"
            if main.soundenabled then
               love.audio.pause(main.musictitle)
               love.audio.resume(main.musicoptions)
            end
            optionsselection = 1
         end
      elseif controls.check("escape", key) then
         love.event.push("q")
      elseif controls.check("left", key) and main.playerselection > 1 then
         main.playerselection = main.playerselection - 1
      elseif controls.check("right", key) and main.playerselection < 3 then
         main.playerselection = main.playerselection + 1
      end
      
   elseif main.gamestate == "menu" then   
      main.oldmusicno = main.musicno
      if controls.check("escape", key) then
         if main.musicno < 4 then
            love.audio.pause(main.music[main.musicno])
         end
         main.gamestate = "title"
         if main.soundenabled then
            love.audio.pause(main.musictitle)
            love.audio.resume(main.musictitle)
         end
      elseif key == "backspace" then
         newhighscores()
      elseif controls.check("return", key) then
         if gameno == 1 then
            gameA_load()
         else
            gameB_load()
         end
      elseif controls.check("left", key) then
         if selection == 2 or selection == 4 or selection == 6 then
            selection = selection - 1
            selectblink = true
            oldtime = love.timer.getTime()
         end
      elseif controls.check("right", key) then
         if selection == 1 or selection == 3 or selection == 5 then
            selection = selection + 1
            selectblink = true
            oldtime = love.timer.getTime()
         end
      elseif controls.check("up", key) then
         if selection == 3 or selection == 4 or selection == 5 or selection == 6 then
            selection = selection - 2
            selectblink = true
            oldtime = love.timer.getTime()
            if selection < 3 then
               selection = gameno
               selectblink = false
               oldtime = love.timer.getTime()
            end
         elseif selection == 1 or selection == 2 then
            selection = main.musicno + 2
            selectblink = false
            oldtime = love.timer.getTime()
         end
      elseif controls.check("down", key) then
         if selection == 1 or selection == 2 or selection == 3 or selection == 4 then
            selection = selection + 2
            selectblink = true
            oldtime = love.timer.getTime()
            if selection > 2 and selection < 5 then
               selection = main.musicno + 2
               selectblink = false
               oldtime = love.timer.getTime()
            end
         elseif selection == 5 or selection == 6 then
            selection = gameno
            selectblink = false
            oldtime = love.timer.getTime()
         end
      end
      if selection > 2 and not controls.check("escape", key) then
         main.musicno = selection - 2
         love.audio.pause(main.music[1])
         love.audio.pause(main.music[2])
         love.audio.pause(main.music[3])
         if main.musicno < 4 then
            love.audio.resume(main.music[main.musicno])
         end
      elseif not controls.check("escape", key) then
         gameno = selection
         loadhighscores()
      end
   
   elseif main.gamestate == "options" then
      if controls.check("escape", key) then
         if main.soundenabled then
            love.audio.pause(main.musicoptions)
            love.audio.pause(main.musictitle)
            love.audio.resume(main.musictitle)
         end
         saveoptions()
         -- loadimages()
         main.gamestate = "title"
      elseif controls.check("down", key) then
         optionsselection = optionsselection + 1
         if optionsselection > #optionschoices then
            optionsselection = 1
         end
         selectblink = true
         oldtime = love.timer.getTime()
         
      elseif controls.check("up", key) then
         optionsselection = optionsselection - 1
         if optionsselection == 0 then
            optionsselection = #optionschoices
         end
         selectblink = true
         oldtime = love.timer.getTime()
         
      elseif controls.check("left", key) then
         if optionsselection == 1 then
            if volume >= 0.1 then
               volume = volume - 0.1
               if volume < 0.1 then
                  volume = 0
               end
               changevolume(volume)
            end
            
         elseif optionsselection == 3 then
            if fullscreen == false then
               if scale > 1 then
                  scale = scale - 1
                  changescale(scale)
               end
            end
            
         elseif optionsselection == 4 then
            if fullscreen == false then
               togglefullscreen(true)
            end
         
         end
         
      elseif controls.check("right", key) then
         if optionsselection == 1 then
            if volume <= 0.9 then
               volume = volume + 0.1
               changevolume(volume)
            end
            
         elseif optionsselection == 3 then
            if fullscreen == false then
               if scale < maxscale then
                  scale = scale + 1
                  changescale(scale)
               end
            end
            
         elseif optionsselection == 4 then
            if fullscreen == true then
               togglefullscreen(false)
            end
            
         end
         
      elseif controls.check("return", key) then
         if optionsselection == 1 then
            volume = 1
            changevolume(volume)
         elseif optionsselection == 2 then
            hue = 0.08
            main.optionsmenu = newPaddedImage("graphics/options.png")
            main.optionsmenu:setFilter( "nearest", "nearest" )
            main.volumeslider = newPaddedImage("graphics/volumeslider.png")
            main.volumeslider:setFilter( "nearest", "nearest" )
         elseif optionsselection == 3 then
            if fullscreen == false then
               if scale ~= suggestedscale then
                  scale = suggestedscale
                  changescale(scale)
               end
            end
         elseif optionsselection == 4 then
            if fullscreen == true then
               togglefullscreen(false)
            end
         end
         
      end
   
   elseif main.gamestate == "multimenu" then
      main.oldmusicno = main.musicno
      if controls.check("escape", key) then
         if main.musicno < 4 then
            love.audio.pause(main.music[main.musicno])
         end
         main.gamestate = "title"
         love.audio.pause(main.musictitle)
         love.audio.resume(main.musictitle)
      elseif controls.check("return", key) then
         gameBmulti_load()
      elseif controls.check("left", key) then
         if selection == 2 or selection == 4 or selection == 6 then
            selection = selection - 1
            selectblink = true
            oldtime = love.timer.getTime()
         end
      elseif controls.check("right", key) then
         if selection == 1 or selection == 3 or selection == 5 then
            selection = selection + 1
            selectblink = true
            oldtime = love.timer.getTime()
         end
      elseif controls.check("up", key) then
         if selection == 3 or selection == 4 or selection == 5 or selection == 6 then
            selection = selection - 2
            selectblink = true
            oldtime = love.timer.getTime()
            if selection < 3 then
               selection = gameno
               selectblink = false
               oldtime = love.timer.getTime()
            end
         elseif selection == 1 or selection == 2 then
            selection = main.musicno + 2
            selectblink = false
            oldtime = love.timer.getTime()
         end
      elseif controls.check("down", key) then
         if selection == 1 or selection == 2 or selection == 3 or selection == 4 then
            selection = selection + 2
            selectblink = true
            oldtime = love.timer.getTime()
            if selection > 2 and selection < 5 then
               selection = main.musicno + 2
               selectblink = false
               oldtime = love.timer.getTime()
            end
         elseif selection == 5 or selection == 6 then
            selection = gameno
            selectblink = false
            oldtime = love.timer.getTime()
         end
      end
      if selection > 2 and not controls.check("return", key) and not controls.check("escape", key) then
         main.musicno = selection - 2
         if main.oldmusicno ~= main.musicno and main.oldmusicno ~= 4 then
            love.audio.pause(main.music[main.oldmusicno])
         end
         if main.musicno < 4 then
            love.audio.resume(main.music[main.musicno])
         end
      elseif not controls.check("return", key) and not controls.check("escape", key) then
         gameno = selection
         loadhighscores()
      end
         
   elseif main.gamestate == "gameA" or main.gamestate == "gameB" or main.gamestate == "failingA" or main.gamestate == "failingB" then

      if controls.check("return", key) then
         pause = not pause

         if pause == true then
            if main.musicno < 4 then
               love.audio.pause(music[main.musicno])
            end
            love.audio.pause(main.pausesound)
            love.audio.resume(main.pausesound)
         else
            if main.musicno < 4 then
               love.audio.resume(music[main.musicno])
            end
         end
      end
      if main.gamestate == "gameA" or main.gamestate == "gameB" then
         if controls.check("escape", key) then
            oldtime = love.timer.getTime()
            main.gamestate = "menu"
         end
         
         if pause == false and (cuttingtimer == lineclearduration or main.gamestate == "gameB") then
            --if key == "up" then --STOP ROTATION OF BLOCK (makes it too easy..)
            --   tetribodies[counter]:setAngularVelocity(0)
            --end
            if controls.check("left", key) or controls.check("right", key) then
               love.audio.pause(main.blockmove)
               love.audio.resume(main.blockmove)
            elseif controls.check("rotateleft", key) or controls.check("rotateright", key) then
               love.audio.pause(main.blockturn)
               love.audio.resume(main.blockturn)
            end
         end
      end
   elseif main.gamestate == "gameBmulti" and gamestarted == false then
      if controls.check("escape", key) then
         if not fullscreen then
            love.graphics.setMode( 160*scale, 144*scale, false, vsync, 0 )
         end
         main.gamestate = "multimenu"
         if main.musicno < 4 then
            love.audio.resume(main.music[main.musicno])
         end
      end
   elseif main.gamestate == "gameBmulti" and gamestarted == true then
      if controls.check("escape", key) then
         if not fullscreen then
            love.graphics.setMode( 160*scale, 144*scale, false, vsync, 0 )
         end
         main.gamestate = "multimenu"
      end
      if controls.check("left", key) or controls.check("right", key) or controls.check("leftp2", key) or controls.check("rightp2", key) then
         love.audio.pause(main.blockmove)
         love.audio.resume(main.blockmove)
      elseif controls.check("rotateleft", key) or controls.check("rotateright", key) or controls.check("rotaterightp2", key) or controls.check("rotateleftp2", key) then
         love.audio.pause(main.blockturn)
         love.audio.resume(main.blockturn)
      end
      
   elseif main.gamestate == "gameBmulti_results" then
      if controls.check("return", key) or controls.check("escape", key) then
         if main.musicno < 4 then
            love.audio.pause(main.musicresults)
            love.audio.resume(main.music[main.musicno])
         end
         if not fullscreen then
            love.graphics.setMode( 160*scale, 144*scale, false, vsync, 0 )
         end
         main.gamestate = "multimenu"
      end
      
   elseif main.gamestate == "failed" then
      if controls.check("return", key) or controls.check("escape", key) then 
         love.audio.pause(main.gameover2)
         rocket_load()
      end
   elseif main.gamestate == "highscoreentry" then
      if controls.check("return", key) then
         main.gamestate = "menu"
         savehighscores()
         if musicchanged == true then
            love.audio.pause(main.musichighscore)
         else
            love.audio.pause(main.highscoreintro)
         end
         if main.musicno < 4 then
            love.audio.resume(main.music[main.musicno])
         end
      elseif key == "backspace" then
         if highscorename[highscoreno]:len() > 0 then
            cursorblink = true
            highscorename[highscoreno] = string.sub(highscorename[highscoreno], 1, highscorename[highscoreno]:len()-1)
         end
      end
   elseif string.sub(main.gamestate, 1, 6) == "rocket" then
      if controls.check("return", key) then
         love.audio.pause(main.musicrocket1to3)
         love.audio.pause(main.musicrocket4)
         failed_checkhighscores()
      end
   end
end

return main