#pragma once

#include <hxcpp.h>
#include <hx/CFFI.h>

#include <sstream>
#include <iostream>

#include "../lib/luau/VM/include/lua.h"
#include "../lib/luau/VM/include/lualib.h"

#include "../lib/luau/Compiler/include/luacode.h"

namespace linc {

    typedef ::cpp::Function < int(::cpp::Reference<lua_State>, ::String) > luaCallbackFN;
    // typedef ::cpp::Function < int(::cpp::Pointer<lua_State>, ::String) > luaCallbackFN;
    typedef ::cpp::Function < int(String) > HxTraceFN;

    namespace lua {

        extern ::String version();
        extern ::String tostring(lua_State *l, int v);
        extern ::String tolstring(lua_State *l, int v, size_t *len);
        extern ::String _typename(lua_State *l, int tp);

        extern int getstack(lua_State *L, int level, Dynamic ar);
        extern int getinfo(lua_State *L, const char *what, Dynamic ar);

        extern ::cpp::Function<int(lua_State*)> tocfunction(lua_State* l, int i);
        extern void pushcclosure(lua_State* l, ::cpp::Function<int(lua_State*)> fn, int n);
        extern void pushcfunction(lua_State* l, ::cpp::Function<int(lua_State*)> fn);

    } // lua

    namespace luau {

        extern int load_source(lua_State* L, const char* chunkname, const char* source);
        extern ::Array< int > compile_bytecode(const char* source, int optimizationLevel, int debugLevel, int typeInfoLevel, int coverageLevel);

    }

    namespace lual {

        extern ::String checklstring(lua_State *l, int numArg, size_t *len);
        extern ::String optlstring(lua_State *L, int numArg, const char *def, size_t *l);
        extern ::String prepbuffer(luaL_Buffer *B);
        extern ::String gsub(lua_State *l, const char *s, const char *p, const char *r);
        extern ::String findtable(lua_State *L, int idx, const char *fname, int szhint);
        extern ::String checkstring(lua_State *L, int n);
        extern ::String optstring(lua_State *L, int n, const char *d);
        extern ::String ltypename(lua_State *L, int idx);
        extern void error(lua_State *L, const char* fmt);

    }

    namespace helpers {

        extern int setErrorHandler(lua_State *L);
        extern void register_hxtrace_func(HxTraceFN fn);
        extern void register_hxtrace_lib(lua_State* L);

    }

    namespace callbacks {

        extern void set_callbacks_function(luaCallbackFN fn);
        extern void add_callback_function(lua_State *L, const char *name);
        extern void remove_callback_function(lua_State *L, const char *name);

    }


} //linc

extern "C" int luaL_ref(lua_State* L, int t);
extern "C" void luaL_unref(lua_State* L, int t, int ref);
extern "C" int luaL_loadbuffer(lua_State* L, const char* s, size_t sz, const char* chunkname);
