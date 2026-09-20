# linc/Luau

<p>
  <img src="luau-logo.svg" alt="Luau" width="48" align="left" />

  [![Roblox Luau](https://img.shields.io/badge/Roblox-Luau-00A2FF?logo=roblox&logoColor=white)](https://luau-lang.org)

  Haxe/hxcpp @:native bindings for [Luau](https://github.com/luau-lang/luau).
</p>

This is a [linc](http://snowkit.github.io/linc/) library.

---

This library works with the Haxe cpp target only.

---

### Example usage

See test/Test.hx

Be sure to read the Luau documentation
[this](https://luau.org/getting-started/) 

```haxe
import llua.Lua;
import llua.LuaL;
import llua.State;

class Test {
        
    static function main() {

        var lua:State = LuaL.newstate();
        LuaL.openlibs(lua);
        trace("Lua version: " + Lua.version());

        LuaL.dofile(lua, "script.lua");

        Lua.getglobal(lua, "foo");

        Lua.pushinteger(lua, 1);
        Lua.pushnumber(lua, 2.0);
        Lua.pushstring(lua, "three");

        Lua.pcall(lua, 3, 0, 1);

        Lua.close(lua);
        
    }

}
```
