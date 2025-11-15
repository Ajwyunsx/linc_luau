print("[Lua] lua_callback_demo.lua loaded")

function lua_call_haxe(a, b)
    print(string.format("[Lua] lua_call_haxe(%s, %s)", tostring(a), tostring(b)))
    local result = haxeSum(a, b)
    print("[Lua] haxeSum returned", result)
    return result
end

function lua_call_from_haxe(name)
    print("[Lua] lua_call_from_haxe invoked by", tostring(name))
    return "Lua says hi to " .. tostring(name)
end

function lua_make_multiplier(factor)
    print("[Lua] creating multiplier with factor", factor)
    return function(value)
        return value * factor
    end
end
