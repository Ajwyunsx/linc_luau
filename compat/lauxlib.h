#pragma once
#include "../lib/luau/VM/include/lualib.h"

#ifdef __cplusplus
extern "C" {
#endif

int luaL_dofile(lua_State* L, const char* filename);
int luaL_dostring(lua_State* L, const char* s);

#ifdef __cplusplus
}
#endif