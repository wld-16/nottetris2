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

#include <cstring>
#include <cstdio>
#include <cstdlib>

#include <malloc.h>
#include <vitasdk.h>
#include "include/nottetris.h"

#ifndef SYS_APP_MODE
unsigned int _newlib_heap_size_user = 192 * 1024 * 1024;
#else
unsigned int _newlib_heap_size_user = 16 * 1024 * 1024;
#endif

extern int _newlib_heap_memblock; // Newlib Heap memblock
extern unsigned _newlib_heap_size; // Newlib Heap size

static const char* errMsg;
static unsigned char* script;
bool unsafe_mode = true;
SceCommonDialogConfigParam cmnDlgCfgParam;

char errorMsg[1024];
static lua_State *L;

int main(int argc, char *argv[]) {
    // Initializing touch screens and analogs
	sceCtrlSetSamplingMode(SCE_CTRL_MODE_ANALOG_WIDE);
	sceTouchSetSamplingState(SCE_TOUCH_PORT_FRONT, SCE_TOUCH_SAMPLING_STATE_START);
	sceTouchSetSamplingState(SCE_TOUCH_PORT_BACK, SCE_TOUCH_SAMPLING_STATE_START);

	// Starting secondary modules and mounting secondary filesystems
	sceSysmoduleLoadModule(SCE_SYSMODULE_NET);
	sceSysmoduleLoadModule(SCE_SYSMODULE_HTTP);
	SceAppUtilInitParam appUtilParam;
	SceAppUtilBootParam appUtilBootParam;
	memset(&appUtilParam, 0, sizeof(SceAppUtilInitParam));
	memset(&appUtilBootParam, 0, sizeof(SceAppUtilBootParam));
	sceAppUtilInit(&appUtilParam, &appUtilBootParam);
	sceCommonDialogConfigParamInit(&cmnDlgCfgParam);
	sceAppUtilSystemParamGetInt(SCE_SYSTEM_PARAM_ID_LANG, (int *)&cmnDlgCfgParam.language);
	sceAppUtilSystemParamGetInt(SCE_SYSTEM_PARAM_ID_ENTER_BUTTON, (int *)&cmnDlgCfgParam.enterButtonAssign);
	sceCommonDialogSetConfigParam(&cmnDlgCfgParam);
	sceShellUtilInitEvents(0);

	// Check what mode lpp-vita is currently running on
	SceUID fd = sceIoOpen("os0:/psp2bootconfig.skprx", SCE_O_RDONLY, 0777);
	if (fd < 0) unsafe_mode = false;
	else sceIoClose(fd);

	// Debug FTP stuffs
	char vita_ip[16];
	unsigned short int vita_port = 0;

	// Initializing graphics device
	vita2d_init_advanced(0x800000);
	vita2d_set_clear_color(RGBA8(0x00, 0x00, 0x00, 0xFF));
	vita2d_set_vblank_wait(0);
	debug_font = vita2d_load_default_pgf();
	clr_color = 0x000000FF;

	// Getting newlib heap memblock starting address
	void *addr = NULL;
	sceKernelGetMemBlockBase(_newlib_heap_memblock, &addr);

	// Mapping newlib heap into sceGxm
	sceGxmMapMemory(addr, _newlib_heap_size, static_cast<SceGxmMemoryAttribFlags>(SCE_GXM_MEMORY_ATTRIB_READ | SCE_GXM_MEMORY_ATTRIB_WRITE));


	SceCtrlData pad;
	SceCtrlData oldpad;
	int errored = 0;
	while (1) {

		// Load main script
		SceUID main_file = sceIoOpen("app0:/index.lua", SCE_O_RDONLY, 0777);

		if (main_file < 0) {
			errored = 1;
			strcpy(errorMsg, "Invalid main script.");
		} else {
			SceOff size = sceIoLseek(main_file, 0, SEEK_END);
			if (size < 1) {
				errored = 1;
				strcpy(errorMsg, "Invalid main script.");
			} else {
				sceIoLseek(main_file, 0, SEEK_SET);
				script = (unsigned char*)malloc(size + 1);
				sceIoRead(main_file, script, size);
				script[size] = 0;
				sceIoClose(main_file);
				L = luaL_newstate();

				// Standard libraries
				luaL_openlibs(L);

				// Modules
				luaControls_init(L);
				luaScreen_init(L);
				luaGraphics_init(L);
				luaSound_init(L);
				luaTimer_init(L);
				luaSystem_init(L);


				errored = luaL_dostring(L, reinterpret_cast<const char*>(script));

				if (errored) {
					strcpy(errorMsg, (char *)lua_tostring(L, -1));
				}

				lua_close(L);
				free(script);
			}
		}

		if (errored) {
			int restore = 0;
			bool s = true;
			while (restore == 0) {
				vita2d_start_drawing();
				vita2d_clear_screen();
				vita2d_pgf_draw_textf(debug_font, 2, 19.402, RGBA8(255, 255, 255, 255), 1.0, "An error occurred:\n%s\n\nPress X to restart.\n", errorMsg);
				vita2d_end_drawing();
				vita2d_swap_buffers();
				sceDisplayWaitVblankStart();
				if (s) {
					sceKernelDelayThread(800000);
					s = false;
				}
				sceCtrlPeekBufferPositive(0, &pad, 1);
				oldpad = pad;
			}
		}
	}

	sceAppUtilShutdown();
	vita2d_fini();
	sceSysmoduleUnloadModule(SCE_SYSMODULE_NET);
	sceSysmoduleUnloadModule(SCE_SYSMODULE_HTTP);
	sceKernelExitProcess(0);
	return 0;
}