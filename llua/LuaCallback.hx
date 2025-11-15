package llua;

/**
 * Wrapper object for a Lua function (annonimous or not) sent from a script
 * for use as callback.
 */
class LuaCallback {
    /** The Lua environment the function is bound to **/
    private var l:State;
    /** Reference to Lua function - either Int (registry) or String (global table key) */
    public var ref(default, null):Dynamic;
    /** Whether using global table storage (Luau compatibility) */
    private var useGlobalTable:Bool;

    public function new(lua:State, ref:Dynamic) {
        this.l = lua;
        this.ref = ref;
        this.useGlobalTable = Std.isOfType(ref, String);
    }

    /** Runs this Lua function once, with the given arguments and returns the result. */
    public function call(args:Array<Dynamic> = null):Dynamic {
        // Luau compatibility: support both registry and global table references
        if (useGlobalTable) {
            Lua.getglobal(l, "__haxe_func_refs");
            Lua.getfield(l, -1, cast(ref, String));
            Lua.remove(l, -2); // Remove table
        } else {
            Lua.rawgeti(l, Lua.LUA_REGISTRYINDEX, cast(ref, Int));
        }
        
        if (Lua.isfunction(l, -1)) {
            if (args == null) args = [];
            for (arg in args) Convert.toLua(l, arg);
            var status:Int = Lua.pcall(l, args.length, 1, 0);
            if (status != Lua.LUA_OK) {
                var err:String = Lua.tostring(l, -1);
                Lua.pop(l, 1);
                //if (err != null) err = err.trim();
                if (err == null || err == "") {
                    switch(status) {
                        case Lua.LUA_ERRRUN: err = "Runtime Error";
                        case Lua.LUA_ERRMEM: err = "Memory Allocation Error";
                        case Lua.LUA_ERRERR: err = "Critical Error";
                        default: err = "Unknown Error";
                    }
                }
                trace("Error on callback: " + err);
                return null;
            } else {
                var result:Dynamic = Convert.fromLua(l, -1);
                Lua.pop(l, 1);
                return result;
            }
        }
        return null;
    }

    /**
     * Deallocates the pointer reserved for this callback.
     * Make sure to call this once you're done using the function.
     */
    public function dispose() {
        if (useGlobalTable) {
            // Remove from global table (Luau compatible)
            Lua.getglobal(l, "__haxe_func_refs");
            Lua.pushnil(l);
            Lua.setfield(l, -2, cast(ref, String));
            Lua.pop(l, 1);
        } else {
            // For Luau compatibility, use global table approach only
            // luaL_unref is not available in Luau
        }
    }
}
