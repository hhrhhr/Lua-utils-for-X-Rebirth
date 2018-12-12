local conf = require("x4_config")

arg[1] = conf.res_dir .. "/t/" .. conf.lang .. ".xml"
arg[2] = conf.lang .. ".lua"

--[[
local mt = {}
function mt:__index(key)
    print("!!! index " .. key .. " not found.")
--    os.exit()
    return "#" .. key .. "#"
end
setmetatable(WARE, mt)
--]]

--[[ ]]------------------------------------------------------------------------

local xml2lua = require("xml2lua")
local handler = require("xmlhandler.tree")
local parser = xml2lua.parser(handler)

parser.options.stripWS = true
parser.options.expandEntities = false
parser.options.errorHandler = function(err, pos) print("\n", err .. "\n", pos .. "\n") end

local xml
local f, e = io.open(arg[1], "rb")
if f then
    xml = f:read("a")
    f:close()
else
    io.stderr:write(e, "\n")
    xml = ""
end
parser:parse(xml)

local out = assert(io.open(arg[2], "wb"))

local function wr(k, v)
    out:write("[" .. k .. "]=[=[" .. v .. "]=],\n")
end

local l = handler.root.language
out:write("local lang={\n")

local page = l.page
for i = 1, #page do
    local p = page[i]
    local pid = p._attr.id
    out:write("-- page\n[" .. pid .. "]={\n")
    local t = p.t
    if #t > 1 then
        for j = 1, #t do
            local tj = t[j]
            wr(tj._attr.id, tj[1])
        end
    else
        wr(t._attr.id, t[1])
    end
    out:write("}, -- page[" .. pid .. "]\n")
end
out:write("} -- lang\nreturn lang\n")

out:close()

