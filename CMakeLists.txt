## This file is a quick tutorial on writing CMakeLists for targeting the Vita
cmake_minimum_required(VERSION 3.16)

## This includes the Vita toolchain, must go before project definition
# It is a convenience so you do not have to type
# -DCMAKE_TOOLCHAIN_FILE=$VITASDK/share/vita.toolchain.cmake for cmake. It is
# highly recommended that you include this block for all projects.
if(NOT DEFINED CMAKE_TOOLCHAIN_FILE)
    if(DEFINED ENV{VITASDK})
        set(CMAKE_TOOLCHAIN_FILE "$ENV{VITASDK}/share/vita.toolchain.cmake" CACHE PATH "toolchain file")
    else()
        message(FATAL_ERROR "Please define VITASDK to point to your SDK path!")
    endif()
endif()

## Define project parameters here
# Name of the project
project(nottetris2)
# This line adds Vita helper macros, must go after project definition in order
# to build Vita specific artifacts (self/vpk).
include("${VITASDK}/share/vita.cmake" REQUIRED)

## Configuration options for this app
# Display name (under bubble in LiveArea)
set(VITA_APP_NAME "Not Tetris 2")
# Unique ID must be exactly 9 characters. Recommended: XXXXYYYYY where X =
# unique string of developer and Y = a unique number for this app
set(VITA_TITLEID  "WLDD00001")
# Optional version string to show in LiveArea's more info screen
set(VITA_VERSION  "01.00")

## Flags and includes for building
# Note that we make sure not to overwrite previous flags
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -DHAVE_MPG123 -DHAVE_OGGVORBIS -DUSE_AUDIO_RESAMPLER -DHAVE_LIBSPEEXDSP")
# Optional. You can specify more param.sfo flags this way.
set(VITA_MKSFOEX_FLAGS "${VITA_MKSFOEX_FLAGS} -d PARENTAL_LEVEL=1")

# vita-elf-create appends ~4 KiB of SCE module data at the end of the code
# segment and fails with "Cannot allocate ... bytes for SCE data" when the
# code segment ends too close to the next segment (the linker puts segments
# on 64 KiB boundaries). Pin the data segment to a fixed address far above
# the code segment so there is always room for it. If the code segment ever
# grows past this address, bump it to the next 4 MiB mark.
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--section-start=.init_array=0x81400000")

find_package(Vorbis REQUIRED)

# Add any additional include paths here
include_directories(
        src/include
)

# Add any additional library paths here
# ${CMAKE_CURRENT_BINARY_DIR} lets you use any library currently being built
link_directories(
        ${CMAKE_CURRENT_BINARY_DIR}
)

## Build and link
# Add all the files needed to compile here
add_executable(${PROJECT_NAME}
        src/include/sbrk.c
        src/include/head.h
        src/include/sha1.c
        src/include/sha1.h
        src/include/ioapi.c
        src/include/ioapi.h
        src/include/crypt.h
        src/include/audiodec/audio_decoder.h
        src/include/audiodec/audio_decoder.cpp
        src/include/audiodec/audio_resampler.h
        src/include/audiodec/audio_resampler.cpp
        src/include/audiodec/decoder_aiff.h
        src/include/audiodec/decoder_aiff.cpp
        src/include/audiodec/decoder_fmmidi.h
        src/include/audiodec/decoder_fmmidi.cpp
        src/include/audiodec/decoder_libsndfile.h
        src/include/audiodec/decoder_libsndfile.cpp
        src/include/audiodec/decoder_mpg123.h
        src/include/audiodec/decoder_mpg123.cpp
        src/include/audiodec/decoder_oggopus.h
        src/include/audiodec/decoder_oggopus.cpp
        src/include/audiodec/decoder_oggvorbis.h
        src/include/audiodec/decoder_oggvorbis.cpp
        src/include/audiodec/decoder_oggvorbis_pshv.h
        src/include/audiodec/decoder_oggvorbis_pshv.cpp
        src/include/audiodec/decoder_wav.h
        src/include/audiodec/decoder_wav.cpp
        src/include/audiodec/midiprogram.h
        src/include/audiodec/midisequencer.h
        src/include/audiodec/midisequencer.cpp
        src/include/audiodec/midisynth.h
        src/include/audiodec/midisynth.cpp
        src/include/audiodec/utils.h
        src/include/audiodec/utils.cpp
        src/main.cpp
        src/common/debugScreen.c
        src/graphics.cpp
        src/include/nottetris.h
        src/include/utils.h
        src/keyboard.cpp
        src/controls.cpp
        src/screen.cpp
        src/sound.cpp
        src/timer.cpp
        src/physics.cpp
        src/system.cpp
        src/vita2d_debug_draw.cpp
        src/vita2d_debug_draw.h
)

# Library to link to (drop the -l prefix). This will mostly be stubs.
target_link_libraries(${PROJECT_NAME}
        SceLibKernel_stub
        SceDisplay_stub
        stdc++
        pthread
        luajit-5.1
        dl
        taihen_stub
        SceSblSsMgr_stub
        vita2d
        ScePvf_stub
        freetype
        imagequant
        SceGxm_stub
        png
        jpeg
        bz2
        z
        ScePgf_stub
        SceAppMgr_stub
        SceCommonDialog_stub
        SceCtrl_stub
        SceTouch_stub
        SceMotion_stub
        SceShellSvc_stub
        SceAppUtil_stub
        mpg123
        SceAudio_stub
        SceAudioIn_stub
        SceShutterSound_stub
        ScePromoterUtil_stub
        SceJpegEnc_stub
        SceVshBridge_stub
        ScePower_stub
        vorbisfile
        ogg
        Vorbis::vorbis
        speexdsp
        box2d
)

## Create Vita files
vita_create_self(${PROJECT_NAME}.self ${PROJECT_NAME})
# The FILE directive lets you add additional files to the VPK, the syntax is
# FILE src_path dst_path_in_vpk. In this case, we add the LiveArea paths.
vita_create_vpk(${PROJECT_NAME}.vpk ${VITA_TITLEID} ${PROJECT_NAME}.self
        VERSION ${VITA_VERSION}
        NAME ${VITA_APP_NAME}
        FILE res/lua/conf.lua conf.lua
        FILE res/lua/controls.lua controls.lua
        FILE res/lua/failed.lua failed.lua
        FILE res/lua/gameA.lua gameA.lua
        FILE res/lua/gameB.lua gameB.lua
        FILE res/lua/gameBmulti.lua gameBmulti.lua
        FILE res/lua/index.lua index.lua
        FILE res/lua/main.lua main.lua
        FILE res/lua/menu.lua menu.lua
        FILE res/lua/rocket.lua rocket.lua
        FILE res/lua/wrapper/love.lua wrapper/love.lua
        FILE res/lua/wrapper/loveBody.lua wrapper/loveBody.lua
        FILE res/lua/wrapper/loveEnvironment.lua wrapper/loveEnvironment.lua
        FILE res/lua/wrapper/loveFont.lua wrapper/loveFont.lua
        FILE res/lua/wrapper/loveImage.lua wrapper/loveImage.lua
        FILE res/lua/wrapper/loveImageData.lua wrapper/loveImageData.lua
        FILE res/lua/wrapper/loveSound.lua wrapper/loveSound.lua
        FILE res/lua/wrapper/loveWorld.lua wrapper/loveWorld.lua
        FILE res/lua/wrapper/lovePolygonShape.lua wrapper/lovePolygonShape.lua
        FILE res/lua/wrapper/loveRectangleShape.lua wrapper/loveRectangleShape.lua
        FILE res/lua/wrapper/loveFixture.lua wrapper/loveFixture.lua
        # Graphics: installed to app0:/graphics, read by the game via GAME_ROOT
        FILE res/graphics/bigrocketbackground.png graphics/bigrocketbackground.png
        FILE res/graphics/bigrockettakeoffbackground.png graphics/bigrockettakeoffbackground.png
        FILE res/graphics/congratsline.png graphics/congratsline.png
        FILE res/graphics/fire1.png graphics/fire1.png
        FILE res/graphics/fire2.png graphics/fire2.png
        FILE res/graphics/firebig1.png graphics/firebig1.png
        FILE res/graphics/firebig2.png graphics/firebig2.png
        FILE res/graphics/font.png graphics/font.png
        FILE res/graphics/fontwhite.png graphics/fontwhite.png
        FILE res/graphics/gamebackground.png graphics/gamebackground.png
        FILE res/graphics/gamebackgroundgamea.png graphics/gamebackgroundgamea.png
        FILE res/graphics/gamebackgroundmulti.png graphics/gamebackgroundmulti.png
        FILE res/graphics/gameover.png graphics/gameover.png
        FILE res/graphics/gameovercutoff.png graphics/gameovercutoff.png
        FILE res/graphics/gametype.png graphics/gametype.png
        FILE res/graphics/logo.png graphics/logo.png
        FILE res/graphics/mpmenu.png graphics/mpmenu.png
        FILE res/graphics/multiresults.png graphics/multiresults.png
        FILE res/graphics/options.png graphics/options.png
        FILE res/graphics/pause.png graphics/pause.png
        FILE res/graphics/pausecutoff.png graphics/pausecutoff.png
        FILE res/graphics/rainbow.png graphics/rainbow.png
        FILE res/graphics/rocket1.png graphics/rocket1.png
        FILE res/graphics/rocket2.png graphics/rocket2.png
        FILE res/graphics/rocket3.png graphics/rocket3.png
        FILE res/graphics/rocketbackground.png graphics/rocketbackground.png
        FILE res/graphics/smoke1left.png graphics/smoke1left.png
        FILE res/graphics/smoke1right.png graphics/smoke1right.png
        FILE res/graphics/smoke2left.png graphics/smoke2left.png
        FILE res/graphics/smoke2right.png graphics/smoke2right.png
        FILE res/graphics/spaceshuttle.png graphics/spaceshuttle.png
        FILE res/graphics/stabyourselflogo.png graphics/stabyourselflogo.png
        FILE res/graphics/title.png graphics/title.png
        FILE res/graphics/volumeslider.png graphics/volumeslider.png
        FILE res/graphics/font/Masaaki-Regular.ttf graphics/font/Masaaki-Regular.ttf
        FILE res/graphics/pieces/1.png graphics/pieces/1.png
        FILE res/graphics/pieces/2.png graphics/pieces/2.png
        FILE res/graphics/pieces/3.png graphics/pieces/3.png
        FILE res/graphics/pieces/4.png graphics/pieces/4.png
        FILE res/graphics/pieces/5.png graphics/pieces/5.png
        FILE res/graphics/pieces/6.png graphics/pieces/6.png
        FILE res/graphics/pieces/7.png graphics/pieces/7.png
        FILE res/graphics/versus/luigicry1.png graphics/versus/luigicry1.png
        FILE res/graphics/versus/luigicry2.png graphics/versus/luigicry2.png
        FILE res/graphics/versus/luigiidle.png graphics/versus/luigiidle.png
        FILE res/graphics/versus/luigijump.png graphics/versus/luigijump.png
        FILE res/graphics/versus/mariocry1.png graphics/versus/mariocry1.png
        FILE res/graphics/versus/mariocry2.png graphics/versus/mariocry2.png
        FILE res/graphics/versus/marioidle.png graphics/versus/marioidle.png
        FILE res/graphics/versus/mariojump.png graphics/versus/mariojump.png
        FILE res/graphics/versus/number1.png graphics/versus/number1.png
        FILE res/graphics/versus/number2.png graphics/versus/number2.png
        FILE res/graphics/versus/number3.png graphics/versus/number3.png
        # Sounds: installed to app0:/sounds
        FILE res/sounds/4lineclear.ogg sounds/4lineclear.ogg
        FILE res/sounds/blockfall.ogg sounds/blockfall.ogg
        FILE res/sounds/boot.ogg sounds/boot.ogg
        FILE res/sounds/gameover1.ogg sounds/gameover1.ogg
        FILE res/sounds/gameover2.ogg sounds/gameover2.ogg
        FILE res/sounds/highscorebeep.ogg sounds/highscorebeep.ogg
        FILE res/sounds/highscoreintro.ogg sounds/highscoreintro.ogg
        FILE res/sounds/highscoremusic.ogg sounds/highscoremusic.ogg
        FILE res/sounds/lineclear.ogg sounds/lineclear.ogg
        FILE res/sounds/move.ogg sounds/move.ogg
        FILE res/sounds/musicoptions.ogg sounds/musicoptions.ogg
        FILE res/sounds/newlevel.ogg sounds/newlevel.ogg
        FILE res/sounds/pause.ogg sounds/pause.ogg
        FILE res/sounds/resultsmusic.ogg sounds/resultsmusic.ogg
        FILE res/sounds/rocket1to3.ogg sounds/rocket1to3.ogg
        FILE res/sounds/rocket4.ogg sounds/rocket4.ogg
        FILE res/sounds/themeA.ogg sounds/themeA.ogg
        FILE res/sounds/themeB.ogg sounds/themeB.ogg
        FILE res/sounds/themeC.ogg sounds/themeC.ogg
        FILE res/sounds/titlemusic.ogg sounds/titlemusic.ogg
        FILE res/sounds/turn.ogg sounds/turn.ogg
        FILE sce_sys/icon0.png sce_sys/icon0.png
        FILE sce_sys/livearea/contents/bg.png sce_sys/livearea/contents/bg.png
        FILE sce_sys/livearea/contents/startup.png sce_sys/livearea/contents/startup.png
        FILE sce_sys/livearea/contents/template.xml sce_sys/livearea/contents/template.xml
)
