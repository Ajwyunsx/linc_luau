type KV = { name: string, value: any }

local M = {}

function M.fromHaxe(tbl: { [any]: any }): string
    local count = 0
    for i, v in pairs(tbl) do
        count += 1
        if type(v) == "table" and v[3] == nil then
            continue
        end
    end
    print("Received " .. tostring(count) .. " items")
    return "Printed " .. tostring(#tbl)
end

function M.toHaxe(): (string, string, string, string, { [string]: any })
    local result = { what = "ok",  "extra" }
    return "Th","is","a","Test",result
end

print("Luau file script.luau loaded!")
fromHaxe = M.fromHaxe
toHaxe = M.toHaxe
return M