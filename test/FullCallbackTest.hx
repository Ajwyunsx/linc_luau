import cpp.Callable;
import llua.Convert;
import llua.Lua;
import llua.LuaL;
import llua.LuaCallback;
import llua.State;
import haxe.ds.StringMap;
import Reflect;
import haxe.Log;

class FullCallbackTest {

    private static var callbackMap = new StringMap<Dynamic>();

    // 测试用的Haxe函数，会被Lua调用
    private static function testCallback(args:Array<Dynamic>):Dynamic {
        trace('[HAXE] testCallback called with ' + args.length + ' args: ' + args);
        return 'callback result: ' + (args.length > 0 ? args[0] : 'no args');
    }

    // 数学运算回调
    private static function mathCallback(args:Array<Dynamic>):Dynamic {
        if (args.length >= 2) {
            var a:Float = cast args[0];
            var b:Float = cast args[1];
            trace('[HAXE] mathCallback: ' + a + ' + ' + b + ' = ' + (a + b));
            return a + b;
        }
        return 0;
    }

    public static function main():Void {
        trace('=== 开始Lua回调功能测试 ===');
        
        // 创建Lua状态
        var vm:State = LuaL.newstate();
        LuaL.openlibs(vm);
        
        #if cpp
        LuaL.sandbox(vm);
        LuaL.sandboxthread(vm);
        #end

        // 注册回调处理函数
        Lua.set_callbacks_function(Callable.fromStaticFunction(handleCallback));

        // 注册多个回调函数
        callbackMap.set('testCallback', testCallback);
        callbackMap.set('mathCallback', mathCallback);
        Lua.add_callback_function(vm, 'testCallback');
        Lua.add_callback_function(vm, 'mathCallback');

        trace('注册回调函数完成');

        // 测试1: 基本回调调用
        trace('\n--- 测试1: 基本回调调用 ---');
        testBasicCallback(vm);

        // 测试2: 复杂参数传递
        trace('\n--- 测试2: 复杂参数传递 ---');
        testComplexCallback(vm);

        // 测试3: Lua调用Haxe函数
        trace('\n--- 测试3: Lua调用Haxe函数 ---');
        testLuaToHaxe(vm);

        // 可选测试4: 获取Lua函数作为回调（当前禁用）

        // 清理
        Lua.close(vm);
        trace('\n=== 测试完成 ===');
    }

    private static function handleCallback(l:State, funcName:String):Int {
        var cb = callbackMap.get(funcName);
        if (cb == null) {
            trace('[ERROR] Callback function not found: ' + funcName);
            return 0;
        }

        // 获取参数
        var args:Array<Dynamic> = [];
        var nparams = Lua.gettop(l);
        trace('[HANDLER] ' + funcName + ' called with ' + nparams + ' params');
        
        for (i in 0...nparams) {
            var arg = Convert.fromLua(l, i + 1);
            args.push(arg);
            trace('  param ' + i + ': ' + arg + ' (' + Type.typeof(arg) + ')');
        }

        // 调用Haxe函数
        var result:Dynamic = null;
        try {
            result = Reflect.callMethod(null, cb, [args]);
        } catch (e:Dynamic) {
            trace('[ERROR] Callback execution failed: ' + e);
            Lua.pushstring(l, 'Error: ' + e);
            return 1;
        }

        // 返回结果
        if (result != null) {
            Convert.toLua(l, result);
            trace('[HANDLER] ' + funcName + ' returned: ' + result + ' (' + Type.typeof(result) + ')');
            return 1;
        }
        
        return 0;
    }

    private static function testBasicCallback(vm:State):Void {
        var script = '
            print("Lua: 调用testCallback");
            local result = testCallback("hello", 42);
            print("Lua: 收到结果 = " .. tostring(result));
            return result;
        ';
        
        if (LuaL.luau_loadsource(vm, 'basic_test', script) != 0) {
            trace('[ERROR] 加载脚本失败');
            return;
        }
        
        if (Lua.pcall(vm, 0, 1, 0) != Lua.LUA_OK) {
            trace('[ERROR] 执行脚本失败: ' + Lua.tostring(vm, -1));
            return;
        }
        
        var result = Convert.fromLua(vm, -1);
        trace('[TEST1] 最终结果: ' + result);
        Lua.pop(vm, 1);
    }

    private static function testComplexCallback(vm:State):Void {
        var script = '
            print("Lua: 测试复杂参数");
            local table = {name="test", value=100};
            local array = {1, 2, 3, "four"};
            local result = testCallback(table, array, "mixed");
            print("Lua: 复杂回调结果 = " .. tostring(result));
            return result;
        ';
        
        if (LuaL.luau_loadsource(vm, 'complex_test', script) != 0) {
            trace('[ERROR] 加载复杂测试脚本失败');
            return;
        }
        
        if (Lua.pcall(vm, 0, 1, 0) != Lua.LUA_OK) {
            trace('[ERROR] 执行复杂测试失败: ' + Lua.tostring(vm, -1));
            return;
        }
        
        var result = Convert.fromLua(vm, -1);
        trace('[TEST2] 复杂回调结果: ' + result);
        Lua.pop(vm, 1);
    }

    private static function testLuaToHaxe(vm:State):Void {
        // 直接调用Lua函数
        Lua.getglobal(vm, 'mathCallback');
        Lua.pushnumber(vm, 15);
        Lua.pushnumber(vm, 25);
        
        if (Lua.pcall(vm, 2, 1, 0) != Lua.LUA_OK) {
            trace('[ERROR] 调用Lua函数失败: ' + Lua.tostring(vm, -1));
            return;
        }
        
        var result = Convert.fromLua(vm, -1);
        trace('[TEST3] Lua函数调用结果: ' + result);
        Lua.pop(vm, 1);
    }

    private static function testLuaFunctionAsCallback(vm:State):Void {
        // 创建一个Lua函数并获取为Haxe回调
        var script = '
            return function(x, y)
                print("Lua函数: 计算 " .. x .. " * " .. y);
                return x * y;
            end
        ';
        
        if (LuaL.luau_loadsource(vm, 'closure_test', script) != 0) {
            trace('[ERROR] 加载闭包测试脚本失败');
            return;
        }
        
        if (Lua.pcall(vm, 0, 1, 0) != Lua.LUA_OK) {
            trace('[ERROR] 执行闭包测试失败: ' + Lua.tostring(vm, -1));
            return;
        }
        
        Lua.pushvalue(vm, -1);
        var ref = LuaL.ref(vm, Lua.LUA_REGISTRYINDEX);
        var cb = new LuaCallback(vm, ref);
        var callResult = cb.call([6, 7]);
        trace('[TEST4] Lua回调调用结果: ' + callResult);
        cb.dispose();
        
        Lua.pop(vm, 1);
    }
}
