import llua.Convert;
import llua.Lua;
import llua.LuaL;
import llua.LuaCallback;
import llua.State;
import haxe.ds.StringMap;
import Reflect;
import haxe.Log;
import sys.FileSystem;

class LuaHelperTest {

    public static function main():Void {
        trace('=== Lua Helper 测试 ===');
        
        // 创建Lua状态
        var vm:State = LuaL.newstate();
        LuaL.openlibs(vm);
        Lua.init_callbacks(vm);
        
        try {
            // 测试1: 基本Lua脚本执行
            trace('\n--- 测试1: 基本Lua脚本执行 ---');
            testBasicScript(vm);
            
            // 测试2: Lua与Haxe数据转换
            trace('\n--- 测试2: 数据转换测试 ---');
            testDataConversion(vm);
            
            // 测试3: Lua函数调用
            trace('\n--- 测试3: Lua函数调用 ---');
            testLuaFunctionCall(vm);
            
            // 测试4: Haxe函数作为Lua回调
            trace('\n--- 测试4: Haxe回调函数 ---');
            testHaxeCallback(vm);
            
        } catch (e:Dynamic) {
            trace('[ERROR] 测试过程中出现错误: ' + e);
        }
        
        trace('\n=== Lua Helper 测试完成 ===');
    }

    private static function testBasicScript(vm:State):Void {
        var script = 
            "print('Hello from Lua!');" +
            "local x = 10 + 20;" +
            "local y = x * 2;" +
            "return {result = y, message = 'success'};";
        
        if (LuaL.luau_loadsource(vm, 'basic', script) != 0) {
            trace('[ERROR] 加载脚本失败');
            return;
        }
        
        if (Lua.pcall(vm, 0, 1, 0) != Lua.LUA_OK) {
            trace('[ERROR] 执行脚本失败: ' + Lua.tostring(vm, -1));
            return;
        }
        
        var result = Convert.fromLua(vm, -1);
        trace('[TEST1] 脚本执行结果: ' + result);
        Lua.pop(vm, 1);
    }

    private static function testDataConversion(vm:State):Void {
        // 从Haxe传递数据到Lua
        var haxeData = {
            name: "TestObject",
            value: 42,
            items: ["a", "b", "c"]
        };
        
        Convert.toLua(vm, haxeData);
        Lua.setglobal(vm, "haxeData");
        
        // 在Lua中操作数据
        var script = 
            "print('Lua收到Haxe数据: ' .. tostring(haxeData.name));" +
            "haxeData.value = haxeData.value * 2;" +
            "haxeData.items[4] = 'd';" +
            "return haxeData;";
        
        if (LuaL.luau_loadsource(vm, 'conversion', script) != 0) {
            trace('[ERROR] 加载转换测试脚本失败');
            return;
        }
        
        if (Lua.pcall(vm, 0, 1, 0) != Lua.LUA_OK) {
            trace('[ERROR] 执行转换测试失败: ' + Lua.tostring(vm, -1));
            return;
        }
        
        var result = Convert.fromLua(vm, -1);
        trace('[TEST2] 转换测试结果: ' + result);
        Lua.pop(vm, 1);
    }

    private static function testLuaFunctionCall(vm:State):Void {
        // 定义一个Lua函数
        var script = 
            "local M = {} " +
            "function M.calculate(a, b) " +
            "  return { sum = a + b, product = a * b, average = (a + b) / 2 } " +
            "end " +
            "function M.greet(name) " +
            "  return 'Hello, ' .. name .. '!' " +
            "end " +
            "return M;";
        
        if (LuaL.luau_loadsource(vm, 'functions', script) != 0) {
            trace('[ERROR] 加载函数测试脚本失败: ' + Lua.tostring(vm, -1));
            return;
        }
        
        if (Lua.pcall(vm, 0, 1, 0) != Lua.LUA_OK) {
            trace('[ERROR] 执行函数测试失败: ' + Lua.tostring(vm, -1));
            return;
        }
        
        // 将返回的模块设置为全局变量
        Lua.setglobal(vm, 'M');
        
        trace('[TEST3] 获取到Lua模块');
        
        // 使用修复后的 Convert.callLuaFunction 支持嵌套路径
        var calcResult = Convert.callLuaFunction(vm, "M.calculate", [5, 10]);
        trace('[TEST3] M.calculate(5, 10) = ' + calcResult);
        
        var greetResult = Convert.callLuaFunction(vm, "M.greet", ["World"]);
        trace('[TEST3] M.greet("World") = ' + greetResult);
    }

    private static function testHaxeCallback(vm:State):Void {
        var scriptPath = 'test/lua_callback_demo.lua';
        if (!FileSystem.exists(scriptPath)) {
            trace('[ERROR] 找不到脚本文件: ' + scriptPath);
            return;
        }

        var haxeSum = function(a:Dynamic, b:Dynamic):Dynamic {
            var na = a == null ? 0 : Std.parseFloat(Std.string(a));
            var nb = b == null ? 0 : Std.parseFloat(Std.string(b));
            var sum = na + nb;
            trace('[HAXE] lua_call_haxe -> ' + na + ' + ' + nb + ' = ' + sum);
            return sum;
        };

        llua.Lua.Lua_helper.add_callback(vm, 'haxeSum', haxeSum);

        var scriptContent = sys.io.File.getContent(scriptPath);
        var status = LuaL.luau_loadsource(vm, scriptPath, scriptContent);
        if (status != Lua.LUA_OK) {
            trace('[ERROR] 加载外部脚本失败: ' + Lua.tostring(vm, -1));
            Lua.pop(vm, 1);
            llua.Lua.Lua_helper.remove_callback(vm, 'haxeSum');
            return;
        }
        
        // 执行加载的脚本
        if (Lua.pcall(vm, 0, 0, 0) != Lua.LUA_OK) {
            trace('[ERROR] 执行外部脚本失败: ' + Lua.tostring(vm, -1));
            Lua.pop(vm, 1);
            llua.Lua.Lua_helper.remove_callback(vm, 'haxeSum');
            return;
        }

        // 调用 lua_call_haxe
        Lua.getglobal(vm, 'lua_call_haxe');
        Convert.toLua(vm, 3);
        Convert.toLua(vm, 9);
        Lua.pcall(vm, 2, 1, 0);
        var callbackResult = Convert.fromLua(vm, -1);
        Lua.pop(vm, 1);
        trace('[TEST4] lua_call_haxe(3, 9) 返回: ' + callbackResult);

        // 调用 lua_call_from_haxe
        Lua.getglobal(vm, 'lua_call_from_haxe');
        Convert.toLua(vm, 'Copilot');
        Lua.pcall(vm, 1, 1, 0);
        var directResult = Convert.fromLua(vm, -1);
        Lua.pop(vm, 1);
        trace('[TEST4] lua_call_from_haxe("Copilot") 返回: ' + directResult);

        // 调用 lua_make_multiplier
        Lua.getglobal(vm, 'lua_make_multiplier');
        Convert.toLua(vm, 5);
        Lua.pcall(vm, 1, 1, 0);
        var closureDyn = Convert.fromLua(vm, -1);
        Lua.pop(vm, 1);
        var luaClosure:LuaCallback = Std.downcast(closureDyn, LuaCallback);
        if (luaClosure != null) {
            var closureResult = luaClosure.call([6]);
            trace('[TEST4] lua_make_multiplier(5)(6) = ' + closureResult);
            luaClosure.dispose();
        } else {
            trace('[TEST4] lua_make_multiplier 未返回 Lua 函数');
        }

        llua.Lua.Lua_helper.remove_callback(vm, 'haxeSum');
    }
}
