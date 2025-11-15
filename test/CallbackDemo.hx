import cpp.Callable;
import llua.Convert;
import llua.Lua;
import llua.LuaL;
import llua.LuaCallback;
import llua.State;
import haxe.ds.StringMap;
import Reflect;

class CallbackDemo {

    private static var callbacks = new StringMap<Dynamic>();

    private static function haxeCallback(a:Dynamic, b:Dynamic, c:Dynamic):Dynamic {
        trace('Haxe callback triggered with args: ' + a + ', ' + b + ', ' + c);
        return 'got 3 args: ' + a + ', ' + b + ', ' + c;
    }

    private static function callbackHandler(l:State, fname:String):Int {
        trace('callbackHandler called for: ' + fname);
        var cb = callbacks.get(fname);
        if (cb == null) {
            trace('callback not found: ' + fname);
            return 0;
        }

        var args:Array<Dynamic> = [];
        var nparams = Lua.gettop(l);
        trace('nparams: ' + nparams);
        for (i in 0...nparams) args.push(Convert.fromLua(l, i + 1));

        trace('calling callback with args: ' + args);
        var result:Dynamic = Reflect.callMethod(null, cb, args);
        trace('callback returned: ' + result);
        if (result != null) {
            Convert.toLua(l, result);
            return 1;
        }
        return 0;
    }

    private static function registerCallback(l:State, name:String, f:Dynamic):Void {
        callbacks.set(name, f);
        Lua.add_callback_function(l, name);
    }

    private static function unregisterCallback(l:State, name:String):Void {
        callbacks.remove(name);
        Lua.remove_callback_function(l, name);
    }

    public static function main():Void {
        var vm:State = LuaL.newstate();
        LuaL.openlibs(vm);

        Lua.init_callbacks(vm);
        trace('callback demo starting...');

        llua.Lua.Lua_helper.add_callback(vm, 'haxeCallback', haxeCallback);

        var script:String =
            'local M = {}\n'
            + 'function M.testFunc(a, b, c)\n'
            + '    return "Got args: " .. tostring(a) .. ", " .. tostring(b) .. ", " .. tostring(c);\n'
            + 'end\n'
            + 'function M.callHaxe(a, b, c)\n'
            + '    local response = haxeCallback(a, b, c);\n'
            + '    print("Lua got:", response);\n'
            + '    return response;\n'
            + 'end\n'
            + 'function M.simpleSum(a, b)\n'
            + '    return "sum", a + b;\n'
            + 'end\n'
            + 'function M.closure(factor)\n'
            + '    return function(value)\n'
            + '        return value * factor;\n'
            + '    end;\n'
            + 'end\n'
            + 'return M';

        if (LuaL.luau_loadsource(vm, 'callback_demo', script) != 0) {
            trace('failed to compile: ' + Lua.tostring(vm, -1));
            Lua.close(vm);
            return;
        }

        if (Lua.pcall(vm, 0, 1, 0) != Lua.LUA_OK) {
            trace('script execution failed: ' + Lua.tostring(vm, -1));
            Lua.close(vm);
            return;
        }

        Lua.setglobal(vm, 'callbackDemo');

        trace('calling testFunc (no callback)...');
        Lua.getglobal(vm, 'callbackDemo');
        Lua.getfield(vm, -1, 'testFunc');
        Lua.remove(vm, -2);
        Lua.pushstring(vm, 'first');
        Lua.pushnumber(vm, 2);
        Lua.pushnumber(vm, 3);
        var status = Lua.pcall(vm, 3, 1, 0);
        if (status != Lua.LUA_OK) {
            trace('testFunc pcall failed: ' + Lua.tostring(vm, -1));
            Lua.pop(vm, 1);
        } else {
            var result = Convert.fromLua(vm, -1);
            Lua.pop(vm, 1);
            trace('testFunc returned: ' + result);
        }

        trace('calling Lua -> Haxe callback...');
        Lua.getglobal(vm, 'callbackDemo');
        Lua.getfield(vm, -1, 'callHaxe');
        Lua.remove(vm, -2);
        Lua.pushstring(vm, 'first');
        Lua.pushnumber(vm, 2);
        Lua.pushnumber(vm, 3);
        status = Lua.pcall(vm, 3, 1, 0);
        trace('pcall returned: ' + status);
        if (status != Lua.LUA_OK) {
            trace('pcall failed: ' + Lua.tostring(vm, -1));
            Lua.pop(vm, 1);
        } else {
            var cbResult = Convert.fromLua(vm, -1);
            Lua.pop(vm, 1);
            trace('callHaxe returned: ' + cbResult);
        }

        trace('calling Lua simpleSum...');
        Lua.getglobal(vm, 'callbackDemo');
        Lua.getfield(vm, -1, 'simpleSum');
        Lua.remove(vm, -2);
        Convert.toLua(vm, 4);
        Convert.toLua(vm, 5);
        Lua.pcall(vm, 2, 2, 0); // simpleSum 返回两个值
        var sumLabel = Convert.fromLua(vm, -2);
        var sumValue = Convert.fromLua(vm, -1);
        Lua.pop(vm, 2);
        trace('simpleSum returns: ' + sumLabel + ', ' + sumValue);

        trace('grabbing Lua closure as LuaCallback...');
        Lua.getglobal(vm, 'callbackDemo');
        Lua.getfield(vm, -1, 'closure');
        Lua.remove(vm, -2);
        Lua.pushnumber(vm, 10);
        status = Lua.pcall(vm, 1, 1, 0);
        if (status != Lua.LUA_OK) {
            trace('closure pcall failed: ' + Lua.tostring(vm, -1));
            Lua.pop(vm, 1);
        } else {
            if (Lua.isfunction(vm, -1)) {
                // 使用底层修复后的 Convert.fromLua 自动处理 Luau 兼容性
                var closure:LuaCallback = Convert.fromLua(vm, -1);
                Lua.pop(vm, 1);
                
                if (closure != null) {
                    trace('Got LuaCallback, calling it with argument 7...');
                    var result = closure.call([7]);
                    trace('closure(7) = ' + result);
                    closure.dispose();
                } else {
                    trace('Failed to convert closure to LuaCallback');
                }
            } else {
                trace('Not a function');
                Lua.pop(vm, 1);
            }
        }

        llua.Lua.Lua_helper.remove_callback(vm, 'haxeCallback');
        Lua.close(vm);
        trace('Demo completed successfully!');
    }
}
