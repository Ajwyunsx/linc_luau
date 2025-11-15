-- Test all built-in Lua libraries

print("=== Testing Built-in Libraries ===")

-- Test math library
local math = require("math")
print("\n[Math Library]")
print("math.max(10, 20) =", math.max(10, 20))
print("math.min(5, 3) =", math.min(5, 3))
print("math.abs(-15) =", math.abs(-15))
print("math.floor(5.8) =", math.floor(5.8))
print("math.ceil(5.2) =", math.ceil(5.2))
print("math.sqrt(16) =", math.sqrt(16))
print("math.pi =", math.pi)

-- Test string library
local string = require("string")
print("\n[String Library]")
print("string.upper('hello') =", string.upper('hello'))
print("string.lower('WORLD') =", string.lower('WORLD'))
print("string.len('test') =", string.len('test'))
print("string.sub('hello', 2, 4) =", string.sub('hello', 2, 4))
print("string.rep('ab', 3) =", string.rep('ab', 3))

-- Test table library
local table = require("table")
print("\n[Table Library]")
local t = {1, 2, 3}
table.insert(t, 4)
print("After insert(4):", table.concat(t, ", "))
local removed = table.remove(t)
print("After remove():", table.concat(t, ", "), "| removed:", removed)

-- Test os library
local os = require("os")
print("\n[OS Library]")
print("os.time() =", os.time())
print("os.clock() =", os.clock())

-- Test io library
local io = require("io")
print("\n[IO Library]")
io.write("Testing io.write\n")

-- Test nil return safety
print("\n[Nil Safety Test]")
local nilValue = nil
local safeCompare = (nilValue or 0) < 10
print("nil comparison safe:", safeCompare)

print("\n=== All Tests Complete ===")
