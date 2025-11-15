-- Test module that returns a table
local M = {}

M.calculate = function(x, y)
    return x + y
end

M.multiply = function(x, y)
    return x * y
end

return M
