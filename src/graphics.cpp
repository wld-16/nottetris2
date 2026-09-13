/*----------------------------------------------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------------------------------------------#
#------  This File is Part Of : ----------------------------------------------------------------------------------------#
#------- _  -------------------  ______   _   --------------------------------------------------------------------------#
#------ | | ------------------- (_____ \ | |  --------------------------------------------------------------------------#
#------ | | ---  _   _   ____    _____) )| |  ____  _   _   ____   ____   ----------------------------------------------#
#------ | | --- | | | | / _  |  |  ____/ | | / _  || | | | / _  ) / ___)  ----------------------------------------------#
#------ | |_____| |_| |( ( | |  | |      | |( ( | || |_| |( (/ / | |  --------------------------------------------------#
#------ |_______)\____| \_||_|  |_|      |_| \_||_| \__  | \____)|_|  --------------------------------------------------#
#------------------------------------------------- (____/  -------------------------------------------------------------#
#------------------------   ______   _   -------------------------------------------------------------------------------#
#------------------------  (_____ \ | |  -------------------------------------------------------------------------------#
#------------------------   _____) )| | _   _   ___   ------------------------------------------------------------------#
#------------------------  |  ____/ | || | | | /___)  ------------------------------------------------------------------#
#------------------------  | |      | || |_| ||___ |  ------------------------------------------------------------------#
#------------------------  |_|      |_| \____|(___/   ------------------------------------------------------------------#
#-----------------------------------------------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------------------------------------------#
#- Licensed under the GPL License --------------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------------------------------------------#
#- Copyright (c) Nanni <lpp.nanni@gmail.com> ---------------------------------------------------------------------------#
#- Copyright (c) Rinnegatamante <rinnegatamante@gmail.com> -------------------------------------------------------------#
#-----------------------------------------------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------------------------------------------#
#- Credits : -----------------------------------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------------------------------------------#
#- All the devs involved in Rejuvenate and vita-toolchain --------------------------------------------------------------#
#- xerpi for drawing libs and for FTP server code ----------------------------------------------------------------------#
#-----------------------------------------------------------------------------------------------------------------------*/

#include <cstdlib>
#include <psp2/io/fcntl.h>
#include <cstring>

#include "include/nottetris.h"
#include "include/utils.h"

#define stringify(str) #str
#define VariableRegister(lua, value) do { lua_pushinteger(lua, value); lua_setglobal (lua, stringify(value)); } while(0)

vita2d_pgf* debug_font;
struct ttf {
    uint32_t magic;
    vita2d_font* f;
    vita2d_pgf* f2;
    vita2d_pvf* f3;
    int size;
    float scale;
};

struct rescaler {
    vita2d_texture* fbo;
    int x;
    int y;
    float x_scale;
    float y_scale;
};

struct animated_texture {
    void *frames;
    uint32_t num_frames;
};

static bool isRescaling = false;
static rescaler scaler;

static char asyncImagePath[512];

extern int FORMAT_BMP;
extern int FORMAT_PNG;
extern int FORMAT_JPG;

#ifdef PARANOID
static bool draw_state = false;
#endif

static int lua_init(lua_State *L) {
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 0)
        return luaL_error(L, "wrong number of arguments");
#endif
#ifdef PARANOID
    if (draw_state)
        return luaL_error(L, "initBlend can't be called inside a blending phase.");
    else
        draw_state = true;
#endif
    if (isRescaling) {
        vita2d_pool_reset();
        vita2d_start_drawing_advanced(scaler.fbo, SCE_GXM_SCENE_FRAGMENT_SET_DEPENDENCY);
    } else
        vita2d_start_drawing();
    return 0;
}

static int lua_print(lua_State *L) {
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 4 && argc != 5)
        return luaL_error(L, "wrong number of arguments.");
#endif
#ifdef PARANOID
    if (!draw_state)
        return luaL_error(L, "debugPrint can't be called outside a blending phase.");
#endif
    int x = luaL_checkinteger(L, 1);
    int y = luaL_checkinteger(L, 2);
    char* text = (char*)luaL_checkstring(L, 3);
    int color = luaL_checkinteger(L, 4);
    float scale = 1.0f;
    if (argc == 5) scale = luaL_checknumber(L, 5);
    vita2d_pgf_draw_text(debug_font, x, y + 17.402f * scale, RGBA8((color) & 0xFF, (color >> 8) & 0xFF, (color >> 16) & 0xFF, (color >> 24) & 0xFF), scale, text);
    return 0;
}

static int lua_pixel(lua_State *L) {
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 3 && argc != 4)
        return luaL_error(L, "wrong number of arguments.");
#endif
#ifdef PARANOID
    if (!draw_state && argc == 3)
        return luaL_error(L, "drawPixel can't be called outside a blending phase for on screen drawing.");
#endif
    float x = luaL_checknumber(L, 1);
    float y = luaL_checknumber(L, 2);
    uint32_t color = luaL_checkinteger(L, 3);
    if (argc == 3)
        vita2d_draw_rectangle(x, y, 1, 1, RGBA8((color) & 0xFF, (color >> 8) & 0xFF, (color >> 16) & 0xFF, (color >> 24) & 0xFF));
    else {
        texture* text = (texture*)(luaL_checkinteger(L, 4));
#ifndef SKIP_ERROR_HANDLING
        if (text->magic != 0xABADBEEF)
            return luaL_error(L, "attempt to access wrong memory block type.");
#endif
        int intx = x;
        int inty = y;
        uint32_t *data = (uint32_t*)vita2d_texture_get_datap(text->text);
        uint32_t pitch = vita2d_texture_get_stride(text->text) >> 2;
        data[intx + inty * pitch] = color;
    }
    return 0;
}

static int lua_drawimg_scale(lua_State *L) {
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 5 && argc != 6)
        return luaL_error(L, "wrong number of arguments");
#endif
#ifdef PARANOID
    if (!draw_state)
        return luaL_error(L, "drawScaleImage can't be called outside a blending phase.");
#endif
    float x = luaL_checknumber(L, 1);
    float y = luaL_checknumber(L, 2);
    texture* text = (texture*)(luaL_checkinteger(L, 3));
    float x_scale = luaL_checknumber(L, 4);
    float y_scale = luaL_checknumber(L, 5);
#ifndef SKIP_ERROR_HANDLING
    if (text->magic != 0xABADBEEF)
        return luaL_error(L, "attempt to access wrong memory block type.");
#endif
    if (argc == 6) {
        uint32_t color = luaL_checkinteger(L, 6);
        vita2d_draw_texture_tint_scale(text->text, x, y, x_scale, y_scale, color);
    }else vita2d_draw_texture_scale(text->text, x, y, x_scale, y_scale);
    return 0;
}

static int lua_width(lua_State *L) {
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 1)
        return luaL_error(L, "wrong number of arguments");
#endif
    texture* text = (texture*)(luaL_checkinteger(L, 1));
#ifndef SKIP_ERROR_HANDLING
    if (text->magic != 0xABADBEEF)
        return luaL_error(L, "attempt to access wrong memory block type.");
#endif
    lua_pushinteger(L, vita2d_texture_get_width(text->text));
    return 1;
}

static int lua_height(lua_State *L) {
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 1)
        return luaL_error(L, "wrong number of arguments");
#endif
    texture* text = (texture*)(luaL_checkinteger(L, 1));
#ifndef SKIP_ERROR_HANDLING
    if (text->magic != 0xABADBEEF)
        return luaL_error(L, "attempt to access wrong memory block type.");
#endif
    lua_pushinteger(L, vita2d_texture_get_height(text->text));
    return 1;
}

static int lua_gpixel(lua_State *L) {
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 3)
        return luaL_error(L, "wrong number of arguments");
#endif
    int x = luaL_checkinteger(L, 1);
    int y = luaL_checkinteger(L, 2);
    texture* text = (texture*)(luaL_checkinteger(L, 3));
#ifndef SKIP_ERROR_HANDLING
    if (text->magic != 0xABADBEEF)
        return luaL_error(L, "attempt to access wrong memory block type.");
#endif
    uint32_t *buff = (uint32_t*)vita2d_texture_get_datap(text->text);
    lua_pushinteger(L, buff[ALIGN(vita2d_texture_get_width(text->text), 8) * y + x]);
    return 1;
}

static int lua_loadimg(lua_State *L) {
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 1 && argc != 2)
        return luaL_error(L, "wrong number of arguments");
#endif
    char* text = (char*)(luaL_checkstring(L, 1));
    SceUID file = sceIoOpen(text, SCE_O_RDONLY, 0777);
    uint16_t magic;
    sceIoRead(file, &magic, 2);
    sceIoClose(file);
    SceKernelMemBlockType type = SCE_KERNEL_MEMBLOCK_TYPE_USER_CDRAM_RW;
    if (argc == 2)
        type = luaL_checkinteger(L, 4);
    vita2d_texture_set_alloc_memblock_type(type);
    vita2d_texture *result = NULL;
    if (magic == 0x4D42)
        result = vita2d_load_BMP_file(text);
    else if (magic == 0xD8FF)
        result = vita2d_load_JPEG_file(text);
    else if (magic == 0x5089)
        result = vita2d_load_PNG_file(text);
    else
        return luaL_error(L, "Error loading image (invalid magic).");
#ifndef SKIP_ERROR_HANDLING
    if (result == NULL)
        return luaL_error(L, "Error loading image.");
#endif
    texture *ret = (texture*)malloc(sizeof(texture));
    ret->magic = 0xABADBEEF;
    ret->text = result;
    ret->data = NULL;

    lua_pushinteger(L, (uint32_t)(ret));
    return 1;
}

static int lua_term(lua_State *L) {
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 0)
        return luaL_error(L, "wrong number of arguments");
#endif
#ifdef PARANOID
    if (!draw_state)
        return luaL_error(L, "termBlend can't be called outside a blending phase.");
    else
        draw_state = false;
#endif
    vita2d_end_drawing();
    if (isRescaling) {
        vita2d_start_drawing_advanced(NULL, SCE_GXM_SCENE_VERTEX_WAIT_FOR_DEPENDENCY);
        vita2d_draw_texture_scale(scaler.fbo,scaler.x,scaler.y,scaler.x_scale,scaler.y_scale);
        vita2d_end_drawing();
    }
    if (keyboardStarted || messageStarted)
        vita2d_common_dialog_update();
    vita2d_wait_rendering_done();
    return 0;
}

static int lua_loadFont(lua_State *L) {
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 1)
        return luaL_error(L, "wrong number of arguments");
#endif
    char* text = (char*)(luaL_checkstring(L, 1));
    ttf* result = (ttf*)malloc(sizeof(ttf));
    memset(result, 0, sizeof(ttf));
    result->size = 16;
    result->scale = 0.919f;
    result->f = vita2d_load_font_file(text); // TTF font
    if (result->f == NULL) {
        result->f2 = vita2d_load_custom_pgf(text);
        if (result->f2 == NULL) {
            result->f3 = vita2d_load_custom_pvf(text);
#ifndef SKIP_ERROR_HANDLING
            if (result->f3 == NULL) {
                free(result);
                return luaL_error(L, "cannot load font file");
            }
#endif
        }
    }
    result->magic = 0x4C464E54;
    lua_pushinteger(L,(uint32_t)result);
    return 1;
}

static int lua_fprint(lua_State *L) {
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 5)
        return luaL_error(L, "wrong number of arguments");
#endif
#ifdef PARANOID
    if (!draw_state)
        return luaL_error(L, "print can't be called outside a blending phase.");
#endif
    ttf *font = (ttf *)(luaL_checkinteger(L, 1));
    float x = luaL_checknumber(L, 2);
    float y = luaL_checknumber(L, 3);
    char *text = (char *)(luaL_checkstring(L, 4));
    uint32_t color = luaL_checkinteger(L, 5);
#ifndef SKIP_ERROR_HANDLING
    if (font->magic != 0x4C464E54)
        return luaL_error(L, "attempt to access wrong memory block type");
#endif
    if (font->f != NULL)
        vita2d_font_draw_text(font->f, x, y + font->size, RGBA8((color) & 0xFF, (color >> 8) & 0xFF, (color >> 16) & 0xFF, (color >> 24) & 0xFF), font->size, text);
    else if (font->f2 != NULL)
        vita2d_pgf_draw_text(font->f2, x, y + 17.402 * font->scale, RGBA8((color) & 0xFF, (color >> 8) & 0xFF, (color >> 16) & 0xFF, (color >> 24) & 0xFF), font->scale, text);
    else
        vita2d_pvf_draw_text(font->f3, x, y + 17.402 * font->scale, RGBA8((color) & 0xFF, (color >> 8) & 0xFF, (color >> 16) & 0xFF, (color >> 24) & 0xFF), font->scale, text);
    return 0;
}


//Register our Graphics Functions
const luaL_Reg Graphics_functions[] = {
    {"debugPrint",          lua_print},
    {"drawPixel",           lua_pixel},
    {"drawScaleImage",      lua_drawimg_scale},
    {"getImageHeight",      lua_height},
    {"getImageWidth",       lua_width},
    {"getPixel",            lua_gpixel},
    {"initBlend",           lua_init},
    {"loadImage",           lua_loadimg},
    {"termBlend",           lua_term},
    {0, 0}
};

//Register our Font Functions
const luaL_Reg Font_functions[] = {
    {"load",            lua_loadFont},
    {"print",           lua_fprint},
    {0, 0}
};

void luaGraphics_init(lua_State *L) {
    uint32_t FILTER_POINT = (uint32_t)SCE_GXM_TEXTURE_FILTER_POINT;
    uint32_t FILTER_LINEAR = (uint32_t)SCE_GXM_TEXTURE_FILTER_LINEAR;
    uint32_t MEM_VRAM = (uint32_t)SCE_KERNEL_MEMBLOCK_TYPE_USER_CDRAM_RW;
    uint32_t MEM_PHYCONT_RAM = (uint32_t)SCE_KERNEL_MEMBLOCK_TYPE_USER_MAIN_PHYCONT_RW;
    uint32_t MEM_RAM = (uint32_t)SCE_KERNEL_MEMBLOCK_TYPE_USER_RW;
    VariableRegister(L, MEM_VRAM);
    VariableRegister(L, MEM_PHYCONT_RAM);
    VariableRegister(L, MEM_RAM);
    VariableRegister(L, FILTER_POINT);
    VariableRegister(L, FILTER_LINEAR);
    lua_newtable(L);
    luaL_setfuncs(L, Graphics_functions, 0);
    lua_setglobal(L, "Graphics");
    lua_newtable(L);
    luaL_setfuncs(L, Font_functions, 0);
    lua_setglobal(L, "Font");
    lua_newtable(L);
}