import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;

class Testing {
	var x = 1;
	function die(){
		trace('no way i died');
	}
}


class Test {
		

	static function main() {

		var vm:State = LuaL.newstate();
		LuaL.openlibs(vm);
		#if cpp
		LuaL.sandbox(vm);
		LuaL.sandboxthread(vm);
		#end
		trace("Lua version: " + Lua.version());

		var src = sys.io.File.getContent("test/script.luau");
		trace('Read luau source, size=' + src.length);
		if (LuaL.luau_loadsource(vm, "script", src) != 0) {
			throw 'Failed to load Luau chunk';
		}
		trace('Loaded bytecode');
		Lua.pcall(vm, 0, 1, 0);
		trace('Executed chunk');
		Lua.setglobal(vm, "module");
		// expose module functions to globals for simpler calling
		Lua.getglobal(vm, "module");
		Lua.getfield(vm, -1, "fromHaxe");
		Lua.setglobal(vm, "fromHaxe");
		Lua.getfield(vm, -1, "toHaxe");
		Lua.setglobal(vm, "toHaxe");
		Lua.pop(vm, 1);



		// Lua.getglobal(vm, "foo");
		// Lua.pushinteger(vm, 1);
		// Lua.pushnumber(vm, 2.0);
		// Lua.pushstring(vm, "three");
		trace("Luau script executed");

		trace("from haxe:");
		Lua.getglobal(vm, "fromHaxe");
		Lua.newtable(vm);
		Lua.pushstring(vm, "a");
		Lua.pushinteger(vm, 1);
		Lua.settable(vm, -3);
		var st = Lua.pcall(vm, 1, 1, 0);
		if (st == Lua.LUA_OK) {
			trace(Lua.tostring(vm, -1));
			Lua.pop(vm, 1);
		} else {
			trace(Lua.tostring(vm, -1));
			Lua.pop(vm, 1);
		}
		trace("to haxe:");
		Lua.getglobal(vm, "toHaxe");
		st = Lua.pcall(vm, 0, Lua.LUA_MULTRET, 0);
		if (st == Lua.LUA_OK) {
			trace(Lua.tostring(vm, -5));
			trace(Lua.tostring(vm, -4));
			trace(Lua.tostring(vm, -3));
			trace(Lua.tostring(vm, -2));
			trace(Convert.fromLua(vm, -1));
			Lua.pop(vm, 5);
		} else {
			trace(Lua.tostring(vm, -1));
			Lua.pop(vm, 1);
		}

		// Lua.pcall(vm,Lua.gettop(vm)-1, 0, 1);
		// trace('${Convert.fromLua(vm,0)}');




		Lua.close(vm);

	}


}