package test;

package;

import flixel.FlxG;
import flixel.FlxState;

class LuauCodeGenTest extends FlxState {
    private var luaInstance:psych.script.FunkinLua;
    
    override public function create() {
        super.create();
        
        // Test Luau CodeGen functionality
        testLuauCodeGen();
    }
    
    private function testLuauCodeGen() {
        trace("=== Testing Luau CodeGen Integration ===");
        
        // Test 1: Check if LuauCodeGen is available
        #if LUA_ALLOWED
        trace("✓ Lua is allowed in this build");
        
        // Test 2: Check LuauCodeGen class availability
        try {
            var luauVersion = llua.LuauCodeGen.getLuauVersion();
            trace("✓ LuauCodeGen available - Version: " + luauVersion);
            
            // Test 3: Check Luau support
            var isSupported = llua.LuauCodeGen.isLuauSupported();
            trace("✓ Luau supported: " + isSupported);
            
            // Test 4: Test code compilation
            var testCode = "print('Hello from Luau!'); local x = 42; return x * 2;";
            var bytecode = llua.LuauCodeGen.compileLuauCode(testCode);
            trace("✓ Code compilation test - Bytecode: " + bytecode);
            
            // Test 5: Test bytecode optimization
            if (bytecode != null) {
                var optimized = llua.LuauCodeGen.optimizeBytecode(bytecode);
                trace("✓ Bytecode optimization test - Result: " + optimized);
            }
            
            // Test 6: Test creating Luau function
            if (bytecode != null) {
                var funcCreated = llua.LuauCodeGen.createLuauFunction(bytecode, "testFunction");
                trace("✓ Function creation test - Success: " + funcCreated);
            }
            
            // Test 7: Test with actual Lua script if available
            testWithLuaScript();
            
        } catch (e:Dynamic) {
            trace("✗ LuauCodeGen test failed: " + e);
        }
        
        #else
        trace("✗ Lua not allowed in this build");
        #end
        
        trace("=== Luau CodeGen Test Complete ===");
    }
    
    private function testWithLuaScript() {
        try {
            // Create a simple Lua script for testing
            var testScriptContent = '
                -- Test Luau codegen integration
                print("Testing Luau codegen in FunkinLua!");
                
                -- Try to use codegen function if available
                if codegenCompile then
                    local code = "local x = 10; return x * 2";
                    local result = codegenCompile(code);
                    print("Codegen result: " .. tostring(result));
                else
                    print("Codegen function not available");
                end
                
                return "Lua script executed successfully";
            ';
            
            // Write test script to temp file
            var scriptPath = "test_luau_codegen.lua";
            #if sys
            sys.io.File.saveContent(scriptPath, testScriptContent);
            
            // Test loading the script with FunkinLua
            luaInstance = new psych.script.FunkinLua(scriptPath);
            
            // Wait a bit and then test calling functions
            FlxG.state.callLater(() -> {
                testLuaInstanceFunctions();
            });
            #else
            trace("Cannot test with Lua script - sys not available");
            #end
            
        } catch (e:Dynamic) {
            trace("✗ Lua script test failed: " + e);
        }
    }
    
    private function testLuaInstanceFunctions() {
        if (luaInstance != null && luaInstance.lua != null) {
            try {
                // Test calling a simple function
                luaInstance.call("onCreate", []);
                trace("✓ Successfully called onCreate function");
                
                // Test setting and getting variables
                luaInstance.set("testVar", 123);
                luaInstance.set("codegen_test_message", "Luau codegen is working!");
                
                trace("✓ Successfully set test variables");
                
                // Test getting variables back
                var testVar = luaInstance.getBool("testVar");
                trace("✓ Retrieved test variable: " + testVar);
                
            } catch (e:Dynamic) {
                trace("✗ Lua instance function test failed: " + e);
            }
        }
    }
    
    override public function update(elapsed:Float) {
        super.update(elapsed);
        
        // Exit test on any key press
        if (FlxG.keys.justPressed.ANY) {
            FlxG.switchState(new TestState());
        }
    }
}

class TestState extends FlxState {
    override public function create() {
        super.create();
        
        var text = new flixel.text.FlxText(10, 10, 0, 
            "Luau CodeGen Test Complete!\n\n" +
            "Press ANY key to return to main menu.\n\n" +
            "Check console output for detailed test results.", 
            16);
        text.color = flixel.util.FlxColor.WHITE;
        add(text);
    }
    
    override public function update(elapsed:Float) {
        super.update(elapsed);
        
        if (FlxG.keys.justPressed.ANY) {
            FlxG.switchState(new MainMenuState());
        }
    }
}

// Simple main menu state for testing
class MainMenuState extends FlxState {
    override public function create() {
        super.create();
        
        var text = new flixel.text.FlxText(10, 10, 0, 
            "FunkinLua + Luau CodeGen Test\n\n" +
            "Press R to run Luau CodeGen test\n" +
            "Press ANY other key to exit", 
            20);
        text.color = flixel.util.FlxColor.CYAN;
        add(text);
    }
    
    override public function update(elapsed:Float) {
        super.update(elapsed);
        
        if (FlxG.keys.justPressed.R) {
            FlxG.switchState(new LuauCodeGenTest());
        } else if (FlxG.keys.justPressed.ANY) {
            Sys.exit(0);
        }
