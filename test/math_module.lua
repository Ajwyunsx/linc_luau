-- Math module (standard library simulation)
local math = {}

math.max = function(a, b)
    if a > b then return a else return b end
end

math.min = function(a, b)
    if a < b then return a else return b end
end

math.floor = function(x)
    return x - (x % 1)
end

math.abs = function(x)
    if x < 0 then return -x else return x end
end

return math
