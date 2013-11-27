package.path = "./?.lua;./lua/?.lua"

if arg[1] == nil then
    io.write("\n[INFO] usage: luajit xmf_scan.lua path_to_xml [output_path [extract]]\n\n")
    os.exit()
end
local OUTDIR = arg[2] or "."

local ffi = require("ffi")
ffi.cdef[[
int uncompress(
    uint8_t *dest, unsigned long *destLen,
    const uint8_t *source, unsigned long sourceLen);
]]
local zlib = ffi.load("zlib1")
local function uncompress(comp, n)
    local buf = ffi.new("uint8_t[?]", n)
    local buflen = ffi.new("unsigned long[1]", n)
    local res = zlib.uncompress(buf, buflen, comp, #comp)
    assert(res == 0)
    return ffi.string(buf, buflen[0])
end

require("mod_binary_reader")
local r = BinaryReader
r:open(arg[1])

if r:size() < 4 then
    r:close()
    io.write("[ERR] size < 4: " .. arg[1] .. ", exiting\n")
    os.exit()
end

r:idstring("XUMF")

local h = {}    -- header
local c = {}    -- chunks
local v = {}    -- vertices
local f = {}    -- faces
local m = {}    -- materials


-------------------------------------------------------------------------------
-- header
-------------------------------------------------------------------------------

h.ver1          = r:uint16()    -- 0x0003 (3)
h.ver2          = r:uint16()    -- 0x0040 (64)
h.chunk_count   = r:uint8()     --
h.chunk_size    = r:uint8()     -- 0x38/0xBC (56/188)
m.count         = r:uint8()     -- materials
h.unk1_1        = r:uint8()     -- 0x88 (136)
h.unk1_2        = r:uint8()     -- 0x01
h.unk1_3        = r:uint8()     -- 0x00
v.count         = r:uint32()
f.count         = r:uint32()
h.unk1_4        = r:uint32()    -- 0x00000004
h.unk1_5        = r:uint16()    -- 0x0001 | 0x0000 for *-collision.xmf
r:seek(64)                      -- skip 36 0x00


-------------------------------------------------------------------------------
-- chunks
-------------------------------------------------------------------------------
for i = 1, h.chunk_count do
    local t = {}
    for j = 1, 10 do
        table.insert(t, r:uint32())
    end
    if     h.chunk_size == 56 then
        -- unknown bytes
        r:seek(r:pos() + 16)
    elseif h.chunk_size == 188 then
        -- unknown bytes
        r:seek(r:pos() + 148)
    else
        assert(false, "[ERR] strange chunk size: " .. h.chunk_size)
    end
    table.insert(c, t)
end


-------------------------------------------------------------------------------
-- materials
-------------------------------------------------------------------------------

if m.count > 0 then
    for i = 1, m.count do
        local jmp = r:pos() + 136
        local t = {}
        t.begin = r:uint32()
        t.count = r:uint32()
        t.name = r:str()
        table.insert(m, t)
        r:seek(jmp)
    end
end

-------------------------------------------------------------------------------
-- parse done, show info
-------------------------------------------------------------------------------

io.write("\n==== xmf info: ==============\n")
io.write("chunk headers:\t" .. h.chunk_count .. " x " .. h.chunk_size .. " bytes\n")
io.write("     vertices:\t" .. v.count .. "\n")
io.write("      indexes:\t" .. f.count .. "\n")
io.write("        faces:\t" .. f.count/3 .. "\n")
io.write("    materials:\t" .. m.count .. "\n")
io.write("\n= chunks info: ======================\n")
io.write("id1\tpart\tid2\tunits\tbytes\n")
io.write("-------------------------------------\n")
for k, v in ipairs(c) do
    io.write(v[1] .. "\t" .. v[2] .. "\t" .. v[6] .. "\t" ..v[8] .. "\t x " ..v[9])
    --io.write(table.concat(v, "\t"))
    --io.write("\t" .. arg[1] .. "\n")
    io.write("\n")
end
if m.count > 0 then
    io.write("\n= materials: =========================\n")
    io.write("start\tcount\tname\n")
    io.write("--------------------------------------\n")
    for k, v in ipairs(m) do
        io.write(v.begin .. "\t" .. v.count .. "\t" .. v.name .. "\n")
    end
end


-- without arg[3] just print chunks info and exit
if arg[3] == nil or arg[3] ~= "extract" then
    r:close()
    os.exit()
end


-------------------------------------------------------------------------------
-- extract chunks data
-------------------------------------------------------------------------------

os.execute("del /q /f " .. OUTDIR .. "\\chunk*.bin >nul 2>&1")

io.write("\nunpack chunk data....")
for k, v in ipairs(c) do
    io.write(" " .. k .. "...")
    local name = string.format("%s/chunkdata#%d_(%d_%d_%d)_%dx%d.bin", OUTDIR, k, v[1], v[2], v[6], v[8], v[9])
    local packed = v[7]
    local unpacked = v[8] * v[9]
    local buf = r:str(packed)
    local data = uncompress(buf, unpacked)

    local w = assert(io.open(name, "w+b"))
    w:write(data)
    w:close()
end
io.write(" done\n")
assert(r:pos() == r:size(), "[ERR] pos != filesize: " .. r:pos() .. " != " .. r:size())

-------------------------------------------------------------------------------
-- copy binary chunk headers
-------------------------------------------------------------------------------

r:seek(64)  -- jump back to begin
io.write("copy chunk headers...")
for i = 1, h.chunk_count do
    io.write(" " .. i .. "...")
    local name = string.format("%s/chunk#%d.bin", OUTDIR, i)
    local data = r:str(h.chunk_size)

    local w = assert(io.open(name, "w+b"))
    w:write(data)
    w:close()
end
io.write(" done\n")


r:close()
