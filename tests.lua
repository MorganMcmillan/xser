-- This test can only be run in Lua 5.3 or later, because it has string.pack and string.unpack
local xser = require("xser")
local serialise, deserialise = xser.serialise, xser.deserialise
local format, pack, unpack = string.format, string.pack, string.unpack
local write = io.write
local xtest = require("xtest")

local function printBytes(bytes)
    write("\"")
    for i = 1, #bytes do
        write("\\" .. tostring(bytes:byte(i)))
    end
    write("\"\n")
end

xtest.run{
    "nil (de)serialization",
    function()
        xtest.assertEq("\0", serialise(nil))
        xtest.assertEq(nil, deserialise("\0"))
    end,
    "number (de)serialization",
    function()
        -- u8
        xtest.assertEq("\1\0", serialise(0))
        xtest.assertEq(0, deserialise("\1\0"))
        xtest.assertEq("\1\255", serialise(255))
        xtest.assertEq(255, deserialise("\1\255"))
        -- u16
        xtest.assertEq("\3\0\1", serialise(256))
        xtest.assertEq(256, deserialise("\3\0\1"))
        xtest.assertEq(30000, deserialise("\0030u"))
        xtest.assertEq("\3\255\255", serialise(65535))
        -- u32
        xtest.assertEq("\5\0\0\1\0", serialise(65536))
        xtest.assertEq(65536, deserialise("\5\0\0\1\0"))
        xtest.assertEq(4294967295, deserialise("\5\255\255\255\255u"))
        xtest.assertEq("\5\255\255\255\255", serialise(4294967295))
        -- u64 cannot be represented in lua
        -- i8
        xtest.assertEq("\2\255", serialise(-1))
        xtest.assertEq(-1, deserialise("\2\255"))
        xtest.assertEq("\2\128", serialise(-128))
        xtest.assertEq(-128, deserialise("\2\128"))
        -- i16
        xtest.assertEq("\4\127\255", serialise(-129))
        xtest.assertEq(-129, deserialise("\4\127\255"))
        xtest.assertEq("\4\0\128", serialise(-32768))
        xtest.assertEq(-32768, deserialise("\4\0\128"))
        -- i32
        xtest.assertEq("\6\255\127\255\255", serialise(-32769))
        xtest.assertEq(-32769, deserialise("\6\255\127\255\255"))
        xtest.assertEq("\6\0\0\0\128", serialise(-2147483648))
        xtest.assertEq(-2147483648, deserialise("\6\0\0\0\128"))
        -- i64 cannot be represented in lua
        -- f64
        xtest.assertEq("\9\0\0\0\0\0\0\224\63", serialise(0.5))
        xtest.assertEq(0.5, deserialise("\9\0\0\0\0\0\0\224\63"))
        xtest.assertEq("\9\0\0\0\0\0\0\224\191", serialise(-0.5))
        xtest.assertEq(-0.5, deserialise("\9\0\0\0\0\0\0\224\191"))
        write"pi = "
        printBytes(serialise(3.14))
        xtest.assertEq("\9\31\133\235\81\184\30\9\64", serialise(3.14))
        xtest.assertEq(3.14, deserialise("\9\31\133\235\81\184\30\9\64"))
        local googol = 10 ^ 100
        write"googol = "
        printBytes(serialise(googol))
        xtest.assertEq("\9\125\195\148\37\173\73\178\84", serialise(googol))
        xtest.assertEq(googol, deserialise("\9\125\195\148\37\173\73\178\84"))
        googol = -googol
        write"-googol = "
        printBytes(serialise(googol))
        xtest.assertEq("\9\125\195\148\37\173\73\178\212", serialise(googol))
        xtest.assertEq(googol, deserialise("\9\125\195\148\37\173\73\178\212"))
    end,
    "string (de)serialization",
    function()
        xtest.assertEq("\13\0", serialise(""))
        xtest.assertEq("", deserialise("\13\0"))
        xtest.assertEq("\13Hello, world!\0", serialise("Hello, world!"))
        xtest.assertEq("Hello, world!", deserialise("\13Hello, world!\0"))
        -- A string containing null bytes cannot be terminated with a null byte, so we instead provide a 4 byte length    
        xtest.assertEq("\12\1\0\0\0\0", serialise("\0"))
    end,
    "boolean (de)serialization",
    function()
        xtest.assertEq("\10", serialise(false))
        xtest.assertEq(false, deserialise("\10"))
        xtest.assertEq("\11", serialise(true))
        xtest.assertEq(true, deserialise("\11"))
    end,
    "table (de)serialization",
    function()
        xtest.assertEq("\14", serialise({}))
        xtest.assertShallowEq({}, deserialise("\14"))
        write"array = "
        printBytes(serialise({1, 2, 3, 4, 5}))
        xtest.assertShallowEq({1, 2, 3, 4, 5}, deserialise(serialise({1, 2, 3, 4, 5})))
        write"map = "
        printBytes(serialise({a = 1, b = 2, c = 3, d = 4, e = 5}))
        xtest.assertShallowEq({a = 1, b = 2, c = 3, d = 4, e = 5}, deserialise(serialise({a = 1, b = 2, c = 3, d = 4, e = 5})))
        local mapArray = {1, 2, 3, d = 4, e = 5, f = 6}
        write"map array = "
        printBytes(serialise(mapArray))
        xtest.assertShallowEq(mapArray, deserialise(serialise(mapArray)))
    end
}