#include "hxcpp.h"
#include <hx/CFFI.h>

#include "./linc_lua.h"
#include "../lib/luau/VM/include/lua.h"
#include "../lib/luau/VM/include/lualib.h"
#include "../lib/luau/Compiler/include/luacode.h"
#include <fstream>

namespace linc {

    namespace lua {

        ::String version(){
            return ::String("Luau");
        }

        

        ::String tostring(lua_State *l, int v){

            return ::String(lua_tostring(l, v));

        }

        ::String tolstring(lua_State *l, int v, size_t *len){

            return ::String(lua_tolstring(l, v, len));

        }

        ::cpp::Function<int(lua_State*)> tocfunction(lua_State* l, int i) {
            return (::cpp::Function<int(lua_State*)>) lua_tocfunction(l, i);
        }

        void pushcclosure(lua_State* l, ::cpp::Function<int(lua_State*)> fn, int n) {
            lua_pushcclosure(l, (lua_CFunction)fn, "hx_closure", n);
        }

        void pushcfunction(lua_State* l, ::cpp::Function<int(lua_State*)> fn) {
            lua_pushcfunction(l, (lua_CFunction)fn, "hx_func");
        }

        ::String _typename(lua_State *l, int v){

            return ::String(lua_typename(l, v));

        }

        int getstack(lua_State *L, int level, Dynamic ar){
            return 0;
        }

        int getinfo(lua_State *L, const char *what, Dynamic ar){
            return 0;
        }

    } //lua

    namespace luau {

        int load_source(lua_State* L, const char* chunkname, const char* source) {
            size_t bytecodeSize = 0;
            lua_CompileOptions opts = {0};
            opts.optimizationLevel = 1;
            opts.debugLevel = 2;
            opts.typeInfoLevel = 0;
            opts.coverageLevel = 0;
            char* bytecode = luau_compile(source, (size_t)strlen(source), &opts, &bytecodeSize);
            if (!bytecode) {
                return LUA_ERRMEM;
            }

            int result = luau_load(L, chunkname, bytecode, bytecodeSize, 0);
            free(bytecode);
            return result;
        }

    } //luau

    extern "C" int luaL_dostring(lua_State* L, const char* s) {
        size_t bytecodeSize = 0;
        lua_CompileOptions opts = {0};
        opts.optimizationLevel = 1;
        opts.debugLevel = 2;
        char* bytecode = luau_compile(s, (size_t)strlen(s), &opts, &bytecodeSize);
        if (!bytecode) return LUA_ERRMEM;
        int r = luau_load(L, "chunk", bytecode, bytecodeSize, 0);
        free(bytecode);
        if (r != 0) return r;
        return lua_pcall(L, 0, LUA_MULTRET, 0);
    }

    extern "C" int luaL_dofile(lua_State* L, const char* filename) {
        std::ifstream ifs(filename, std::ios::binary);
        if (!ifs) { lua_pushfstring(L, "cannot open %s", filename); return LUA_ERRERR; }
        std::string src((std::istreambuf_iterator<char>(ifs)), std::istreambuf_iterator<char>());
        size_t bytecodeSize = 0;
        lua_CompileOptions opts = {0};
        opts.optimizationLevel = 1;
        opts.debugLevel = 2;
        char* bytecode = luau_compile(src.c_str(), (size_t)src.size(), &opts, &bytecodeSize);
        if (!bytecode) { lua_pushstring(L, "compile error"); return LUA_ERRSYNTAX; }
        int r = luau_load(L, filename, bytecode, bytecodeSize, 0);
        free(bytecode);
        if (r != 0) return r;
        return lua_pcall(L, 0, LUA_MULTRET, 0);
    }

    namespace lual {

        ::String checklstring(lua_State *l, int numArg, size_t *len){

            return ::String(luaL_checklstring(l, numArg, len));

        }

        ::String optlstring(lua_State *l, int numArg, const char *def, size_t *len){

            return ::String(luaL_optlstring(l, numArg, def, len));

        }

        ::String prepbuffer(luaL_Buffer *B){
            return ::String(luaL_prepbuffsize(B, 1));
        }

        ::String gsub(lua_State *l, const char *s, const char *p, const char *r){
            return ::String(s);
        }

        ::String findtable(lua_State *L, int idx, const char *fname, int szhint){

            return ::String(luaL_findtable(L, idx, fname, szhint));

        }

        ::String checkstring(lua_State *L, int n){

            return ::String(luaL_checkstring(L, n));

        }

        ::String optstring(lua_State *L, int n, const char *d){

            return ::String(luaL_optstring(L, n, d));

        }

        void error(lua_State *L, const char* fmt) {
            luaL_error(L,fmt,"");
        }

        ::String ltypename(lua_State *L, int idx){

            return ::String(luaL_typename(L, idx));

        }

    } //lual

    namespace helpers {

        static int onError(lua_State *L) {

            // Dummy implementation
            return 0;

        }

        int setErrorHandler(lua_State *L){

            // Dummy implementation
            return 0;

        }

        // haxe trace function

        static HxTraceFN print_fn = 0;
        static int hx_trace(lua_State* L) {

            // Dummy implementation
            return 0;

        }

        static const struct luaL_Reg printlib [] = {

            {NULL, NULL} /* end of array */

        };

        void register_hxtrace_func(HxTraceFN fn){

            // Dummy implementation

        }

        void register_hxtrace_lib(lua_State* L){

            // Dummy implementation

        }

    } //helpers

    namespace callbacks {

        static luaCallbackFN event_fn = 0;
        static int luaCallback(lua_State *L){

            return event_fn(L, ::String(lua_tostring(L, lua_upvalueindex(1))));

        }

        void set_callbacks_function(luaCallbackFN fn){

            event_fn = fn;

        }

        void add_callback_function(lua_State *L, const char *name) {

            lua_pushstring(L, name);
            lua_pushcclosure(L, luaCallback, "callback", 1);
            lua_setglobal(L, name);

        }

        void remove_callback_function(lua_State *L, const char *name){

            lua_pushnil(L);
            lua_setglobal(L, name);

        }

    } //callbacks


} //linc
