#ifndef NOTTETRIS2_NOTTETRIS_H
#define NOTTETRIS2_NOTTETRIS_H

#include <luajit-2.1/lua.hpp>
#include <cstdio>
#include <unordered_map>
#include <map>
#include <vita2d.h>

void luaControls_init(lua_State *L);
void luaScreen_init(lua_State *L);
void luaGraphics_init(lua_State *L);
void luaSound_init(lua_State *L);
void luaSystem_init(lua_State *L);
void luaNetwork_init(lua_State *L);
void luaTimer_init(lua_State *L);
void luaKeyboard_init(lua_State *L);
void luaRender_init(lua_State *L);
void luaMic_init(lua_State *L);
void luaVideo_init(lua_State *L);
void luaDatabase_init(lua_State *L);
void luaRegistry_init(lua_State *L);
void luaGui_init(lua_State *L);


extern vita2d_pgf* debug_font;
extern int clr_color;
extern bool keyboardStarted;
extern bool messageStarted;
extern bool unsafe_mode;

struct bitmap_glyph {
    int id;
    unsigned int x, y;         // Position auf der PNG-Textur
    unsigned int width, height;// Dimensionen des Zeichens
    unsigned int xoffset;      // Versatz beim Zeichnen auf der X-Achse
    unsigned int yoffset;      // Versatz beim Zeichnen auf der Y-Achse
    unsigned int xadvance;     // Wie weit der Cursor nach diesem Zeichen springt
};

struct bitmap_font {
    uint32_t magic;
    vita2d_texture* texture;
    unsigned int line_height;
    unsigned int base_height;
    std::unordered_map<char, bitmap_glyph> glyphs;
};

// Internal structs
struct texture{
    uint32_t magic;
    vita2d_texture *text;
    void *data;
};

struct DecodedMusic{
    uint8_t* audiobuf;
    uint8_t* audiobuf2;
    uint8_t* cur_audiobuf;
    FILE* handle;
    volatile bool isPlaying;
    bool loop;
    volatile bool pauseTrigger;
    volatile bool closeTrigger;
    volatile uint8_t audioThread;
    volatile int volume;
    char filepath[256];
    char title[256];
    char author[256];
    bool tempBlock;
};

#endif //NOTTETRIS2_NOTTETRIS_H
