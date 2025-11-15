package llua;

import llua.State;
import llua.Lua;
import llua.LuaL;

@:include("linc_lua.h")
#if !display
@:build(linc.Linc.touch())
@:build(linc.Linc.xml("lua"))
#end
class CodeGen {
    public static inline var DEFAULT_OPTIMIZATION:Int = 1;
    public static inline var DEFAULT_DEBUG:Int = 2;
    public static inline var DEFAULT_TYPEINFO:Int = 0;
    public static inline var DEFAULT_COVERAGE:Int = 0;

    public static function compileToBytecode(
        source:String,
        ?optimizationLevel:Int = DEFAULT_OPTIMIZATION,
        ?debugLevel:Int = DEFAULT_DEBUG,
        ?typeInfoLevel:Int = DEFAULT_TYPEINFO,
        ?coverageLevel:Int = DEFAULT_COVERAGE
    ):Array<Int> {
        if (source == null || source.length == 0) {
            return [];
        }

        var opt = clamp(optimizationLevel, 0, 2, DEFAULT_OPTIMIZATION);
        var dbg = clamp(debugLevel, 0, 2, DEFAULT_DEBUG);
        var typeInfo = clamp(typeInfoLevel, 0, 1, DEFAULT_TYPEINFO);
        var coverage = clamp(coverageLevel, 0, 2, DEFAULT_COVERAGE);

        return compile_bytecode_native(source, opt, dbg, typeInfo, coverage);
    }

    public static function compileAndExecute(
        luaState:State,
        source:String,
        ?chunkName:String = "script"
    ):Int {
        if (luaState == null) {
            return Lua.LUA_ERRERR;
        }

        var bytecode = compileToBytecode(source);
        if (bytecode == null || bytecode.length == 0) {
            return Lua.LUA_ERRSYNTAX;
        }

        var loadStatus = loadBytecode(luaState, bytecode, chunkName);
        if (loadStatus != Lua.LUA_OK) {
            return loadStatus;
        }

        return Lua.pcall(luaState, 0, Lua.LUA_MULTRET, 0);
    }

    public static function loadBytecode(
        luaState:State,
        bytecode:Array<Int>,
        ?chunkName:String = "script"
    ):Int {
        if (luaState == null) {
            return Lua.LUA_ERRERR;
        }

        if (bytecode == null || bytecode.length == 0) {
            return Lua.LUA_ERRSYNTAX;
        }

        var buffer = bytesToString(bytecode);
        return LuaL.loadbuffer(luaState, buffer, bytecode.length, chunkName);
    }

    public static function loadSource(
        luaState:State,
        chunkName:String,
        source:String,
        ?fallbackToNative:Bool = true
    ):Int {
        if (source == null || source.length == 0) {
            return Lua.LUA_ERRSYNTAX;
        }

        var bytecode = compileToBytecode(source);
        if (bytecode != null && bytecode.length > 0) {
            var loadStatus = loadBytecode(luaState, bytecode, chunkName);
            if (loadStatus == Lua.LUA_OK || !fallbackToNative) {
                return loadStatus;
            }
        }

        return fallbackToNative ? LuaL.luau_loadsource(luaState, chunkName, source) : Lua.LUA_ERRSYNTAX;
    }

    public static function getCompilationStats():Dynamic {
        return {
            supportsCodegen: true,
            optimizationRange: [0, 1, 2],
            debugRange: [0, 1, 2],
            typeInfoRange: [0, 1],
            coverageRange: [0, 1, 2]
        };
    }

    public static function compileWithProfile(source:String, profile:String = "balanced"):Array<Int> {
        var settings = getProfileSettings(profile);
        return compileToBytecode(
            source,
            settings.optimizationLevel,
            settings.debugLevel,
            settings.typeInfoLevel,
            settings.coverageLevel
        );
    }

    public static function getProfileSettings(profile:String):Dynamic {
        var key = profile == null ? "balanced" : profile.toLowerCase();
        switch (key) {
            case "debug":
                return {
                    optimizationLevel: 0,
                    debugLevel: 2,
                    typeInfoLevel: 1,
                    coverageLevel: 1
                };
            case "release":
                return {
                    optimizationLevel: 2,
                    debugLevel: 0,
                    typeInfoLevel: 0,
                    coverageLevel: 0
                };
            case "coverage":
                return {
                    optimizationLevel: 1,
                    debugLevel: 2,
                    typeInfoLevel: 1,
                    coverageLevel: 2
                };
            default:
                return {
                    optimizationLevel: 1,
                    debugLevel: 1,
                    typeInfoLevel: 0,
                    coverageLevel: 0
                };
        }
    }

    static inline function clamp(value:Int, minValue:Int, maxValue:Int, fallback:Int):Int {
        if (value < minValue || value > maxValue) {
            return fallback;
        }
        return value;
    }

    static function bytesToString(bytes:Array<Int>):String {
        var builder = new StringBuf();
        for (byte in bytes) {
            builder.addChar(byte & 0xFF);
        }
        return builder.toString();
    }

    @:native("linc::luau::compile_bytecode")
    private static extern function compile_bytecode_native(
        source:String,
        optimizationLevel:Int,
        debugLevel:Int,
        typeInfoLevel:Int,
        coverageLevel:Int
    ):Array<Int>;
}
