package llua;

import llua.State;
import llua.Lua;
import llua.LuaL;
import llua.Convert;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class LuaRequire {
    private static var loadedModules:Map<State, Map<String, Bool>> = new Map();
    private static var searchPaths:Map<State, Array<String>> = new Map();
    
    public static function init(l:State, ?basePaths:Array<String>):Void {
        if (!loadedModules.exists(l)) {
            loadedModules.set(l, new Map<String, Bool>());
        }
        
        if (basePaths != null) {
            searchPaths.set(l, basePaths);
        } else {
            searchPaths.set(l, ['./', 'mods/', 'scripts/']); // wtf fnf???
        }
        
        Lua.newtable(l);
        Lua.setglobal(l, 'package');
        
        Lua.getglobal(l, 'package');
        Lua.newtable(l);
        Lua.setfield(l, -2, 'loaded');
        Lua.pop(l, 1);
        
        #if cpp
        Lua.pushcclosure(l, _requireCallback, 0);
        Lua.setglobal(l, 'require');
        #end
    }
    
    #if cpp
    static var _requireCallback = cpp.Callable.fromStaticFunction(requireCallback);
    
    static function requireCallback(lptr:cpp.RawPointer<Lua_State>):Int {
        var l:State = cast cpp.Pointer.fromRaw(lptr).ref;
        
        if (Lua.gettop(l) < 1) {
            Lua.pushstring(l, 'require expects 1 argument');
            Lua.error(l);
            return 0;
        }
        
        var modname = Lua.tostring(l, 1);
        return requireModuleDirect(l, modname);
    }
    #end
    
    private static function resolveModulePath(l:State, modname:String):String {
        #if sys
        var path = modname.replace('.', '/');
        
        var paths = searchPaths.get(l);
        if (paths == null) paths = ['./'];
        
        var extensions = ['.lua', '.luau', '/init.lua'];
        
        for (searchPath in paths) {
            for (ext in extensions) {
                var fullPath = searchPath + path + ext;
                if (FileSystem.exists(fullPath)) {
                    return fullPath;
                }
            }
        }
        
        for (ext in extensions) {
            var fullPath = path + ext;
            if (FileSystem.exists(fullPath)) {
                return fullPath;
            }
        }
        #end
        
        return null;
    }
    
    private static function requireModuleDirect(l:State, modname:String):Int {
        // Check for built-in modules
        var builtinLoader = switch(modname) {
            case 'math': loadBuiltinMath;
            case 'string': loadBuiltinString;
            case 'table': loadBuiltinTable;
            case 'os': loadBuiltinOS;
            case 'io': loadBuiltinIO;
            default: null;
        };
        
        if (builtinLoader != null) {
            return builtinLoader(l);
        }
        
        Lua.getglobal(l, 'package');
        Lua.getfield(l, -1, 'loaded');
        Lua.getfield(l, -1, modname);
        
        if (Lua.type(l, -1) != Lua.LUA_TNIL) {
            Lua.remove(l, -2);
            Lua.remove(l, -2);
            return 1;
        }
        Lua.pop(l, 3);
        
        var path = resolveModulePath(l, modname);
        if (path == null) {
            Lua.pushstring(l, 'module $modname not found');
            Lua.error(l);
            return 0;
        }
        
        #if sys
        var code = File.getContent(path);
        var status = LuaL.luau_loadsource(l, modname, code);
        
        if (status != Lua.LUA_OK) {
            Lua.error(l);
            return 0;
        }
        
        var execStatus = Lua.pcall(l, 0, 1, 0);
        if (execStatus != Lua.LUA_OK) {
            Lua.error(l);
            return 0;
        }
        
        var topType = Lua.type(l, -1);
        if (topType == Lua.LUA_TNIL || topType == Lua.LUA_TNONE) {
            if (topType == Lua.LUA_TNIL) Lua.pop(l, 1);
            Lua.pushboolean(l, true);
        }
        
        Lua.pushvalue(l, -1);
        Lua.getglobal(l, 'package');
        Lua.getfield(l, -1, 'loaded');
        Lua.pushvalue(l, -3);
        Lua.setfield(l, -2, modname);
        Lua.pop(l, 2);
        
        return 1;
        #else
        Lua.pushstring(l, 'require not available (no file system)');
        Lua.error(l);
        return 0;
        #end
    }
    
    private static function loadBuiltinMath(l:State):Int {
        Lua.getglobal(l, 'package');
        Lua.getfield(l, -1, 'loaded');
        Lua.getfield(l, -1, 'math');
        
        if (Lua.type(l, -1) != Lua.LUA_TNIL) {
            Lua.remove(l, -2);
            Lua.remove(l, -2);
            return 1;
        }
        Lua.pop(l, 3);
        
        Lua.newtable(l);
        
        var mathFuncs = [
            {name: 'abs', code: 'function(x) if x < 0 then return -x else return x end end'},
            {name: 'max', code: 'function(a, b) if a > b then return a else return b end end'},
            {name: 'min', code: 'function(a, b) if a < b then return a else return b end end'},
            {name: 'floor', code: 'function(x) return x - (x % 1) end'},
            {name: 'ceil', code: 'function(x) local f = x - (x % 1); if f == x then return x else return f + 1 end end'},
            {name: 'sqrt', code: 'function(x) return x ^ 0.5 end'},
        ];
        
        for (func in mathFuncs) {
            var fullCode = 'return ' + func.code;
            if (LuaL.luau_loadsource(l, 'math.' + func.name, fullCode) == Lua.LUA_OK) {
                if (Lua.pcall(l, 0, 1, 0) == Lua.LUA_OK) {
                    Lua.setfield(l, -2, func.name);
                } else {
                    Lua.pop(l, 1);
                }
            }
        }
        
        Lua.pushnumber(l, 3.14159265358979323846);
        Lua.setfield(l, -2, 'pi');
        Lua.pushnumber(l, 999999999);
        Lua.setfield(l, -2, 'huge');
        
        Lua.pushvalue(l, -1);
        Lua.getglobal(l, 'package');
        Lua.getfield(l, -1, 'loaded');
        Lua.pushvalue(l, -3);
        Lua.setfield(l, -2, 'math');
        Lua.pop(l, 2);
        
        return 1;
    }
    
    private static function loadBuiltinString(l:State):Int {
        Lua.getglobal(l, 'package');
        Lua.getfield(l, -1, 'loaded');
        Lua.getfield(l, -1, 'string');
        
        if (Lua.type(l, -1) != Lua.LUA_TNIL) {
            Lua.remove(l, -2);
            Lua.remove(l, -2);
            return 1;
        }
        Lua.pop(l, 3);
        
        Lua.newtable(l);
        
        var stringFuncs = [
            {name: 'upper', code: 'function(s) local r = ""; for i = 1, #s do local c = s:byte(i); if c >= 97 and c <= 122 then r = r .. string.char(c - 32) else r = r .. string.char(c) end end return r end'},
            {name: 'lower', code: 'function(s) local r = ""; for i = 1, #s do local c = s:byte(i); if c >= 65 and c <= 90 then r = r .. string.char(c + 32) else r = r .. string.char(c) end end return r end'},
            {name: 'len', code: 'function(s) return #s end'},
            {name: 'sub', code: 'function(s, i, j) j = j or #s; return s:sub(i, j) end'},
            {name: 'find', code: 'function(s, pattern, init, plain) init = init or 1; local idx = s:find(pattern, init, plain); return idx end'},
            {name: 'format', code: 'function(fmt, ...) return fmt end'},
            {name: 'rep', code: 'function(s, n) local r = ""; for i = 1, n do r = r .. s end return r end'},
        ];
        
        for (func in stringFuncs) {
            var fullCode = 'return ' + func.code;
            if (LuaL.luau_loadsource(l, 'string.' + func.name, fullCode) == Lua.LUA_OK) {
                if (Lua.pcall(l, 0, 1, 0) == Lua.LUA_OK) {
                    Lua.setfield(l, -2, func.name);
                } else {
                    Lua.pop(l, 1);
                }
            }
        }
        
        Lua.pushvalue(l, -1);
        Lua.getglobal(l, 'package');
        Lua.getfield(l, -1, 'loaded');
        Lua.pushvalue(l, -3);
        Lua.setfield(l, -2, 'string');
        Lua.pop(l, 2);
        
        return 1;
    }
    
    private static function loadBuiltinTable(l:State):Int {
        Lua.getglobal(l, 'package');
        Lua.getfield(l, -1, 'loaded');
        Lua.getfield(l, -1, 'table');
        
        if (Lua.type(l, -1) != Lua.LUA_TNIL) {
            Lua.remove(l, -2);
            Lua.remove(l, -2);
            return 1;
        }
        Lua.pop(l, 3);
        
        Lua.newtable(l);
        
        var tableFuncs = [
            {name: 'insert', code: 'function(t, pos, value) if value == nil then value = pos; pos = #t + 1 end table.insert(t, pos, value) end'},
            {name: 'remove', code: 'function(t, pos) pos = pos or #t; return table.remove(t, pos) end'},
            {name: 'concat', code: 'function(t, sep, i, j) sep = sep or ""; i = i or 1; j = j or #t; local r = ""; for k = i, j do if k > i then r = r .. sep end r = r .. tostring(t[k]) end return r end'},
            {name: 'sort', code: 'function(t, comp) table.sort(t, comp) end'},
        ];
        
        for (func in tableFuncs) {
            var fullCode = 'return ' + func.code;
            if (LuaL.luau_loadsource(l, 'table.' + func.name, fullCode) == Lua.LUA_OK) {
                if (Lua.pcall(l, 0, 1, 0) == Lua.LUA_OK) {
                    Lua.setfield(l, -2, func.name);
                } else {
                    Lua.pop(l, 1);
                }
            }
        }
        
        Lua.pushvalue(l, -1);
        Lua.getglobal(l, 'package');
        Lua.getfield(l, -1, 'loaded');
        Lua.pushvalue(l, -3);
        Lua.setfield(l, -2, 'table');
        Lua.pop(l, 2);
        
        return 1;
    }
    
    private static function loadBuiltinOS(l:State):Int {
        Lua.getglobal(l, 'package');
        Lua.getfield(l, -1, 'loaded');
        Lua.getfield(l, -1, 'os');
        
        if (Lua.type(l, -1) != Lua.LUA_TNIL) {
            Lua.remove(l, -2);
            Lua.remove(l, -2);
            return 1;
        }
        Lua.pop(l, 3);
        
        Lua.newtable(l);
        
        var osFuncs = [
            {name: 'time', code: 'function(t) return 0 end'},
            {name: 'date', code: 'function(fmt, time) return "" end'},
            {name: 'clock', code: 'function() return 0 end'},
        ];
        
        for (func in osFuncs) {
            var fullCode = 'return ' + func.code;
            if (LuaL.luau_loadsource(l, 'os.' + func.name, fullCode) == Lua.LUA_OK) {
                if (Lua.pcall(l, 0, 1, 0) == Lua.LUA_OK) {
                    Lua.setfield(l, -2, func.name);
                } else {
                    Lua.pop(l, 1);
                }
            }
        }
        
        Lua.pushvalue(l, -1);
        Lua.getglobal(l, 'package');
        Lua.getfield(l, -1, 'loaded');
        Lua.pushvalue(l, -3);
        Lua.setfield(l, -2, 'os');
        Lua.pop(l, 2);
        
        return 1;
    }
    
    private static function loadBuiltinIO(l:State):Int {
        Lua.getglobal(l, 'package');
        Lua.getfield(l, -1, 'loaded');
        Lua.getfield(l, -1, 'io');
        
        if (Lua.type(l, -1) != Lua.LUA_TNIL) {
            Lua.remove(l, -2);
            Lua.remove(l, -2);
            return 1;
        }
        Lua.pop(l, 3);
        
        Lua.newtable(l);
        
        var ioFuncs = [
            {name: 'write', code: 'function(...) local args = {...}; for i, v in ipairs(args) do print(tostring(v)) end end'},
            {name: 'read', code: 'function() return "" end'},
        ];
        
        for (func in ioFuncs) {
            var fullCode = 'return ' + func.code;
            if (LuaL.luau_loadsource(l, 'io.' + func.name, fullCode) == Lua.LUA_OK) {
                if (Lua.pcall(l, 0, 1, 0) == Lua.LUA_OK) {
                    Lua.setfield(l, -2, func.name);
                } else {
                    Lua.pop(l, 1);
                }
            }
        }
        
        Lua.pushvalue(l, -1);
        Lua.getglobal(l, 'package');
        Lua.getfield(l, -1, 'loaded');
        Lua.pushvalue(l, -3);
        Lua.setfield(l, -2, 'io');
        Lua.pop(l, 2);
        
        return 1;
    }
    
    public static function addPath(l:State, path:String):Void {
        var paths = searchPaths.get(l);
        if (paths == null) {
            paths = [];
            searchPaths.set(l, paths);
        }
        
        if (!path.endsWith('/') && !path.endsWith('\\')) path += '/';
        if (!paths.contains(path)) {
            paths.push(path);
        }
    }
    
    public static function clearCache(l:State, ?modname:String):Void {
        if (modname == null) {
            Lua.getglobal(l, 'package');
            Lua.getfield(l, -1, 'loaded');
            Lua.pushnil(l);
            
            while (Lua.next(l, -2) != 0) {
                Lua.pop(l, 1);
                Lua.pushnil(l);
                Lua.settable(l, -3);
            }
            
            Lua.pop(l, 2);
        } else {
            Lua.getglobal(l, 'package');
            Lua.getfield(l, -1, 'loaded');
            Lua.pushnil(l);
            Lua.setfield(l, -2, modname);
            Lua.pop(l, 2);
        }
    }
}
