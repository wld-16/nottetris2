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
set(VITA_TITLEID  "WLDW00001")
# Optional version string to show in LiveArea's more info screen
set(VITA_VERSION  "01.00")

## Flags and includes for building
# Note that we make sure not to overwrite previous flags
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -DHAVE_MPG123 -DHAVE_OGGVORBIS -DUSE_AUDIO_RESAMPLER -DHAVE_LIBSPEEXDSP")
# Optional. You can specify more param.sfo flags this way.
set(VITA_MKSFOEX_FLAGS "${VITA_MKSFOEX_FLAGS} -d PARENTAL_LEVEL=1")

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
        src/system.cpp
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
        FILE sce_sys/icon0.png sce_sys/icon0.png
        FILE sce_sys/livearea/contents/bg.png sce_sys/livearea/contents/bg.png
        FILE sce_sys/livearea/contents/startup.png sce_sys/livearea/contents/startup.png
        FILE sce_sys/livearea/contents/template.xml sce_sys/livearea/contents/template.xml
)
